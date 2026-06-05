import { Router } from "express";
import { db, betaEnrollmentsTable, usersTable, clientsTable, betaFeaturesTable, auditLogsTable, outreachBatchEnrollmentsTable } from "../lib/db";
import { ok, err, parsePagination } from "../lib/helpers";
import { eq, and, desc, count, inArray, isNotNull } from "drizzle-orm";
import { triggerBatching } from "../lib/batching";
import { getRequestUser } from "../lib/currentUser";

const router = Router();

const OUTREACH_WINDOW_DAYS = 14;
const ACTIVE_STATUSES = ["nominated", "csm_pending", "csm_approved", "outreach_sent"] as const;


// GET /api/enrollments
router.get("/", async (req, res) => {
  try {
    const { skip, take } = parsePagination(req.query as Record<string, string>);
    const { feature: featureId, client: clientId, status, approvalStatus } = req.query as Record<string, string>;

    const conditions = [];
    if (featureId) conditions.push(eq(betaEnrollmentsTable.featureId, featureId));
    if (clientId) conditions.push(eq(betaEnrollmentsTable.clientId, clientId));
    if (status) conditions.push(eq(betaEnrollmentsTable.testerStatus, status as any));
    if (approvalStatus) conditions.push(eq(betaEnrollmentsTable.csmApprovalStatus, approvalStatus as any));

    const enrollments = await db.select().from(betaEnrollmentsTable)
      .where(conditions.length ? and(...conditions) : undefined)
      .orderBy(desc(betaEnrollmentsTable.createdAt))
      .offset(skip).limit(take);

    const [{ value: total }] = await db.select({ value: count() }).from(betaEnrollmentsTable)
      .where(conditions.length ? and(...conditions) : undefined);

    // Enrich with client, feature, user refs
    const clientIds = [...new Set(enrollments.map(e => e.clientId))];
    const featureIds = [...new Set(enrollments.map(e => e.featureId))];
    const userIds = [...new Set([
      ...enrollments.map(e => e.assignedById),
      ...enrollments.map(e => e.csmApprovedById).filter(Boolean) as string[],
    ])];

    const [enrichedClients, enrichedFeatures, enrichedUsers] = await Promise.all([
      clientIds.length ? db.select().from(clientsTable).where(inArray(clientsTable.id, clientIds)) : Promise.resolve([]),
      featureIds.length ? db.select({ id: betaFeaturesTable.id, name: betaFeaturesTable.name, status: betaFeaturesTable.status, idealClientCriteria: betaFeaturesTable.idealClientCriteria, slug: betaFeaturesTable.slug })
        .from(betaFeaturesTable).where(inArray(betaFeaturesTable.id, featureIds)) : Promise.resolve([]),
      userIds.length ? db.select().from(usersTable).where(inArray(usersTable.id, userIds)) : Promise.resolve([]),
    ]);

    // Enrich clients with csmOwner and aeOwner
    const csmOwnerIds = [...new Set(enrichedClients.map(c => c.csmOwnerId))];
    const aeOwnerIds = [...new Set(enrichedClients.map(c => c.aeOwnerId).filter(Boolean) as string[])];
    const allClientOwnerIds = [...new Set([...csmOwnerIds, ...aeOwnerIds])];
    const clientOwners = allClientOwnerIds.length ? await db.select().from(usersTable).where(inArray(usersTable.id, allClientOwnerIds)) : [];
    const clientOwnerMap = Object.fromEntries(clientOwners.map(u => [u.id, u]));
    const clientMap = Object.fromEntries(enrichedClients.map(c => [c.id, {
      ...c,
      csmOwner: clientOwnerMap[c.csmOwnerId] ?? null,
      aeOwner: c.aeOwnerId ? (clientOwnerMap[c.aeOwnerId] ?? null) : null,
    }]));
    const featureMap = Object.fromEntries(enrichedFeatures.map(f => [f.id, f]));
    const userMap = Object.fromEntries(enrichedUsers.map(u => [u.id, u]));

    const enriched = enrollments.map(e => ({
      ...e,
      client: clientMap[e.clientId] ?? null,
      feature: featureMap[e.featureId] ?? null,
      assignedBy: userMap[e.assignedById] ?? null,
      csmApprovedBy: e.csmApprovedById ? (userMap[e.csmApprovedById] ?? null) : null,
    }));

    return ok(res, { enrollments: enriched, total, skip, take });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// POST /api/enrollments
router.post("/", async (req, res) => {
  try {
    const adminUser = await getRequestUser(req);
    const { clientId, featureId, force } = req.body;
    if (!clientId || !featureId) return err(res, "clientId and featureId are required.");

    const [client] = await db.select().from(clientsTable).where(eq(clientsTable.id, clientId));
    if (!client) return err(res, "Client not found.", 404);

    const [feature] = await db.select().from(betaFeaturesTable).where(eq(betaFeaturesTable.id, featureId));
    if (!feature) return err(res, "Feature not found.", 404);

    if (client.accountHealth === "red") {
      return err(res, "Client account health is red — nomination blocked.");
    }
    if (feature.status === "complete") {
      return err(res, "Beta is no longer accepting nominations.");
    }

    const [existing] = await db.select().from(betaEnrollmentsTable)
      .where(and(eq(betaEnrollmentsTable.clientId, clientId), eq(betaEnrollmentsTable.featureId, featureId)));
    if (existing) return res.status(409).json({ error: "Client is already nominated for this beta." });

    const windowStart = new Date();
    windowStart.setDate(windowStart.getDate() - OUTREACH_WINDOW_DAYS);
    const [{ value: activeCount }] = await db.select({ value: count() }).from(betaEnrollmentsTable)
      .where(and(
        eq(betaEnrollmentsTable.clientId, clientId),
        inArray(betaEnrollmentsTable.testerStatus, [...ACTIVE_STATUSES] as any)
      ));

    if (activeCount >= 3 && !force) {
      return res.status(409).json({
        error: `Client has ${activeCount} active enrollments in the last ${OUTREACH_WINDOW_DAYS} days. Pass force: true to override.`,
        conflict: true,
      });
    }

    const warning = client.accountHealth === "yellow"
      ? "Client account health is yellow — proceed with CSM discretion."
      : undefined;

    const [{ value: confirmedCount }] = await db.select({ value: count() }).from(betaEnrollmentsTable)
      .where(and(
        eq(betaEnrollmentsTable.featureId, featureId),
        inArray(betaEnrollmentsTable.testerStatus, ["confirmed", "active", "completed"] as any)
      ));

    const [enrollment] = await db.insert(betaEnrollmentsTable).values({
      clientId, featureId,
      assignedById: adminUser.id,
      isOverflow: confirmedCount >= feature.targetTesterCount,
      testerStatus: "nominated",
      csmApprovalStatus: "pending",
    }).returning();

    await db.insert(auditLogsTable).values({
      entityType: "BetaEnrollment", entityId: enrollment.id, action: "nominated",
      changedById: adminUser.id, nextState: enrollment as any,
    });

    const ownerIds = [client.csmOwnerId, ...(client.aeOwnerId ? [client.aeOwnerId] : [])];
    const owners = await db.select().from(usersTable).where(inArray(usersTable.id, ownerIds));
    const ownerMap = Object.fromEntries(owners.map(u => [u.id, u]));
    const enrichedClient = {
      ...client,
      csmOwner: ownerMap[client.csmOwnerId] ?? null,
      aeOwner: client.aeOwnerId ? (ownerMap[client.aeOwnerId] ?? null) : null,
    };

    return res.status(201).json({ enrollment: { ...enrollment, client: enrichedClient }, warning });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// PATCH /api/enrollments/:id
router.patch("/:id", async (req, res) => {
  try {
    const adminUser = await getRequestUser(req);
    const { id } = req.params;
    const { status } = req.body;

    const ALLOWED = ["nominated", "csm_approved", "enrolled", "using", "accepted"];
    if (!status || !ALLOWED.includes(status)) {
      return err(res, `status must be one of: ${ALLOWED.join(", ")}.`);
    }

    const [enrollment] = await db.select().from(betaEnrollmentsTable).where(eq(betaEnrollmentsTable.id, id));
    if (!enrollment) return err(res, "Enrollment not found.", 404);

    const [updated] = await db.update(betaEnrollmentsTable).set({
      testerStatus: status as any,
      updatedAt: new Date(),
    }).where(eq(betaEnrollmentsTable.id, id)).returning();

    await db.insert(auditLogsTable).values({
      entityType: "BetaEnrollment", entityId: id, action: "status_change",
      changedById: adminUser.id, priorState: enrollment as any, nextState: updated as any,
    });

    return ok(res, updated);
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// DELETE /api/enrollments/:id
router.delete("/:id", async (req, res) => {
  try {
    const adminUser = await getRequestUser(req);
    const { id } = req.params;
    const [enrollment] = await db.select().from(betaEnrollmentsTable).where(eq(betaEnrollmentsTable.id, id));
    if (!enrollment) return err(res, "Enrollment not found.", 404);

    const preOutreach = ["nominated", "csm_pending", "csm_approved"];
    if (!preOutreach.includes(enrollment.testerStatus)) {
      return err(res, "Cannot remove an enrollment after outreach has been sent.");
    }

    await db.delete(betaEnrollmentsTable).where(eq(betaEnrollmentsTable.id, id));
    await db.insert(auditLogsTable).values({
      entityType: "BetaEnrollment", entityId: id, action: "removed",
      changedById: adminUser.id, priorState: enrollment as any,
    });

    return ok(res, { success: true });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// POST /api/enrollments/:id/approve
router.post("/:id/approve", async (req, res) => {
  try {
    const adminUser = await getRequestUser(req);
    const { id } = req.params;

    const [enrollment] = await db.select().from(betaEnrollmentsTable).where(eq(betaEnrollmentsTable.id, id));
    if (!enrollment) return err(res, "Enrollment not found.", 404);

    const [updated] = await db.update(betaEnrollmentsTable).set({
      csmApprovalStatus: "approved",
      csmApprovedById: adminUser.id,
      csmApprovedAt: new Date(),
      testerStatus: "csm_approved",
      updatedAt: new Date(),
    }).where(eq(betaEnrollmentsTable.id, id)).returning();

    await db.insert(auditLogsTable).values({
      entityType: "BetaEnrollment", entityId: id, action: "csm_approved",
      changedById: adminUser.id, priorState: enrollment as any, nextState: updated as any,
    });

    triggerBatching(updated.featureId).catch((batchErr) => {
      req.log.error({ err: batchErr }, "Auto-batch failed after approval");
    });

    return ok(res, updated);
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// POST /api/enrollments/:id/unapprove
router.post("/:id/unapprove", async (req, res) => {
  try {
    const adminUser = await getRequestUser(req);
    const { id } = req.params;

    const [enrollment] = await db.select().from(betaEnrollmentsTable).where(eq(betaEnrollmentsTable.id, id));
    if (!enrollment) return err(res, "Enrollment not found.", 404);
    if (enrollment.testerStatus !== "csm_approved") {
      return err(res, "Enrollment is not in an approvable state.");
    }

    const [updated] = await db.update(betaEnrollmentsTable).set({
      csmApprovalStatus: "pending",
      csmApprovedById: null,
      csmApprovedAt: null,
      testerStatus: "nominated",
      updatedAt: new Date(),
    }).where(eq(betaEnrollmentsTable.id, id)).returning();

    await db.insert(auditLogsTable).values({
      entityType: "BetaEnrollment", entityId: id, action: "csm_approval_revoked",
      changedById: adminUser.id, priorState: enrollment as any, nextState: updated as any,
    });

    return ok(res, updated);
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// POST /api/enrollments/:id/reject
router.post("/:id/reject", async (req, res) => {
  try {
    const adminUser = await getRequestUser(req);
    const { id } = req.params;
    const { reason } = req.body;
    if (!reason?.trim()) return err(res, "reason is required.");

    const [enrollment] = await db.select().from(betaEnrollmentsTable).where(eq(betaEnrollmentsTable.id, id));
    if (!enrollment) return err(res, "Enrollment not found.", 404);

    const [updated] = await db.update(betaEnrollmentsTable).set({
      csmApprovalStatus: "rejected",
      csmRejectionReason: reason,
      testerStatus: "dropped",
      droppedAt: new Date(),
      updatedAt: new Date(),
    }).where(eq(betaEnrollmentsTable.id, id)).returning();

    await db.insert(auditLogsTable).values({
      entityType: "BetaEnrollment", entityId: id, action: "csm_rejected",
      changedById: adminUser.id, priorState: enrollment as any, nextState: updated as any,
    });

    return ok(res, updated);
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// PUT /api/enrollments/:id/status
router.put("/:id/status", async (req, res) => {
  try {
    const adminUser = await getRequestUser(req);
    const { id } = req.params;
    const { testerStatus, dropReason } = req.body;
    if (!testerStatus) return err(res, "testerStatus is required.");

    const [enrollment] = await db.select().from(betaEnrollmentsTable).where(eq(betaEnrollmentsTable.id, id));
    if (!enrollment) return err(res, "Enrollment not found.", 404);

    const timestamps: Record<string, Date> = {};
    if (testerStatus === "confirmed") timestamps.confirmedAt = new Date();
    if (testerStatus === "completed") timestamps.completedAt = new Date();
    if (testerStatus === "dropped") timestamps.droppedAt = new Date();

    const [updated] = await db.update(betaEnrollmentsTable).set({
      testerStatus, dropReason, ...timestamps, updatedAt: new Date(),
    }).where(eq(betaEnrollmentsTable.id, id)).returning();

    await db.insert(auditLogsTable).values({
      entityType: "BetaEnrollment", entityId: id, action: "status_change",
      changedById: adminUser.id, priorState: enrollment as any, nextState: updated as any,
    });

    return ok(res, updated);
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

export default router;
