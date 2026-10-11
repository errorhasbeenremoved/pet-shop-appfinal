
require('dotenv').config();

const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  connectionTimeoutMillis: 5000,
  idleTimeoutMillis: 30000,
  max: 10,
});

pool.on('error', (error) => {
  console.error('Ошибка неактивного соединения PostgreSQL:', error.message);
});

async function checkDatabase() {
  const result = await pool.query(`
    SELECT current_database() AS database,
           current_user AS username,
           NOW() AS server_time
  `);

  return result.rows[0];
}

module.exports = { pool, checkDatabase };
