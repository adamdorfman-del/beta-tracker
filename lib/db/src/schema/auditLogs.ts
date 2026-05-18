import { pgTable, text, timestamp, json } from "drizzle-orm/pg-core";
import { usersTable } from "./users.ts";

export const auditLogsTable = pgTable("audit_logs", {
  id: text("id").primaryKey().$defaultFn(() => crypto.randomUUID()),
  entityType: text("entity_type").notNull(),
  entityId: text("entity_id").notNull(),
  action: text("action").notNull(),
  changedById: text("changed_by").notNull().references(() => usersTable.id),
  priorState: json("prior_state"),
  nextState: json("next_state"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export type AuditLog = typeof auditLogsTable.$inferSelect;
