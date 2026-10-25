import { env } from './config/env.js';
import { pool } from './config/db.js';
import { createApp } from './app.js';

async function start() {
  try {
    await pool.query('SELECT 1');
    const [tables] = await pool.query("SELECT COUNT(*) AS n FROM information_schema.tables WHERE table_schema = ? AND table_name IN ('users','trips','expenses','sessions')", [env.db.database]);
    if (tables[0].n < 4) throw new Error(`Database "${env.db.database}" exists but the tables are missing. Run database/schema.sql in MySQL Workbench.`);
  } catch (err) {
    console.error('\n[database] Could not start:', err.message);
    console.error('  Check DB_HOST / DB_USER / DB_PASSWORD / DB_NAME in .env and that schema.sql was run.\n');
    process.exit(1);
  }
  createApp().listen(env.port, () => {
    console.log(`Travel Expense Manager API running on http://localhost:${env.port}  (${env.nodeEnv})`);
    console.log(env.exchangeApiKey ? 'Live exchange rates: enabled' : 'Live exchange rates: not configured (manual rates only)');
  });
}
start();
