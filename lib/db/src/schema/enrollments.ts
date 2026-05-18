import { pgTable, text, timestamp, boolean, pgEnum, unique } from "drizzle-orm/pg-core";
import { usersTable } from "./users.ts";
import { clientsTable } from "./clients.ts";
import { betaFeaturesTable } from "./betaFeatures.ts";

export const approvalStatusEnum = pgEnum("approval_status", ["pending", "approved", "rejected"]);

export const testerStatusEnum = pgEnum("tester_status", [
  "nominated", "csm_pending", "csm_approved", "outreach_sent",
  "confirmed", "active", "completed", "dropped", "cancelled"
]);

export const betaEnrollmentsTable = pgTable("beta_enrollments", {
  id: text("id").primaryKey().$defaultFn(() => crypto.randomUUID()),
  clientId: text("client_id").notNull().references(() => clientsTable.id),
  featureId: text("feature_id").notNull().references(() => betaFeaturesTable.id),
  assignedById: text("assigned_by").notNull().references(() => usersTable.id),
  isOverflow: boolean("is_overflow").notNull().default(false),
  csmApprovalStatus: approvalStatusEnum("csm_approval_status").notNull().default("pending"),
  csmApprovedById: text("csm_approved_by").references(() => usersTable.id),
  csmApprovedAt: timestamp("csm_approved_at"),
  csmRejectionReason: text("csm_rejection_reason"),
  testerStatus: testerStatusEnum("tester_status").notNull().default("nominated"),
  outreachSentAt: timestamp("outreach_sent_at"),
  confirmedAt: timestamp("confirmed_at"),
  completedAt: timestamp("completed_at"),
  droppedAt: timestamp("dropped_at"),
  dropReason: text("drop_reason"),
  feedbackSubmitted: boolean("feedback_submitted").notNull().default(false),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
}, (t) => [unique().on(t.clientId, t.featureId)]);

export type BetaEnrollment = typeof betaEnrollmentsTable.$inferSelect;
export type InsertBetaEnrollment = typeof betaEnrollmentsTable.$inferInsert;
