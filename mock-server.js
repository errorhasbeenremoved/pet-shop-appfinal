/**
 * Запуск:
 *   node mock-server.js --port 8080 --origin http://localhost:5555
 *
 * Проверка:
 *   GET  http://localhost:8080/api/__health
 *
 * Тестовые переключатели:
 *   ?__delay=1500  — искусственная задержка
 *   ?__fail=500    — принудительная ошибка сервера
 */
const http = require('http');
const { URL } = require('url');

const args = process.argv.slice(2);
const portArg = args.indexOf('--port');
const originArg = args.indexOf('--origin');
const ttlArg = args.indexOf('--ttl');
const PORT = portArg >= 0 ? Number(args[portArg + 1]) : 8080;
const ACCESS_TTL_SECONDS = ttlArg >= 0 ? Math.max(10, Number(args[ttlArg + 1]) || 60) : 900;
const REFRESH_TTL_SECONDS = 7 * 24 * 60 * 60;
const crypto = require('crypto');
require('dotenv').config();
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const pool = new Pool({ connectionString: process.env.DATABASE_URL, connectionTimeoutMillis: 5000, max: 10 });
const newToken = () => crypto.randomBytes(32).toString('hex');
const tokenHash = token => crypto.createHash('sha256').update(String(token)).digest('hex');
const publicUser = u => ({ id: Number(u.id), username: u.username, email: u.email, fullName: u.full_name ?? u.fullName, role: u.role, active: u.active });
async function authUser(req) {
  const h = req.headers.authorization || ''; const token = h.startsWith('Bearer ') ? h.slice(7) : '';
  if (!token) return null;
  const result = await pool.query(`SELECT u.id, u.username, u.email, u.full_name, u.role, u.active FROM auth_sessions s JOIN app_users u ON u.id=s.user_id WHERE s.access_token_hash=$1 AND s.access_expires_at > now() AND u.active=true AND u.deleted_at IS NULL`, [tokenHash(token)]);
  return result.rowCount ? publicUser(result.rows[0]) : null;
}
async function issueTokens(user, sessionStartedAt = new Date()) {
  const accessToken = newToken(), refreshToken = newToken();
  const started = sessionStartedAt instanceof Date ? sessionStartedAt : new Date(sessionStartedAt);
  await pool.query(`INSERT INTO auth_sessions(user_id, access_token_hash, refresh_token_hash, access_expires_at, refresh_expires_at, session_started_at) VALUES ($1,$2,$3,now()+($4 * interval '1 second'),now()+($5 * interval '1 second'),$6)`, [user.id, tokenHash(accessToken), tokenHash(refreshToken), ACCESS_TTL_SECONDS, REFRESH_TTL_SECONDS, started]);
  return { accessToken, refreshToken, expiresIn: ACCESS_TTL_SECONDS, refreshExpiresIn: REFRESH_TTL_SECONDS, user: publicUser(user) };
}
function requireRole(res, user, roles) { if (!user) { error(res, 401, 'Требуется вход в систему'); return false; } if (!roles.includes(user.role)) { error(res, 403, 'Недостаточно прав для выполнения операции'); return false; } return true; }
const ORIGIN = originArg >= 0 ? args[originArg + 1] : 'http://localhost:5555';

const clone = (v) => JSON.parse(JSON.stringify(v));
const now = () => new Date().toISOString();
function seed() { /* PostgreSQL is the source of truth; never reset production-like data here. */ }

function json(res, status, body) {
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
  });
  res.end(JSON.stringify(body));
}
function empty(res, status = 204) {
  res.writeHead(status, {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
  });
  res.end();
}
function error(res, status, message, errors) {
  json(res, status, { message, ...(errors ? { errors } : {}) });
}
function parseBody(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', (chunk) => raw += chunk);
    req.on('end', () => {
      try { resolve(raw ? JSON.parse(raw) : {}); } catch (_) { reject(new Error('Некорректный JSON')); }
    });
    req.on('error', reject);
  });
}

