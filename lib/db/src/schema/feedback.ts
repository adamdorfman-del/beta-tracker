import { pgTable, text, timestamp, pgEnum } from "drizzle-orm/pg-core";
import { clientsTable } from "./clients.ts";
import { betaFeaturesTable } from "./betaFeatures.ts";
import { usersTable } from "./users.ts";

export const sentimentEnum = pgEnum("sentiment", ["positive", "neutral", "negative"]);

export const feedbackTable = pgTable("feedback", {
  id: text("id").primaryKey().$defaultFn(() => crypto.randomUUID()),
  clientId: text("client_id").notNull().references(() => clientsTable.id),
  featureId: text("feature_id").notNull().references(() => betaFeaturesTable.id),
  sentiment: sentimentEnum("sentiment").notNull(),
  notes: text("notes"),
  feedbackProviderId: text("feedback_provider_id").notNull().references(() => usersTable.id),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export type Feedback = typeof feedbackTable.$inferSelect;
export type InsertFeedback = typeof feedbackTable.$inferInsert;
