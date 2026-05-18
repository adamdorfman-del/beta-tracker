import { drizzle } from "drizzle-orm/node-postgres";
import pg from "pg";
import { usersTable, betaFeaturesTable, clientsTable, betaEnrollmentsTable } from "./schema/index.ts";
import * as users from "./schema/users.ts";
import * as betaFeatures from "./schema/betaFeatures.ts";
import * as clients from "./schema/clients.ts";
import * as enrollments from "./schema/enrollments.ts";
import * as batches from "./schema/batches.ts";
import * as auditLogs from "./schema/auditLogs.ts";
import { eq } from "drizzle-orm";

const { Pool } = pg;

if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL must be set.");
}

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const db = drizzle(pool, {
  schema: { ...users, ...betaFeatures, ...clients, ...enrollments, ...batches, ...auditLogs }
});

async function seed() {
  console.log("Seeding database...");

  const existingUsers = await db.select().from(usersTable);
  let allUsers;
  if (existingUsers.length > 0) {
    console.log("Users already seeded, skipping.");
    allUsers = existingUsers;
  } else {
    allUsers = await db.insert(usersTable).values([
      { name: "Alice Chen", email: "alice@example.com", role: "pm" },
      { name: "Bob Kumar", email: "bob@example.com", role: "pmm" },
      { name: "Carol Davis", email: "carol@example.com", role: "csm" },
      { name: "Dave Wilson", email: "dave@example.com", role: "coordinator" },
      { name: "Eve Martinez", email: "eve@example.com", role: "admin" },
      { name: "Frank Lee", email: "frank@example.com", role: "pm" },
      { name: "Grace Kim", email: "grace@example.com", role: "csm" },
      { name: "Henry Zhang", email: "henry@example.com", role: "csm" },
    ]).returning();
    console.log(`Created ${allUsers.length} users`);
  }

  const pm = allUsers.find((u: any) => u.role === "pm")!;
  const pmm = allUsers.find((u: any) => u.role === "pmm")!;
  const csms = allUsers.filter((u: any) => u.role === "csm");
  const csm1 = csms[0]!;
  const csm2 = csms[1] ?? csm1;
  const csm3 = csms[2] ?? csm1;
  const pm2 = allUsers.find((u: any) => u.role === "pm" && u.id !== pm.id) ?? pm;
  const admin = allUsers.find((u: any) => u.role === "admin")!;

  const existingClients = await db.select().from(clientsTable);
  let allClients: any[];
  if (existingClients.length > 0) {
    console.log("Clients already seeded, skipping.");
    allClients = existingClients;
  } else {
    const SEGMENTS: Array<"Enterprise" | "Commercial" | "Midmarket" | "Channel" | "SMB"> =
      ["Enterprise", "Commercial", "Midmarket", "Channel", "SMB"];
    const healthOptions: Array<"green" | "yellow" | "red"> = ["green", "green", "green", "yellow", "yellow", "red"];
    const csmList = [csm1, csm2, csm3];
    const clientSeeds = [
      { name: "Acme Corp",       crmId: "ACC-001", segment: "Enterprise" as const, primaryContactName: "Jane Smith",    primaryContactEmail: "jane@acme.com",       vertical: "Real Estate",    productSubscriptions: "Listings, Reviews" },
      { name: "TechStart Inc",   crmId: "ACC-002", segment: "SMB" as const,        primaryContactName: "Tom Nguyen",    primaryContactEmail: "tom@techstart.io",    vertical: "Technology",     productSubscriptions: "Reviews" },
      { name: "GlobalRetail",    crmId: "ACC-003", segment: "Enterprise" as const, primaryContactName: "Sarah Chen",   primaryContactEmail: "sarah@globalretail.com",vertical: "Retail",       productSubscriptions: "Listings, Social" },
      { name: "MediHealth",      crmId: "ACC-004", segment: "Commercial" as const, primaryContactName: "Dr. Patel",    primaryContactEmail: "d.patel@medihealth.org",vertical: "Healthcare",    productSubscriptions: "Listings" },
      { name: "EduPlatform",     crmId: "ACC-005", segment: "Midmarket" as const,  primaryContactName: "Lisa Park",    primaryContactEmail: "lisa@eduplatform.com", vertical: "Education",     productSubscriptions: "Reviews, Social" },
      { name: "FinanceHub",      crmId: "ACC-006", segment: "Enterprise" as const, primaryContactName: "Mark Torres",  primaryContactEmail: "mark@financehub.com",  vertical: "Finance",       productSubscriptions: "Listings, Reviews, Social" },
      { name: "LogiFlow",        crmId: "ACC-007", segment: "Commercial" as const, primaryContactName: "Amy Johnson",  primaryContactEmail: "amy@logiflow.com",     vertical: "Logistics",     productSubscriptions: "Listings" },
      { name: "CloudNine",       crmId: "ACC-008", segment: "Midmarket" as const,  primaryContactName: "Chris Lee",    primaryContactEmail: "chris@cloudnine.io",   vertical: "Technology",    productSubscriptions: "Reviews" },
      { name: "DataStream",      crmId: "ACC-009", segment: "Enterprise" as const, primaryContactName: "Priya Sharma", primaryContactEmail: "priya@datastream.ai",  vertical: "Data/Analytics",productSubscriptions: "Listings, Reviews" },
      { name: "BuildSmart",      crmId: "ACC-010", segment: "SMB" as const,        primaryContactName: "Kevin Brown",  primaryContactEmail: "kevin@buildsmart.co",  vertical: "Construction",  productSubscriptions: "Listings" },
      { name: "RetailGiant",     crmId: "ACC-011", segment: "Enterprise" as const, primaryContactName: "Rachel Moore", primaryContactEmail: "rachel@retailgiant.com",vertical: "Retail",       productSubscriptions: "Listings, Social" },
      { name: "SecurePath",      crmId: "ACC-012", segment: "Channel" as const,    primaryContactName: "Dan Walsh",    primaryContactEmail: "dan@securepath.net",   vertical: "Cybersecurity", productSubscriptions: "Reviews" },
      { name: "FlexWork",        crmId: "ACC-013", segment: "Midmarket" as const,  primaryContactName: "Nina Patel",   primaryContactEmail: "nina@flexwork.com",    vertical: "HR Tech",       productSubscriptions: "Listings, Reviews" },
      { name: "GreenEnergy",     crmId: "ACC-014", segment: "Commercial" as const, primaryContactName: "Sam Rivera",   primaryContactEmail: "sam@greenenergy.org",  vertical: "Energy",        productSubscriptions: "Social" },
      { name: "AutoDrive",       crmId: "ACC-015", segment: "Enterprise" as const, primaryContactName: "Mei Zhang",    primaryContactEmail: "mei@autodrive.io",     vertical: "Automotive",    productSubscriptions: "Listings, Reviews, Social" },
    ];
    allClients = await db.insert(clientsTable).values(
      clientSeeds.map((c, i) => ({
        ...c,
        csmOwnerId: csmList[i % csmList.length].id,
        tier: (i % 3) + 1,
        accountHealth: healthOptions[i % healthOptions.length],
        outreachLock: false,
        contractRenewalDate: i % 3 === 0 ? `2026-${String((i % 12) + 1).padStart(2, "0")}-28` : null,
        lastOutreachDate: i % 2 === 0 ? `2026-0${(i % 4) + 1}-15` : null,
      }))
    ).returning();
    console.log(`Created ${allClients.length} clients`);
  }

  const existingFeatures = await db.select().from(betaFeaturesTable);
  if (existingFeatures.length > 0) {
    console.log("Features already seeded, skipping.");
    await pool.end();
    console.log("Seed complete.");
    return;
  }

  const features: any[] = await db.insert(betaFeaturesTable).values([
    {
      name: "AI Copilot Assistant",
      ownerPmId: pm.id, ownerPmmId: pmm.id,
      targetTesterCount: 15, status: "recruiting",
      startDate: "2026-05-01", outreachDeadline: "2026-06-01",
      idealClientCriteria: "Enterprise tier 1 customers with 500+ seats",
    },
    {
      name: "Advanced Analytics Dashboard",
      ownerPmId: pm2.id, ownerPmmId: pmm.id,
      targetTesterCount: 10, status: "in_progress",
      startDate: "2026-04-01", outreachDeadline: "2026-05-01",
      idealClientCriteria: "Customers with BI/analytics focus",
    },
    {
      name: "Mobile App v2",
      ownerPmId: pm.id, ownerPmmId: pmm.id,
      targetTesterCount: 20, status: "outreach_sent",
      startDate: "2026-05-10", outreachDeadline: "2026-06-15",
    },
    {
      name: "Smart Notifications",
      ownerPmId: pm2.id, ownerPmmId: pmm.id,
      targetTesterCount: 8, status: "draft",
      startDate: "2026-07-01", outreachDeadline: "2026-07-15",
    },
    {
      name: "API v3 Migration",
      ownerPmId: pm.id, ownerPmmId: pmm.id,
      targetTesterCount: 12, status: "closed",
      startDate: "2026-01-15", closedAt: new Date("2026-04-15"),
      closeReason: "completed", outreachDeadline: "2026-02-01",
    },
  ]).returning();
  console.log(`Created ${features.length} features`);

  const aiCopilot = features.find((f: any) => f.name === "AI Copilot Assistant")!;
  const analytics = features.find((f: any) => f.name === "Advanced Analytics Dashboard")!;

  const eligibleClients = allClients.filter((c: any) => c.accountHealth !== "red");

  await db.insert(betaEnrollmentsTable).values(
    eligibleClients.slice(0, 6).map((c: any, i: number) => ({
      clientId: c.id, featureId: aiCopilot.id, assignedById: admin.id,
      testerStatus: (["nominated", "csm_pending", "csm_approved", "csm_approved", "confirmed", "active"][i] ?? "nominated") as any,
      csmApprovalStatus: (["pending", "pending", "approved", "approved", "approved", "approved"][i] ?? "pending") as any,
    }))
  );

  await db.insert(betaEnrollmentsTable).values(
    eligibleClients.slice(6, 10).map((c: any, i: number) => ({
      clientId: c.id, featureId: analytics.id, assignedById: admin.id,
      testerStatus: (["confirmed", "active", "completed", "completed"][i] ?? "confirmed") as any,
      csmApprovalStatus: "approved" as any,
      csmApprovedById: csm1.id,
      csmApprovedAt: new Date("2026-04-05"),
      confirmedAt: new Date("2026-04-10"),
      completedAt: i >= 2 ? new Date("2026-05-01") : null,
    }))
  );

  console.log("Created enrollments");
  await pool.end();
  console.log("Seed complete.");
}

seed().catch((e) => { console.error(e); process.exit(1); });
