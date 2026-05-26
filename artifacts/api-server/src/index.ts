import app from "./app";
import { logger } from "./lib/logger";
import { db, betaFeaturesTable } from "./lib/db";
import { isNull, eq, sql } from "drizzle-orm";
import { generateUniqueSlug } from "./lib/slugify";

async function runStartupMigrations() {
  await db.execute(sql`ALTER TABLE beta_features ADD COLUMN IF NOT EXISTS slug TEXT`);
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
      logged_by TEXT NOT NULL REFERENCES users(id),
      created_at TIMESTAMP NOT NULL DEFAULT NOW()
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
