import { pgTable, text, timestamp, boolean, date } from "drizzle-orm/pg-core";
import { clientsTable } from "./clients.ts";
import { betaFeaturesTable } from "./betaFeatures.ts";
import { usersTable } from "./users.ts";

export const testimonialsTable = pgTable("testimonials", {
  id: text("id").primaryKey().$defaultFn(() => crypto.randomUUID()),
  clientId: text("client_id").notNull().references(() => clientsTable.id),
  featureId: text("feature_id").notNull().references(() => betaFeaturesTable.id),
  quote: text("quote").notNull(),
  context: text("context"),
  approved: boolean("approved").notNull().default(false),
  callDate: date("call_date"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  createdById: text("created_by_id").notNull().references(() => usersTable.id),
});

export type Testimonial = typeof testimonialsTable.$inferSelect;
export type InsertTestimonial = typeof testimonialsTable.$inferInsert;
