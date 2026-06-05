import { Router } from "express";
import { db, outreachBatchesTable, outreachBatchEnrollmentsTable, betaEnrollmentsTable, clientsTable, usersTable, betaFeaturesTable, auditLogsTable } from "../lib/db";
import { ok, err } from "../lib/helpers";
import { eq, and, desc, inArray } from "drizzle-orm";
import { triggerBatching } from "../lib/batching";

const router = Router();

const COOLDOWN_DAYS = 30;

async function getAdminUser() {
  const [admin] = await db.select().from(usersTable).where(eq(usersTable.role, "admin")).limit(1);
  if (!admin) throw new Error("No admin user found.");
  return admin;
}

// GET /api/batches
router.get("/", async (req, res) => {
  try {
    const batches = await db.select().from(outreachBatchesTable)
      .orderBy(desc(outreachBatchesTable.createdAt));

    const total = batches.length;

    const clientIds = [...new Set(batches.map(b => b.clientId))];
    const clients = clientIds.length > 0 ? await db.select().from(clientsTable).where(inArray(clientsTable.id, clientIds)) : [];
    const clientMap = Object.fromEntries(clients.map(c => [c.id, c]));

    const batchIds = batches.map(b => b.id);
    const batchEntries = batchIds.length > 0 ? await db.select().from(outreachBatchEnrollmentsTable)
      .where(inArray(outreachBatchEnrollmentsTable.batchId, batchIds)) : [];

    const enrollmentIds = [...new Set(batchEntries.map(e => e.enrollmentId))];
    const enrollments = enrollmentIds.length > 0 ? await db.select().from(betaEnrollmentsTable)
      .where(inArray(betaEnrollmentsTable.id, enrollmentIds)) : [];
    const enrollmentMap = Object.fromEntries(enrollments.map(e => [e.id, e]));

    const featureIds = [...new Set(enrollments.map(e => e.featureId))];
    const features = featureIds.length > 0 ? await db.select({
      id: betaFeaturesTable.id,
      name: betaFeaturesTable.name,
      slug: betaFeaturesTable.slug,
      status: betaFeaturesTable.status,
      idealClientCriteria: betaFeaturesTable.idealClientCriteria,
      betaGoal: betaFeaturesTable.betaGoal,
      targetTesterCount: betaFeaturesTable.targetTesterCount,
      ownerPmId: betaFeaturesTable.ownerPmId,
      ownerPmmId: betaFeaturesTable.ownerPmmId,
    }).from(betaFeaturesTable).where(inArray(betaFeaturesTable.id, featureIds)) : [];
    const featureMap = Object.fromEntries(features.map(f => [f.id, f]));

    // Collect all user IDs in one pass
    const userIdSet = new Set<string>();
    batches.forEach(b => {
      if (b.sentById) userIdSet.add(b.sentById);
      if (b.senderId) userIdSet.add(b.senderId);
      (b.ccIds ?? []).forEach(id => userIdSet.add(id));
    });
    clients.forEach(c => {
      userIdSet.add(c.csmOwnerId);
      if (c.aeOwnerId) userIdSet.add(c.aeOwnerId);
    });
    features.forEach(f => {
      if (f.ownerPmId) userIdSet.add(f.ownerPmId);
      if (f.ownerPmmId) userIdSet.add(f.ownerPmmId);
    });
    enrollments.forEach(e => {
      if (e.csmApprovedById) userIdSet.add(e.csmApprovedById);
    });

    const allUsers = userIdSet.size > 0 ? await db.select().from(usersTable).where(inArray(usersTable.id, [...userIdSet])) : [];
    const userMap = Object.fromEntries(allUsers.map(u => [u.id, u]));

    const enrichedBatches = batches.map(b => {
      const client = clientMap[b.clientId] ?? null;
      return {
        ...b,
        client: client ? {
          ...client,
          csmOwner: client.csmOwnerId ? (userMap[client.csmOwnerId] ?? null) : null,
          aeOwner: client.aeOwnerId ? (userMap[client.aeOwnerId] ?? null) : null,
        } : null,
        sentBy: b.sentById ? (userMap[b.sentById] ?? null) : null,
        sender: b.senderId ? (userMap[b.senderId] ?? null) : null,
        ccUsers: (b.ccIds ?? []).map(id => userMap[id]).filter(Boolean),
        enrollments: batchEntries
          .filter(be => be.batchId === b.id)
          .map(be => {
            const e = enrollmentMap[be.enrollmentId];
            const f = e ? (featureMap[e.featureId] ?? null) : null;
            return {
              ...be,
              enrollment: e ? {
                ...e,
                feature: f ? {
                  ...f,
                  ownerPm: f.ownerPmId ? (userMap[f.ownerPmId] ?? null) : null,
                  ownerPmm: f.ownerPmmId ? (userMap[f.ownerPmmId] ?? null) : null,
                } : null,
                csmApprovedBy: e.csmApprovedById ? (userMap[e.csmApprovedById] ?? null) : null,
              } : null,
            };
          }),
      };
    });

    return ok(res, { batches: enrichedBatches, total });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// PUT /api/batches/:id — update sender and/or ccIds
router.put("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { senderId, ccIds } = req.body ?? {};

    const [existing] = await db.select().from(outreachBatchesTable).where(eq(outreachBatchesTable.id, id));
    if (!existing) return err(res, "Batch not found.", 404);

    const updates: Record<string, unknown> = { updatedAt: new Date() };
    if (senderId !== undefined) updates.senderId = senderId || null;
    if (ccIds !== undefined) updates.ccIds = ccIds;

    await db.update(outreachBatchesTable).set(updates).where(eq(outreachBatchesTable.id, id));
    const [updated] = await db.select().from(outreachBatchesTable).where(eq(outreachBatchesTable.id, id));
    return ok(res, updated);
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// POST /api/batches/trigger — group all approved unbatched enrollments
router.post("/trigger", async (req, res) => {
  try {
    const created = await triggerBatching(null);
    return ok(res, { batched: created });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// POST /api/batches/trigger-for-feature/:featureId — group approved unbatched enrollments for one feature
router.post("/trigger-for-feature/:featureId", async (req, res) => {
  try {
    const created = await triggerBatching(req.params.featureId);
    return ok(res, { batched: created });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// POST /api/batches/:id/send
router.post("/:id/send", async (req, res) => {
  try {
    const adminUser = await getAdminUser();
    const { id } = req.params;
    const { overrideCooldown } = req.body ?? {};

    const [batch] = await db.select().from(outreachBatchesTable).where(eq(outreachBatchesTable.id, id));
    if (!batch) return err(res, "Batch not found.", 404);
    if (batch.batchStatus === "sent") return err(res, "Batch already sent.");

    const [client] = await db.select().from(clientsTable).where(eq(clientsTable.id, batch.clientId));
    if (client.lastOutreachDate && !overrideCooldown) {
      const daysSince = (Date.now() - new Date(client.lastOutreachDate).getTime()) / (1000 * 60 * 60 * 24);
      if (daysSince < COOLDOWN_DAYS) {
        return res.status(409).json({
          error: `Client is within ${COOLDOWN_DAYS}-day cooldown (last outreach ${Math.floor(daysSince)} days ago).`,
          cooldown: true,
        });
      }
    }

    const batchEntries = await db.select().from(outreachBatchEnrollmentsTable)
      .where(eq(outreachBatchEnrollmentsTable.batchId, id));
    const enrollmentIds = batchEntries.map(be => be.enrollmentId);
    const now = new Date();

    await db.update(outreachBatchesTable).set({ batchStatus: "sent", sentAt: now, sentById: adminUser.id, updatedAt: now })
      .where(eq(outreachBatchesTable.id, id));

    if (enrollmentIds.length > 0) {
      await db.update(betaEnrollmentsTable).set({ testerStatus: "outreach_sent", outreachSentAt: now, updatedAt: now })
        .where(inArray(betaEnrollmentsTable.id, enrollmentIds));
    }

    await db.update(clientsTable).set({ lastOutreachDate: now.toISOString().split("T")[0], updatedAt: now })
      .where(eq(clientsTable.id, batch.clientId));

    await db.insert(auditLogsTable).values({
      entityType: "OutreachBatch", entityId: id, action: "outreach_sent",
      changedById: adminUser.id, nextState: { batchId: id, clientId: batch.clientId, enrollmentIds } as any,
    });

    return ok(res, { success: true });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

export default router;