function idOf(v) { return Number.parseInt(String(v), 10); }
const tableFor = { products:'products', brands:'brands', categories:'categories', suppliers:'suppliers', customers:'customers' };
const selectSql = {
 brands:`SELECT id,name,country,description,deleted_at FROM brands`,
 categories:`SELECT id,name,brand_id,description,deleted_at FROM categories`,
 suppliers:`SELECT id,brand_id,name,email,phone,description,deleted_at FROM suppliers`,
 products:`SELECT p.id,p.name,p.sku,p.brand_id,p.price::float8 AS price,p.stock,p.description,p.deleted_at,
   COALESCE((SELECT json_agg(pc.category_id ORDER BY pc.category_id) FROM product_categories pc WHERE pc.product_id=p.id),'[]') AS category_ids,
   COALESCE((SELECT json_agg(ps.supplier_id ORDER BY ps.supplier_id) FROM product_suppliers ps WHERE ps.product_id=p.id),'[]') AS supplier_ids
   FROM products p`,
 customers:`SELECT id,user_id,full_name,email,phone,loyalty_number,loyalty_level,bonus_points,deleted_at FROM customers`
};
function shape(entity, r) {
 if (!r) return null;
 const common={id:Number(r.id),deletedAt:r.deleted_at||null};
 if(entity==='brands') return {...common,name:r.name,country:r.country,description:r.description||''};
 if(entity==='categories') return {...common,name:r.name,brandId:r.brand_id==null?null:Number(r.brand_id),description:r.description||''};
 if(entity==='suppliers') return {...common,name:r.name,brandId:r.brand_id==null?null:Number(r.brand_id),email:r.email,phone:r.phone,description:r.description||''};
 if(entity==='products') return {...common,name:r.name,sku:r.sku,brandId:Number(r.brand_id),categoryIds:(r.category_ids||[]).map(Number),supplierIds:(r.supplier_ids||[]).map(Number),price:Number(r.price),stock:Number(r.stock),description:r.description||''};
 return {...common,name:r.full_name,email:r.email,phone:r.phone,card:{number:r.loyalty_number,level:r.loyalty_level,bonusPoints:Number(r.bonus_points)}};
}
async function fetchRows(entity, includeDeleted=false) {
 const q=selectSql[entity];
 const r=await pool.query(q+(includeDeleted?'':' WHERE deleted_at IS NULL')+(entity==='products'?' ORDER BY p.id':' ORDER BY id'));
 return r.rows.map(x=>shape(entity,x));
}
function fieldValue(item, field) {
 if(field==='country') return item.country??'';
 if(field==='email') return item.email??'';
 if(field==='price') return Number(item.price??0);
 if(field==='stock') return Number(item.stock??0);
 if(field==='points') return Number(item.card?.bonusPoints??0);
 if(field==='brandId') return Number(item.brandId??0);
 return String(item.name??'').toLowerCase();
}
function searchable(item) { return Object.values(item).flatMap(v=>Array.isArray(v)?v:[v]).map(v=>typeof v==='object'&&v!==null?JSON.stringify(v):String(v)).join(' ').toLowerCase(); }
async function filtered(entity,url) {
 let rows=await fetchRows(entity,url.searchParams.get('deleted')==='1');
 const search=(url.searchParams.get('search')||'').trim().toLowerCase();
 if(search) rows=rows.filter(x=>searchable(x).includes(search));
 const filter=url.searchParams.get('filter');
 if(filter){const id=idOf(filter);if(entity==='products')rows=rows.filter(x=>x.brandId===id||x.categoryIds.includes(id));if(entity==='categories'||entity==='suppliers')rows=rows.filter(x=>x.brandId===id);}
 const [sortField,direction]=(url.searchParams.get('sort')||'name,asc').split(',');
 rows.sort((a,b)=>{const av=fieldValue(a,sortField),bv=fieldValue(b,sortField);const r=typeof av==='number'&&typeof bv==='number'?av-bv:String(av).localeCompare(String(bv),'ru');return direction==='desc'?-r:r;});
 return rows;
}
async function list(res,entity,url) {
 const rows=await filtered(entity,url); const page=Math.max(1,idOf(url.searchParams.get('page')||1));const size=Math.min(100,Math.max(1,idOf(url.searchParams.get('size')||10)));const total=rows.length;
 return json(res,200,{items:rows.slice((page-1)*size,page*size),page,size,total,totalPages:Math.max(1,Math.ceil(total/size))});
}
function validate(entity,data) {
 const e={}; if(!String(data.name||'').trim())e.name='Название обязательно';
 if(entity==='products'){if(!String(data.sku||'').trim())e.sku='SKU обязателен';if(!(Number(data.price)>=0))e.price='Цена должна быть неотрицательной';if(!Number.isInteger(Number(data.stock))||Number(data.stock)<0)e.stock='Остаток должен быть целым неотрицательным числом';if(!Number.isInteger(Number(data.brandId)))e.brandId='Выберите бренд';if(!Array.isArray(data.categoryIds)||!data.categoryIds.length)e.categoryIds='Выберите хотя бы одну категорию';if(!Array.isArray(data.supplierIds)||!data.supplierIds.length)e.supplierIds='Выберите хотя бы одного поставщика';}
 if((entity==='categories'||entity==='suppliers')&&!Number.isInteger(Number(data.brandId)))e.brandId='Выберите бренд';
 if((entity==='suppliers'||entity==='customers')&&!/^\\S+@\\S+\\.\\S+$/.test(String(data.email||'')))e.email='Введите корректный email';
 if(entity==='customers'&&!String(data.phone||'').trim())e.phone='Укажите телефон';
 if(entity==='brands'&&!String(data.country||'').trim())e.country='Укажите страну';
 return e;
}
async function saveEntity(entity,data,id=null) {
 const client=await pool.connect();
 try{
  await client.query('BEGIN');
  let r, key=id;
  if(entity==='brands'){
   r=id?await client.query('UPDATE brands SET name=$1,country=$2,description=$3 WHERE id=$4 RETURNING *',[data.name,data.country,data.description||'',id]):await client.query('INSERT INTO brands(name,country,description) VALUES($1,$2,$3) RETURNING *',[data.name,data.country,data.description||'']);
  } else if(entity==='categories'){
   r=id?await client.query('UPDATE categories SET name=$1,brand_id=$2,description=$3 WHERE id=$4 RETURNING *',[data.name,data.brandId||null,data.description||'',id]):await client.query('INSERT INTO categories(name,brand_id,description) VALUES($1,$2,$3) RETURNING *',[data.name,data.brandId||null,data.description||'']);
  } else if(entity==='suppliers'){
   r=id?await client.query('UPDATE suppliers SET name=$1,brand_id=$2,email=$3,phone=$4,description=$5 WHERE id=$6 RETURNING *',[data.name,data.brandId||null,data.email,data.phone,data.description||'',id]):await client.query('INSERT INTO suppliers(name,brand_id,email,phone,description) VALUES($1,$2,$3,$4,$5) RETURNING *',[data.name,data.brandId||null,data.email,data.phone,data.description||'']);
  } else if(entity==='customers'){
   const level=data.card?.level||data.loyaltyLevel||'Bronze', points=Number(data.card?.bonusPoints??data.bonusPoints??0);
   r=id?await client.query('UPDATE customers SET full_name=$1,email=$2,phone=$3,loyalty_level=$4,bonus_points=$5 WHERE id=$6 RETURNING *',[data.name,data.email,data.phone,level,points,id]):await client.query('INSERT INTO customers(full_name,email,phone,loyalty_number,loyalty_level,bonus_points) VALUES($1,$2,$3,$4,$5,$6) RETURNING *',[data.name,data.email,data.phone,`PET-${crypto.randomBytes(4).toString('hex').toUpperCase()}`,level,points]);
  } else {
   r=id?await client.query('UPDATE products SET name=$1,sku=$2,brand_id=$3,price=$4,stock=$5,description=$6,updated_at=now() WHERE id=$7 RETURNING *',[data.name,data.sku,data.brandId,data.price,data.stock,data.description||'',id]):await client.query('INSERT INTO products(name,sku,brand_id,price,stock,description) VALUES($1,$2,$3,$4,$5,$6) RETURNING *',[data.name,data.sku,data.brandId,data.price,data.stock,data.description||'']);
  }
  if(!r.rowCount){await client.query('ROLLBACK');return null;}
  key=Number(r.rows[0].id);
  if(entity==='products'){
   await client.query('DELETE FROM product_categories WHERE product_id=$1',[key]);await client.query('DELETE FROM product_suppliers WHERE product_id=$1',[key]);
   for(const cid of [...new Set((data.categoryIds||[]).map(Number))]) await client.query('INSERT INTO product_categories(product_id,category_id) VALUES($1,$2)',[key,cid]);
   for(const sid of [...new Set((data.supplierIds||[]).map(Number))]) await client.query('INSERT INTO product_suppliers(product_id,supplier_id) VALUES($1,$2)',[key,sid]);
  }
  await client.query('COMMIT');
  const rows=await fetchRows(entity,true);return rows.find(x=>x.id===key)||null;
 }catch(e){await client.query('ROLLBACK');throw e;}finally{client.release();}
}
async function main(req, res) {
  const url = new URL(req.url, `http://${req.headers.host}`);
  if (url.searchParams.has('__delay')) await new Promise(r => setTimeout(r, Math.max(0, idOf(url.searchParams.get('__delay')))));
  if (url.searchParams.has('__fail')) return error(res, idOf(url.searchParams.get('__fail')) || 500, 'Принудительная тестовая ошибка');
  if (req.method === 'OPTIONS') return empty(res);
  if (url.pathname === '/api/__health' && req.method === 'GET') { try { const r = await pool.query('SELECT current_database() AS database'); return json(res, 200, { status: 'ok', service: 'pet-shop-api', database: r.rows[0].database, time: now() }); } catch (_) { return error(res, 503, 'PostgreSQL недоступен'); } }
  if (url.pathname === '/api/__reset' && req.method === 'POST') { const resetUser = await authUser(req); if (!requireRole(res, resetUser, ['admin'])) return; return error(res, 405, 'Сброс данных отключён: данные хранятся в PostgreSQL'); }
  if (url.pathname === '/api/auth/login' && req.method === 'POST') {
    const b = await parseBody(req);
    const result = await pool.query('SELECT * FROM app_users WHERE lower(username)=lower($1) AND active=true AND deleted_at IS NULL LIMIT 1', [String(b.username || '')]);
    const u = result.rows[0];
    if (!u || !u.password_hash || !(await bcrypt.compare(String(b.password || ''), u.password_hash))) return error(res, 401, 'Неверный логин или пароль');
    const tokens = await issueTokens(u);
    return json(res, 200, tokens);
  }
  if (url.pathname === '/api/auth/register' && req.method === 'POST') {
    const b = await parseBody(req); const errs = {};
    const username = String(b.username || '').trim();
    const email = String(b.email || '').trim().toLowerCase();
    const fullName = String(b.fullName || '').trim();
    const password = String(b.password || '');
    if (!/^[a-zA-Z0-9_.-]{3,32}$/.test(username)) errs.username = 'Логин: 3–32 символа, латиница, цифры, . _ -';
    if (!/^\S+@\S+\.\S+$/.test(email)) errs.email = 'Укажите корректный email';
    if (password.length < 8 || !/\d/.test(password) || !/[^A-Za-z0-9]/.test(password)) errs.password = 'Не менее 8 символов, цифра и спецсимвол';
    if (!fullName) errs.fullName = 'Укажите имя';
    if (Object.keys(errs).length) return error(res, 422, 'Проверьте поля регистрации', errs);
    const passwordHash = await bcrypt.hash(password, 12);
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const userResult = await client.query(`INSERT INTO app_users(auth_subject, username, email, full_name, role, active, password_hash) VALUES ($1,$2,$3,$4,'customer',true,$5) RETURNING id, username, email, full_name, role, active`, [`local:${username.toLowerCase()}`, username, email, fullName, passwordHash]);
      const u = userResult.rows[0];
      const loyalty = `PET-${String(u.id).padStart(8, '0')}`;
      await client.query(`INSERT INTO customers(user_id, full_name, email, phone, loyalty_number) VALUES ($1,$2,$3,$4,$5)`, [u.id, fullName, email, String(b.phone || 'Не указан').slice(0,32), loyalty]);
      await client.query('COMMIT');
      return json(res, 201, { user: publicUser(u) });
    } catch (e) {
      await client.query('ROLLBACK');
      if (e.code === '23505') return error(res, 409, 'Пользователь с таким логином или email уже существует');
      throw e;
    } finally { client.release(); }
  }
  if (url.pathname === '/api/auth/refresh' && req.method === 'POST') {
    const b = await parseBody(req); const refreshToken = String(b.refreshToken || '');
    if (!refreshToken) return error(res, 401, 'Токен обновления не указан');
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const found = await client.query(`SELECT s.id AS session_id, s.user_id, s.session_started_at, u.id, u.username, u.email, u.full_name, u.role, u.active, u.deleted_at FROM auth_sessions s JOIN app_users u ON u.id=s.user_id WHERE s.refresh_token_hash=$1 AND s.refresh_expires_at>now() FOR UPDATE`, [tokenHash(refreshToken)]);
      const row = found.rows[0];
      if (!row || !row.active || row.deleted_at || Date.now() - new Date(row.session_started_at).getTime() >= 8*60*60*1000) {
        if (row) await client.query('DELETE FROM auth_sessions WHERE id=$1', [row.session_id]);
        await client.query('COMMIT');
        return error(res, 401, 'Токен обновления недействителен, истёк или превышена максимальная длительность сессии');
      }
      await client.query('DELETE FROM auth_sessions WHERE id=$1', [row.session_id]);
      await client.query('COMMIT');
      const tokens = await issueTokens(row, new Date(row.session_started_at));
      return json(res, 200, tokens);
    } catch (e) { await client.query('ROLLBACK'); throw e; }
    finally { client.release(); }
  }
  if (url.pathname === '/api/auth/me' && req.method === 'GET') { const u = await authUser(req); return u ? json(res, 200, u) : error(res, 401, 'Сессия истекла'); }
  if (url.pathname === '/api/auth/logout' && req.method === 'POST') {
    const b = await parseBody(req); const token = (req.headers.authorization || '').replace(/^Bearer /, '');
    await pool.query('DELETE FROM auth_sessions WHERE access_token_hash=$1 OR refresh_token_hash=$2', [token ? tokenHash(token) : '', b.refreshToken ? tokenHash(String(b.refreshToken)) : '']);
    return json(res, 200, { ok: true });
  }
  if (url.pathname === '/api/admin/users' && req.method === 'GET') { const u = await authUser(req); if (!requireRole(res, u, ['admin'])) return; const result = await pool.query('SELECT id, username, email, full_name, role, active FROM app_users WHERE deleted_at IS NULL ORDER BY id'); return json(res, 200, { items: result.rows.map(publicUser) }); }
  if (url.pathname === '/api/admin/stats' && req.method === 'GET') { const u = await authUser(req); if (!requireRole(res, u, ['admin'])) return; const stats={}; for(const entity of ['products','brands','categories','suppliers','customers','orders']) { const r=await pool.query(`SELECT count(*)::int AS total,count(*) FILTER(WHERE deleted_at IS NULL)::int AS active,count(*) FILTER(WHERE deleted_at IS NOT NULL)::int AS deleted FROM ${entity}`); stats[entity]=r.rows[0]; } const userStats=await pool.query('SELECT count(*)::int AS total,count(*) FILTER (WHERE active)::int AS active,count(*) FILTER (WHERE NOT active)::int AS blocked FROM app_users WHERE deleted_at IS NULL'); return json(res,200,{stats,users:userStats.rows[0]}); }

  if (url.pathname === '/api/admin/users' && req.method === 'PATCH') { const u = await authUser(req); if (!requireRole(res, u, ['admin'])) return; const b = await parseBody(req); const role = ['admin','manager','customer'].includes(b.role) ? b.role : null; const result = await pool.query('UPDATE app_users SET role=COALESCE($1,role), active=COALESCE($2,active) WHERE id=$3 AND deleted_at IS NULL RETURNING id, username, email, full_name, role, active', [role, typeof b.active === 'boolean' ? b.active : null, Number(b.id)]); if (!result.rowCount) return error(res, 404, 'Пользователь не найден'); if (b.active === false) await pool.query('DELETE FROM auth_sessions WHERE user_id=$1', [Number(b.id)]); return json(res, 200, publicUser(result.rows[0])); }


  if (url.pathname === '/api/orders' || url.pathname.startsWith('/api/orders/')) {
    const user=await authUser(req); if(!user)return error(res,401,'Для работы с заказами необходимо войти');
    const staff=['admin','manager'].includes(user.role);
    const orderShape=async row=>{
      const items=await pool.query(`SELECT oi.product_id,oi.product_name_snapshot AS name,oi.sku_snapshot AS sku,oi.quantity,oi.unit_price::float8 AS "unitPrice",oi.line_total::float8 AS "lineTotal" FROM order_items oi WHERE oi.order_id=$1 ORDER BY oi.id`,[row.id]);
      return {id:Number(row.id),orderNumber:row.order_number,userId:Number(row.user_id||row.customer_user_id||0),customerId:Number(row.customer_id),customerName:row.customer_name,createdAt:row.created_at,updatedAt:row.updated_at,status:row.status,items:items.rows.map(i=>({...i,productId:Number(i.product_id),quantity:Number(i.quantity),unitPrice:Number(i.unitPrice),lineTotal:Number(i.lineTotal)})),total:Number(row.total_amount),simulated:true};
    };
    const base=`SELECT o.*,c.full_name AS customer_name,c.user_id FROM orders o JOIN customers c ON c.id=o.customer_id`;
    if(req.method==='GET'&&url.pathname==='/api/orders'){
      const params=[];let where='WHERE o.deleted_at IS NULL';if(!staff){params.push(user.id);where+=' AND c.user_id=$1';}
      const search=(url.searchParams.get('search')||'').trim();if(search){params.push('%'+search+'%');where+=` AND (o.order_number ILIKE $${params.length} OR c.full_name ILIKE $${params.length} OR EXISTS(SELECT 1 FROM order_items oi WHERE oi.order_id=o.id AND oi.product_name_snapshot ILIKE $${params.length}))`;}
      const page=Math.max(1,idOf(url.searchParams.get('page')||1)),size=Math.min(100,Math.max(1,idOf(url.searchParams.get('size')||20)));
      const count=await pool.query(`${base} ${where}`,params);const total=count.rowCount;
      params.push(size,(page-1)*size);const result=await pool.query(`${base} ${where} ORDER BY o.created_at DESC LIMIT $${params.length-1} OFFSET $${params.length}`,params);
      const items=[];for(const row of result.rows)items.push(await orderShape(row));
      return json(res,200,{items,page,size,total,totalPages:Math.max(1,Math.ceil(total/size))});
    }
    if(req.method==='POST'&&url.pathname==='/api/orders'){
      if(user.role!=='customer')return error(res,403,'Оформлять тестовые заказы может только покупатель');
      const body=await parseBody(req),errs={};if(!Array.isArray(body.items)||!body.items.length)errs.items='Добавьте хотя бы один товар';
      const quantities=new Map();for(const line of (Array.isArray(body.items)?body.items:[])){const pid=idOf(line.productId),qty=idOf(line.quantity);if(pid<1)errs.items='Некорректный товар';if(qty<1||qty>99)errs.items='Количество должно быть от 1 до 99';quantities.set(pid,(quantities.get(pid)||0)+qty);}
      if(Object.keys(errs).length)return error(res,422,'Проверьте состав заказа',errs);
      const client=await pool.connect();try{
        await client.query('BEGIN');
        const cust=await client.query('SELECT id FROM customers WHERE user_id=$1 AND deleted_at IS NULL',[user.id]);
        if(!cust.rowCount){await client.query('ROLLBACK');return error(res,409,'Для аккаунта не найдена карточка покупателя');}
        const lines=[];let subtotal=0;
        for(const [pid,qty] of quantities){const pr=await client.query('SELECT id,name,sku,price::float8 AS price,stock FROM products WHERE id=$1 AND deleted_at IS NULL FOR UPDATE',[pid]);if(!pr.rowCount){await client.query('ROLLBACK');return error(res,409,`Товар #${pid} больше недоступен`);}const p=pr.rows[0];if(qty>p.stock){await client.query('ROLLBACK');return error(res,409,`Недостаточно остатка товара «${p.name}»`);}const lineTotal=Math.round(p.price*qty*100)/100;subtotal+=lineTotal;lines.push({p,qty,lineTotal});}
        subtotal=Math.round(subtotal*100)/100;const number='PS-'+Date.now()+'-'+crypto.randomBytes(2).toString('hex').toUpperCase();
        const created=await client.query(`INSERT INTO orders(order_number,customer_id,status,currency,subtotal,discount_amount,total_amount,shipping_address,comment) VALUES($1,$2,'new','EUR',$3,0,$3,$4,$5) RETURNING *`,[number,cust.rows[0].id,subtotal,String(body.shippingAddress||'без доставки').slice(0,500),String(body.comment||'').slice(0,1000)]);
        for(const l of lines){await client.query('INSERT INTO order_items(order_id,product_id,product_name_snapshot,sku_snapshot,unit_price,quantity) VALUES($1,$2,$3,$4,$5,$6)',[created.rows[0].id,l.p.id,l.p.name,l.p.sku,l.p.price,l.qty]);await client.query('UPDATE products SET stock=stock-$1,updated_at=now() WHERE id=$2',[l.qty,l.p.id]);}
        await client.query('COMMIT');const full=await pool.query(`${base} WHERE o.id=$1`,[created.rows[0].id]);return json(res,201,await orderShape(full.rows[0]));
      }catch(e){await client.query('ROLLBACK');throw e;}finally{client.release();}
    }
    const orderMatch=url.pathname.match(/^\/api\/orders\/(\d+)$/);
    if(orderMatch&&req.method==='GET'){const r=await pool.query(`${base} WHERE o.id=$1 AND o.deleted_at IS NULL`,[idOf(orderMatch[1])]);if(!r.rowCount)return error(res,404,'Заказ не найден');if(!staff&&Number(r.rows[0].user_id)!==user.id)return error(res,403,'Нельзя просматривать чужой заказ');return json(res,200,await orderShape(r.rows[0]));}
    if(orderMatch&&req.method==='PATCH'){if(!staff)return error(res,403,'Менять статус заказа может только менеджер или администратор');const body=await parseBody(req),allowed=['new','processing','ready','completed','cancelled'];if(!allowed.includes(body.status))return error(res,422,'Неизвестный статус',{status:'Выберите статус из списка'});const r=await pool.query(`UPDATE orders SET status=$1,updated_at=now() WHERE id=$2 AND deleted_at IS NULL AND status NOT IN ('completed','cancelled') RETURNING id`,[body.status,idOf(orderMatch[1])]);if(!r.rowCount)return error(res,409,'Заказ не найден или уже завершён/отменён');const full=await pool.query(`${base} WHERE o.id=$1`,[idOf(orderMatch[1])]);return json(res,200,await orderShape(full.rows[0]));}
    return error(res,405,'Операция с заказом не поддерживается');
  }

  const match = url.pathname.match(/^\/api\/(products|brands|categories|suppliers|customers)(?:\/(.*))?$/);
  if (!match) return error(res, 404, 'Маршрут не найден');
  const entity = match[1];
  const tail = match[2] || '';
  const user = await authUser(req);
  if (!user) return error(res, 401, 'Для работы с магазином необходимо войти');
  const isRead = req.method === 'GET';
  const isAdmin = user.role === 'admin';
  const isManager = user.role === 'manager' || isAdmin;
  if (isRead) {
    if (entity === 'customers' && !isManager) return error(res, 403, 'Просмотр клиентов доступен менеджеру и администратору');
    if (url.searchParams.get('deleted') === '1' && !isAdmin) return error(res, 403, 'Просмотр удалённых записей доступен только администратору');
  } else {
    if (!isManager) return error(res, 403, 'Изменять каталог может только менеджер или администратор');
    if ((req.method === 'DELETE' && url.searchParams.get('hard') === 'true') || /\/restore$/.test(tail) || tail === 'bulk-delete') { if (!isAdmin) return error(res, 403, 'Физическое удаление, восстановление и массовое удаление доступны только администратору'); }
  }

  if (req.method === 'GET' && !tail) return list(res, entity, url);

  if (req.method === 'GET' && tail === 'exists') {
    const field=url.searchParams.get('field')||'', value=url.searchParams.get('value')||'', exceptId=url.searchParams.get('exceptId')?idOf(url.searchParams.get('exceptId')):null;
    const col=({name:'name',sku:'sku',email:'email',country:'country'})[field];
    if(!col)return json(res,200,{exists:false});
    const params=[value];let sql=`SELECT 1 FROM ${entity} WHERE deleted_at IS NULL AND lower(${col}::text)=lower($1)`;
    if(exceptId){params.push(exceptId);sql+=` AND id<>$2`;}sql+=' LIMIT 1';
    const r=await pool.query(sql,params);return json(res,200,{exists:!!r.rowCount});
  }
  if(req.method==='POST'&&tail==='bulk-delete'){
    const body=await parseBody(req),ids=Array.isArray(body.ids)?body.ids.map(idOf).filter(Number.isInteger):[];
    if(!ids.length)return json(res,200,{count:0});
    const r=await pool.query(`UPDATE ${entity} SET deleted_at=now() WHERE id=ANY($1::bigint[]) AND deleted_at IS NULL`,[ids]);return json(res,200,{count:r.rowCount});
  }
  if(req.method==='GET'&&/^\d+$/.test(tail)){
    const rows=await fetchRows(entity,true),item=rows.find(x=>x.id===idOf(tail));return item?json(res,200,item):error(res,404,'Запись не найдена');
  }
  if(req.method==='POST'&&!tail){
    const body=await parseBody(req),errors=validate(entity,body);if(Object.keys(errors).length)return error(res,422,'Ошибка валидации',errors);
    try{const item=await saveEntity(entity,body);return json(res,201,item);}catch(e){if(e.code==='23505')return error(res,409,'Запись с такими уникальными данными уже существует');if(e.code==='23503'||e.code==='23514')return error(res,422,'Проверьте связанные записи и значения');throw e;}
  }
  if(/^\d+$/.test(tail)&&req.method==='PUT'){
    const id=idOf(tail),body=await parseBody(req),errors=validate(entity,body);if(Object.keys(errors).length)return error(res,422,'Ошибка валидации',errors);
    try{const item=await saveEntity(entity,body,id);return item?json(res,200,item):error(res,404,'Запись не найдена');}catch(e){if(e.code==='23505')return error(res,409,'Запись с такими уникальными данными уже существует');if(e.code==='23503'||e.code==='23514')return error(res,422,'Проверьте связанные записи и значения');throw e;}
  }
  if(/^\d+\/restore$/.test(tail)&&req.method==='PATCH'){
    const id=idOf(tail.split('/')[0]);const r=await pool.query(`UPDATE ${entity} SET deleted_at=NULL WHERE id=$1 AND deleted_at IS NOT NULL RETURNING id`,[id]);if(!r.rowCount)return error(res,404,'Удалённая запись не найдена');const rows=await fetchRows(entity,true);return json(res,200,rows.find(x=>x.id===id));
  }
  if(/^\d+$/.test(tail)&&req.method==='DELETE'){
    const id=idOf(tail);
    if(url.searchParams.get('hard')==='true'){
      try{const r=await pool.query(`DELETE FROM ${entity} WHERE id=$1 RETURNING id`,[id]);if(!r.rowCount)return error(res,404,'Запись не найдена');return empty(res,204);}catch(e){if(e.code==='23503')return error(res,409,'Нельзя физически удалить запись: на неё ссылаются другие данные');throw e;}
    }
    const r=await pool.query(`UPDATE ${entity} SET deleted_at=now() WHERE id=$1 AND deleted_at IS NULL RETURNING id`,[id]);if(!r.rowCount)return error(res,404,'Запись не найдена');return empty(res,204);
  }
  return error(res,405,'Операция не поддерживается');
}

http.createServer((req, res) => {
  main(req, res).catch(err => { console.error(err); error(res, 500, 'Внутренняя ошибка сервера'); });
}).listen(PORT, () => {
  console.log(`Pet Shop API: http://localhost:${PORT}/api`);
  console.log(`CORS origin: ${ORIGIN}`);
  console.log('Health: GET /api/__health');
  console.log('Reset:  POST /api/__reset');
  console.log(`Access token TTL: ${ACCESS_TTL_SECONDS}s`);
  console.log('Auth: PostgreSQL app_users + hashed passwords; run db/auth-migration.sql and npm run seed:auth');
});