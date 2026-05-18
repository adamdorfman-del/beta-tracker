import { Router } from "express";
import { db, outreachBatchesTable, outreachBatchEnrollmentsTable, betaEnrollmentsTable, clientsTable, usersTable, betaFeaturesTable, auditLogsTable } from "../lib/db";
import { ok, err, parsePagination } from "../lib/helpers";
import { eq, and, desc, count, inArray, isNotNull } from "drizzle-orm";

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
    const { skip, take } = parsePagination(req.query as Record<string, string>);

    const batches = await db.select().from(outreachBatchesTable)
      .orderBy(desc(outreachBatchesTable.createdAt))
      .offset(skip).limit(take);

    const [{ value: total }] = await db.select({ value: count() }).from(outreachBatchesTable);

    const clientIds = [...new Set(batches.map(b => b.clientId))];
    const clients = clientIds.length > 0 ? await db.select().from(clientsTable).where(inArray(clientsTable.id, clientIds)) : [];
    const clientMap = Object.fromEntries(clients.map(c => [c.id, c]));

    const sentByIds = [...new Set(batches.map(b => b.sentById).filter(Boolean) as string[])];
    const sentByUsers = sentByIds.length > 0 ? await db.select().from(usersTable).where(inArray(usersTable.id, sentByIds)) : [];
    const userMap = Object.fromEntries(sentByUsers.map(u => [u.id, u]));

    const batchIds = batches.map(b => b.id);
    const batchEntries = batchIds.length > 0 ? await db.select().from(outreachBatchEnrollmentsTable)
      .where(inArray(outreachBatchEnrollmentsTable.batchId, batchIds)) : [];

    const enrollmentIds = [...new Set(batchEntries.map(e => e.enrollmentId))];
    const enrollments = enrollmentIds.length > 0 ? await db.select().from(betaEnrollmentsTable)
      .where(inArray(betaEnrollmentsTable.id, enrollmentIds)) : [];
    const enrollmentMap = Object.fromEntries(enrollments.map(e => [e.id, e]));

    const featureIds = [...new Set(enrollments.map(e => e.featureId))];
    const features = featureIds.length > 0 ? await db.select({
      id: betaFeaturesTable.id, name: betaFeaturesTable.name
    }).from(betaFeaturesTable).where(inArray(betaFeaturesTable.id, featureIds)) : [];
    const featureMap = Object.fromEntries(features.map(f => [f.id, f]));

    const approvedByIds = [...new Set(enrollments.map(e => e.csmApprovedById).filter(Boolean) as string[])];
    const approvedByUsers = approvedByIds.length > 0 ? await db.select().from(usersTable).where(inArray(usersTable.id, approvedByIds)) : [];
    const approvedByMap = Object.fromEntries(approvedByUsers.map(u => [u.id, u]));

    const enrichedBatches = batches.map(b => ({
      ...b,
      client: clientMap[b.clientId] ?? null,
      sentBy: b.sentById ? (userMap[b.sentById] ?? null) : null,
      enrollments: batchEntries
        .filter(be => be.batchId === b.id)
        .map(be => {
          const e = enrollmentMap[be.enrollmentId];
          return {
            ...be,
            enrollment: e ? {
              ...e,
              feature: featureMap[e.featureId] ?? null,
              csmApprovedBy: e.csmApprovedById ? (approvedByMap[e.csmApprovedById] ?? null) : null,
            } : null,
          };
        }),
    }));

    return ok(res, { batches: enrichedBatches, total, skip, take });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// POST /api/batches/trigger
router.post("/trigger", async (req, res) => {
  try {
    // Group all csm_approved enrollments not yet in a batch by client
    const unbatched = await db.select().from(betaEnrollmentsTable)
      .where(and(
        eq(betaEnrollmentsTable.csmApprovalStatus, "approved"),
        eq(betaEnrollmentsTable.testerStatus, "csm_approved"),
      ));

    // Filter out those already in a batch
    const allBatchEntries = await db.select().from(outreachBatchEnrollmentsTable);
    const batchedEnrollmentIds = new Set(allBatchEntries.map(e => e.enrollmentId));
    const toGroup = unbatched.filter(e => !batchedEnrollmentIds.has(e.id));

    const byClient = new Map<string, typeof toGroup>();
    for (const e of toGroup) {
      const list = byClient.get(e.clientId) ?? [];
      list.push(e);
      byClient.set(e.clientId, list);
    }

    let created = 0;
    for (const [clientId, enrollments] of byClient) {
      // Find existing open batch for this client
      const [existingBatch] = await db.select().from(outreachBatchesTable)
        .where(and(
          eq(outreachBatchesTable.clientId, clientId),
          inArray(outreachBatchesTable.batchStatus, ["pending", "ready"] as any)
        )).limit(1);

      let batchId = existingBatch?.id;
      if (!batchId) {
        const [batch] = await db.insert(outreachBatchesTable).values({ clientId, batchStatus: "pending" }).returning();
        batchId = batch.id;
        created++;
      }

      for (const e of enrollments) {
        await db.insert(outreachBatchEnrollmentsTable).values({ batchId, enrollmentId: e.id })
          .onConflictDoNothing();
      }

      // Check if all enrollments are CSM approved → ready
      const batchEntries = await db.select().from(outreachBatchEnrollmentsTable)
        .where(eq(outreachBatchEnrollmentsTable.batchId, batchId));
      const batchEnrollmentIds = batchEntries.map(be => be.enrollmentId);
      if (batchEnrollmentIds.length > 0) {
        const [{ value: pendingCount }] = await db.select({ value: count() }).from(betaEnrollmentsTable)
          .where(and(
            inArray(betaEnrollmentsTable.id, batchEnrollmentIds),
            eq(betaEnrollmentsTable.csmApprovalStatus, "pending")
          ));
        if (pendingCount === 0) {
          await db.update(outreachBatchesTable).set({ batchStatus: "ready", updatedAt: new Date() })
            .where(and(eq(outreachBatchesTable.id, batchId), eq(outreachBatchesTable.batchStatus, "pending")));
        }
      }
    }

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

    return ok(res, { success: true });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

export default router;
