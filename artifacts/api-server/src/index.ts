import app from "./app";
import { logger } from "./lib/logger";
import { db, betaFeaturesTable } from "./lib/db";
import { isNull, eq, sql } from "drizzle-orm";
import { generateUniqueSlug } from "./lib/slugify";

async function runStartupMigrations() {
  await db.execute(sql`ALTER TABLE users ADD COLUMN IF NOT EXISTS last_auth_at TIMESTAMP`);
  await db.execute(sql`ALTER TABLE beta_features ADD COLUMN IF NOT EXISTS beta_goal TEXT`);
  await db.execute(sql`ALTER TABLE beta_features ADD COLUMN IF NOT EXISTS slug TEXT`);
  await db.execute(sql`ALTER TABLE beta_features ADD COLUMN IF NOT EXISTS projected_end_date DATE`);
  await db.execute(sql`CREATE UNIQUE INDEX IF NOT EXISTS beta_features_slug_unique ON beta_features (slug)`);

  const unsluggedFeatures = await db
    .select({ id: betaFeaturesTable.id, name: betaFeaturesTable.name })
    .from(betaFeaturesTable)
    .where(isNull(betaFeaturesTable.slug));

  for (const f of unsluggedFeatures) {
    const slug = await generateUniqueSlug(f.name);
    await db.update(betaFeaturesTable).set({ slug }).where(eq(betaFeaturesTable.id, f.id));
  }

  if (unsluggedFeatures.length > 0) {
    logger.info({ count: unsluggedFeatures.length }, "Backfilled feature slugs");
  }

  // feedback table
  await db.execute(sql`
    DO $$ BEGIN
      IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'sentiment') THEN
        CREATE TYPE sentiment AS ENUM ('positive', 'neutral', 'negative');
      END IF;
    END $$
  `);
  await db.execute(sql`
    CREATE TABLE IF NOT EXISTS feedback (
      id TEXT PRIMARY KEY,
      client_id TEXT NOT NULL REFERENCES clients(id),
      feature_id TEXT NOT NULL REFERENCES beta_features(id),
      sentiment sentiment NOT NULL,
      notes TEXT,
      feedback_provider_id TEXT NOT NULL REFERENCES users(id),
      is_gating_request BOOLEAN NOT NULL DEFAULT false,
      gating_description TEXT,
      jira_ticket_url TEXT,
      created_at TIMESTAMP NOT NULL DEFAULT NOW()
    )
  `);
  // rename legacy logged_by column if present (old deployments)
  await db.execute(sql`
    DO $$ BEGIN
      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'feedback' AND column_name = 'logged_by'
      ) THEN
        ALTER TABLE feedback RENAME COLUMN logged_by TO feedback_provider_id;
      END IF;
    END $$
  `);
  await db.execute(sql`ALTER TABLE feedback ADD COLUMN IF NOT EXISTS is_gating_request BOOLEAN NOT NULL DEFAULT false`);
  await db.execute(sql`ALTER TABLE feedback ADD COLUMN IF NOT EXISTS gating_description TEXT`);
  await db.execute(sql`ALTER TABLE feedback ADD COLUMN IF NOT EXISTS jira_ticket_url TEXT`);
  // add new tester_status enum values if missing
  // ALTER TYPE ... ADD VALUE must run outside a transaction block (no DO wrapper)
  await db.execute(sql`ALTER TYPE tester_status ADD VALUE IF NOT EXISTS 'enrolled'`);
  await db.execute(sql`ALTER TYPE tester_status ADD VALUE IF NOT EXISTS 'using'`);
  await db.execute(sql`ALTER TYPE tester_status ADD VALUE IF NOT EXISTS 'accepted'`);
  // testimonials table
  await db.execute(sql`
    CREATE TABLE IF NOT EXISTS testimonials (
      id TEXT PRIMARY KEY,
      client_id TEXT NOT NULL REFERENCES clients(id),
      feature_id TEXT NOT NULL REFERENCES beta_features(id),
      quote TEXT NOT NULL,
      context TEXT,
      approved BOOLEAN NOT NULL DEFAULT false,
      call_date DATE,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      created_by_id TEXT NOT NULL REFERENCES users(id)
    )
  `);
}

const rawPort = process.env["PORT"];

if (!rawPort) {
  throw new Error(
    "PORT environment variable is required but was not provided.",
  );
}

const port = Number(rawPort);

if (Number.isNaN(port) || port <= 0) {
  throw new Error(`Invalid PORT value: "${rawPort}"`);
}

runStartupMigrations().then(() => {
  app.listen(port, (err) => {
    if (err) {
      logger.error({ err }, "Error listening on port");
      process.exit(1);
    }
    logger.info({ port }, "Server listening");
  });
}).catch((err) => {
  logger.error({ err }, "Startup migration failed");
  process.exit(1);
});
