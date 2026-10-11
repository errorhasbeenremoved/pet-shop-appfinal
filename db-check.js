
const { checkDatabase, pool } = require('./db');

async function main() {
  try {
    const info = await checkDatabase();
    console.log('PostgreSQL подключён:', info);
  } catch (error) {
    console.error('Не удалось подключиться:', error.message);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}

main();
