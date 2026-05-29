import { pgTable, text, timestamp, integer, pgEnum, date } from "drizzle-orm/pg-core";
import { usersTable } from "./users.ts";

export const betaStatusEnum = pgEnum("beta_status", [
  "draft", "in_progress", "complete",
  "recruiting", "outreach_sent", "full", "closing", "closed",
]);

export const closeReasonEnum = pgEnum("close_reason", [
  "completed", "cancelled", "merged", "paused"
]);

export const betaFeaturesTable = pgTable("beta_features", {
  id: text("id").primaryKey().$defaultFn(() => crypto.randomUUID()),
  name: text("name").notNull(),
  ownerPmId: text("owner_pm").notNull().references(() => usersTable.id),
  ownerPmmId: text("owner_pmm").notNull().references(() => usersTable.id),
  targetTesterCount: integer("target_tester_count").notNull().default(15),
  status: betaStatusEnum("status").notNull().default("draft"),
  startDate: date("start_date").notNull(),
  closedAt: timestamp("closed_at"),
  closeReason: closeReasonEnum("close_reason"),
  closeNotes: text("close_notes"),
  idealClientCriteria: text("ideal_client_criteria"),
  betaGoal: text("beta_goal"),
  outreachDeadline: date("outreach_deadline").notNull(),
  projectedEndDate: date("projected_end_date"),
  jiraEpicLink: text("jira_epic_link").notNull().default(""),
  slug: text("slug").unique(),
  previousSlug: text("previous_slug"),
  clonedFromId: text("cloned_from"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export type BetaFeature = typeof betaFeaturesTable.$inferSelect;
export type InsertBetaFeature = typeof betaFeaturesTable.$inferInsert;
