import { Router } from "express";
import { db, betaFeaturesTable, usersTable, betaEnrollmentsTable, auditLogsTable } from "../lib/db";
import { ok, err, parsePagination } from "../lib/helpers";
import { eq, and, or, asc, desc, count, inArray, sql } from "drizzle-orm";
import { logger } from "../lib/logger";
import { requireRole } from "../middlewares/requireRole";
import { generateUniqueSlug } from "../lib/slugify";

async function findFeature(slugOrId: string) {
  let [feature] = await db.select().from(betaFeaturesTable).where(eq(betaFeaturesTable.slug, slugOrId));
  if (!feature) [feature] = await db.select().from(betaFeaturesTable).where(eq(betaFeaturesTable.id, slugOrId));
  if (!feature) [feature] = await db.select().from(betaFeaturesTable).where(eq(betaFeaturesTable.previousSlug, slugOrId));
  return feature ?? null;
}

const router = Router();
const pmOrAdmin = requireRole("pm", "admin");

// GET /api/features
router.get("/", async (req, res) => {
  try {
    const { skip, take } = parsePagination(req.query as Record<string, string>);
    const { status, owner, sort, dir } = req.query as Record<string, string>;

    const conditions = [];
    if (status) conditions.push(eq(betaFeaturesTable.status, status as any));
    if (owner) conditions.push(or(eq(betaFeaturesTable.ownerPmId, owner), eq(betaFeaturesTable.ownerPmmId, owner)));

    const isDesc = dir === "desc";
    const orderExpr = (() => {
      switch (sort) {
        case "name":    return isDesc ? desc(betaFeaturesTable.name)      : asc(betaFeaturesTable.name);
        case "status":  return isDesc
          ? desc(sql`CASE status WHEN 'draft' THEN 1 WHEN 'in_progress' THEN 2 WHEN 'complete' THEN 3 END`)
          : asc(sql`CASE status WHEN 'draft' THEN 1 WHEN 'in_progress' THEN 2 WHEN 'complete' THEN 3 END`);
        case "slots":   return isDesc ? desc(betaFeaturesTable.targetTesterCount) : asc(betaFeaturesTable.targetTesterCount);
        case "pm":      return isDesc ? desc(betaFeaturesTable.ownerPmId)  : asc(betaFeaturesTable.ownerPmId);
        case "start":   return isDesc ? desc(betaFeaturesTable.startDate)  : asc(betaFeaturesTable.startDate);
        default:        return desc(betaFeaturesTable.createdAt);
      }
    })();

    const features = await db.select({
      ...betaFeaturesTable,
      filledCount:            sql<number>`(SELECT COUNT(*) FROM beta_enrollments e WHERE e.feature_id = "beta_features".id AND e.tester_status NOT IN ('dropped','cancelled'))`,
      enrolledCount:          sql<number>`(SELECT COUNT(*) FROM beta_enrollments e WHERE e.feature_id = "beta_features".id AND e.tester_status IN ('confirmed','active','completed'))`,
      outreachCount:          sql<number>`(SELECT COUNT(*) FROM beta_enrollments e WHERE e.feature_id = "beta_features".id AND e.tester_status IN ('csm_approved','outreach_sent'))`,
      pendingApprovalCount:   sql<number>`(SELECT COUNT(*) FROM beta_enrollments e WHERE e.feature_id = "beta_features".id AND e.csm_approval_status = 'pending')`,
    }).from(betaFeaturesTable)
      .where(conditions.length ? and(...conditions) : undefined)
      .orderBy(orderExpr)
      .offset(skip).limit(take);

    const [{ value: total }] = await db.select({ value: count() }).from(betaFeaturesTable)
      .where(conditions.length ? and(...conditions) : undefined);

    // Enrich with owner names
    const allUserIds = [...new Set(features.flatMap(f => [f.ownerPmId, f.ownerPmmId]))];
    const owners = allUserIds.length > 0 ? await db.select().from(usersTable).where(inArray(usersTable.id, allUserIds)) : [];
    const ownerMap = Object.fromEntries(owners.map(u => [u.id, u]));

    const enriched = features.map(f => ({
      ...f,
      ownerPm: ownerMap[f.ownerPmId] ?? null,
      ownerPmm: ownerMap[f.ownerPmmId] ?? null,
    }));

    return ok(res, { features: enriched, total, skip, take });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// POST /api/features
router.post("/", pmOrAdmin, async (req, res) => {
  try {
    const { name, ownerPmId, ownerPmmId, startDate, outreachDeadline, idealClientCriteria, targetTesterCount, jiraEpicLink } = req.body;
    if (!name || !ownerPmId || !ownerPmmId || !startDate || !outreachDeadline || !jiraEpicLink) {
      return err(res, "name, ownerPmId, ownerPmmId, startDate, outreachDeadline, and jiraEpicLink are required.");
    }
    const slug = await generateUniqueSlug(name);
    const [feature] = await db.insert(betaFeaturesTable).values({
      name, ownerPmId, ownerPmmId,
      startDate,
      outreachDeadline,
      idealClientCriteria,
      jiraEpicLink,
      slug,
      targetTesterCount: targetTesterCount ?? 15,
    }).returning();
    return ok(res, feature, 201);
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// GET /api/features/:id
router.get("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const feature = await findFeature(id);
    if (!feature) return err(res, "Feature not found.", 404);

    const [ownerPm] = await db.select({ id: usersTable.id, name: usersTable.name, email: usersTable.email })
      .from(usersTable).where(eq(usersTable.id, feature.ownerPmId));
    const [ownerPmm] = await db.select({ id: usersTable.id, name: usersTable.name, email: usersTable.email })
      .from(usersTable).where(eq(usersTable.id, feature.ownerPmmId));

    const enrollments = await db.select().from(betaEnrollmentsTable).where(eq(betaEnrollmentsTable.featureId, feature.id))
      .orderBy(desc(betaEnrollmentsTable.createdAt));

    // Enrich enrollments with client and assignedBy
    const { clientsTable } = await import("../lib/db");
    const clientIds = [...new Set(enrollments.map(e => e.clientId))];
    const clients = clientIds.length > 0 ? await db.select().from(clientsTable).where(inArray(clientsTable.id, clientIds)) : [];
    const clientMap = Object.fromEntries(clients.map(c => [c.id, c]));
    const assignedByIds = [...new Set(enrollments.map(e => e.assignedById))];
    const approvedByIds = [...new Set(enrollments.map(e => e.csmApprovedById).filter(Boolean) as string[])];
    const allUserIds = [...new Set([...assignedByIds, ...approvedByIds])];
    const users = allUserIds.length > 0 ? await db.select().from(usersTable).where(inArray(usersTable.id, allUserIds)) : [];
    const userMap = Object.fromEntries(users.map(u => [u.id, u]));

    const csmOwnerIds = [...new Set(clients.map(c => c.csmOwnerId))];
    const csmOwners = csmOwnerIds.length > 0 ? await db.select().from(usersTable).where(inArray(usersTable.id, csmOwnerIds)) : [];
    const csmOwnerMap = Object.fromEntries(csmOwners.map(u => [u.id, u]));

    const enrichedEnrollments = enrollments.map(e => ({
      ...e,
      client: clientMap[e.clientId] ? {
        ...clientMap[e.clientId],
        csmOwner: csmOwnerMap[clientMap[e.clientId].csmOwnerId] ?? null,
      } : null,
      assignedBy: userMap[e.assignedById] ?? null,
      csmApprovedBy: e.csmApprovedById ? (userMap[e.csmApprovedById] ?? null) : null,
    }));

    return ok(res, { ...feature, ownerPm, ownerPmm, enrollments: enrichedEnrollments });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// PUT /api/features/:id
router.put("/:id", pmOrAdmin, async (req, res) => {
  try {
    const existing = await findFeature(req.params.id);
    if (!existing) return err(res, "Feature not found.", 404);
    const id = existing.id;
    const body = req.body;
    const update: Record<string, unknown> = {};
    if (body.name !== undefined) {
      update.name = body.name;
      if (body.name !== existing.name) {
        update.previousSlug = existing.slug;
        update.slug = await generateUniqueSlug(body.name, existing.id);
      }
    }
    if (body.status !== undefined) update.status = sql`${body.status}::text::beta_status`;
    if (body.idealClientCriteria !== undefined) update.idealClientCriteria = body.idealClientCriteria;
    if (body.outreachDeadline !== undefined) update.outreachDeadline = body.outreachDeadline;
    if (body.startDate !== undefined) update.startDate = body.startDate;
    if (body.targetTesterCount !== undefined) update.targetTesterCount = body.targetTesterCount;
    if (body.jiraEpicLink !== undefined) update.jiraEpicLink = body.jiraEpicLink;
    if (body.ownerPmId !== undefined) update.ownerPmId = body.ownerPmId;
    if (body.ownerPmmId !== undefined) update.ownerPmmId = body.ownerPmmId;
    update.updatedAt = new Date();
    const [updated] = await db.update(betaFeaturesTable).set(update as any).where(eq(betaFeaturesTable.id, id)).returning();
    if (!updated) return err(res, "Feature not found.", 404);
    return ok(res, updated);
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// POST /api/features/:id/close
router.post("/:id/close", pmOrAdmin, async (req, res) => {
  try {
    const adminUser = await getAdminUser();
    const { closeReason, closeNotes, force } = req.body;

    if (!closeReason) return err(res, "closeReason is required.");

    const feature = await findFeature(req.params.id);
    if (!feature) return err(res, "Feature not found.", 404);
    const id = feature.id;
    if (feature.status === "complete") return err(res, "Beta is already complete.");

    const PRE_OUTREACH_STATUSES = ["nominated", "csm_pending", "csm_approved", "outreach_sent"];
    await db.update(betaEnrollmentsTable)
      .set({ testerStatus: "cancelled", updatedAt: new Date() })
      .where(and(eq(betaEnrollmentsTable.featureId, id), inArray(betaEnrollmentsTable.testerStatus, PRE_OUTREACH_STATUSES as any)));

    if (force) {
      await db.update(betaEnrollmentsTable)
        .set({ testerStatus: "dropped", droppedAt: new Date(), updatedAt: new Date() })
        .where(and(eq(betaEnrollmentsTable.featureId, id), eq(betaEnrollmentsTable.testerStatus, "active")));
    }

    const [updated] = await db.update(betaFeaturesTable)
      .set({ status: sql`'complete'::text::beta_status`, closedAt: new Date(), closeReason, closeNotes, updatedAt: new Date() })
      .where(eq(betaFeaturesTable.id, id)).returning();

    await db.insert(auditLogsTable).values({
      entityType: "BetaFeature", entityId: id, action: "closed",
      changedById: adminUser.id, nextState: updated as any,
    });

    return ok(res, updated);
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// POST /api/features/:id/clone
router.post("/:id/clone", pmOrAdmin, async (req, res) => {
  try {
    const adminUser = await getAdminUser();
    const body = req.body ?? {};
    const source = await findFeature(req.params.id);
    if (!source) return err(res, "Feature not found.", 404);

    const cloneName = body.name ?? `${source.name} (clone)`;
    const cloneSlug = await generateUniqueSlug(cloneName);
    const [clone] = await db.insert(betaFeaturesTable).values({
      name: cloneName,
      ownerPmId: body.ownerPmId ?? source.ownerPmId,
      ownerPmmId: body.ownerPmmId ?? source.ownerPmmId,
      targetTesterCount: source.targetTesterCount,
      status: "draft",
      startDate: body.startDate ?? source.startDate,
      outreachDeadline: body.outreachDeadline ?? source.outreachDeadline,
      idealClientCriteria: source.idealClientCriteria,
      slug: cloneSlug,
      clonedFromId: source.id,
    }).returning();

    await db.insert(auditLogsTable).values({
      entityType: "BetaFeature", entityId: clone.id, action: "cloned",
      changedById: adminUser.id, nextState: clone as any,
    });

    return ok(res, clone, 201);
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

async function getAdminUser() {
  const [admin] = await db.select().from(usersTable).where(eq(usersTable.role, "admin")).limit(1);
  if (admin) return admin;
  const [fallback] = await db.select().from(usersTable).limit(1);
  if (!fallback) throw new Error("No users found in the system.");
  return fallback;
}

export default router;
