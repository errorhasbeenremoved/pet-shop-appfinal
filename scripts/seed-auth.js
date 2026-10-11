require('dotenv').config();
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');

const pool = new Pool({ connectionString: process.env.DATABASE_URL, connectionTimeoutMillis: 5000 });
const demoUsers = [
  { username: 'admin', password: 'admin123', email: 'admin@petshop.local', fullName: 'Администратор', role: 'admin' },
  { username: 'manager', password: 'manager123', email: 'manager@petshop.local', fullName: 'Менеджер магазина', role: 'manager' },
  { username: 'customer', password: 'customer123', email: 'customer@petshop.local', fullName: 'Покупатель', role: 'customer' },
];

async function main() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const inserted = {};
    for (const item of demoUsers) {
      const passwordHash = await bcrypt.hash(item.password, 12);
      const result = await client.query(`
        INSERT INTO public.app_users
          (auth_subject, username, email, full_name, role, active, password_hash)
        VALUES ($1,$2,$3,$4,$5,true,$6)
        ON CONFLICT (username) DO UPDATE SET
          email=EXCLUDED.email,
          full_name=EXCLUDED.full_name,
          role=EXCLUDED.role,
          active=true,
          deleted_at=NULL,
          password_hash=EXCLUDED.password_hash
        RETURNING id, username, email, full_name, role, active
      `, [`local:${item.username}`, item.username, item.email, item.fullName, item.role, passwordHash]);
      inserted[item.username] = result.rows[0];
    }

    const customer = inserted.customer;
    await client.query(`
      INSERT INTO public.customers
        (user_id, full_name, email, phone, loyalty_number, loyalty_level, bonus_points)
      VALUES ($1,$2,$3,'Не указан','PET-DEMO-CUSTOMER','Bronze',0)
      ON CONFLICT (user_id) DO UPDATE SET
        full_name=EXCLUDED.full_name,
        email=EXCLUDED.email,
        deleted_at=NULL
    `, [customer.id, customer.full_name, customer.email]);

    await client.query('COMMIT');
    console.log('Учётные записи созданы/обновлены:');
    for (const item of demoUsers) console.log(`- ${item.username} (${item.role})`);
    console.log('Пароли захешированы bcryptjs; открытый текст в БД не сохраняется.');
  } catch (error) {
    await client.query('ROLLBACK');
    if (error.code === '23505') {
      console.error('Конфликт уникальности. Проверь email/loyalty_number в app_users и customers.');
    }
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch(error => {
  console.error('Не удалось создать пользователей:', error.message);
  process.exitCode = 1;
});
