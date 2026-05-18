import { pgTable, text, timestamp, pgEnum, primaryKey } from "drizzle-orm/pg-core";
import { usersTable } from "./users.ts";
import { clientsTable } from "./clients.ts";
import { betaEnrollmentsTable } from "./enrollments.ts";

export const batchStatusEnum = pgEnum("batch_status", ["pending", "ready", "sent"]);

export const outreachBatchesTable = pgTable("outreach_batches", {
  id: text("id").primaryKey().$defaultFn(() => crypto.randomUUID()),
  clientId: text("client_id").notNull().references(() => clientsTable.id),
  batchStatus: batchStatusEnum("batch_status").notNull().default("pending"),
  sentAt: timestamp("sent_at"),
  sentById: text("sent_by").references(() => usersTable.id),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const outreachBatchEnrollmentsTable = pgTable("outreach_batch_enrollments", {
  batchId: text("batch_id").notNull().references(() => outreachBatchesTable.id),
  enrollmentId: text("enrollment_id").notNull().references(() => betaEnrollmentsTable.id),
}, (t) => [primaryKey({ columns: [t.batchId, t.enrollmentId] })]);

export type OutreachBatch = typeof outreachBatchesTable.$inferSelect;
export type OutreachBatchEnrollment = typeof outreachBatchEnrollmentsTable.$inferSelect;
