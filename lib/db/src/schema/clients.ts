import { pgTable, text, timestamp, integer, boolean, pgEnum, date } from "drizzle-orm/pg-core";
import { usersTable } from "./users.ts";

export const healthStatusEnum = pgEnum("health_status", ["green", "yellow", "red"]);
export const segmentEnum = pgEnum("segment", ["Strategic", "Enterprise", "Commercial", "Professional", "Channel"]);

export const clientsTable = pgTable("clients", {
  id: text("id").primaryKey().$defaultFn(() => crypto.randomUUID()),
  name: text("name").notNull(),
  crmId: text("crm_id"),
  csmOwnerId: text("csm_owner").notNull().references(() => usersTable.id),
  tier: integer("tier"),
  segment: segmentEnum("segment"),
  primaryContactName: text("primary_contact_name"),
  primaryContactEmail: text("primary_contact_email"),
  accountHealth: healthStatusEnum("account_health").notNull().default("green"),
  vertical: text("vertical"),
  contractRenewalDate: date("contract_renewal_date"),
  productSubscriptions: text("product_subscriptions"),
  outreachLock: boolean("outreach_lock").notNull().default(false),
  lastOutreachDate: date("last_outreach_date"),
  notes: text("notes"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export type Client = typeof clientsTable.$inferSelect;
export type InsertClient = typeof clientsTable.$inferInsert;
