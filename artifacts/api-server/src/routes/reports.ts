import { Router } from "express";
import { db, betaFeaturesTable, betaEnrollmentsTable, clientsTable, usersTable, auditLogsTable, feedbackTable } from "../lib/db";
import { ok, err, parsePagination, parseDateRange } from "../lib/helpers";
import { eq, and, desc, count, inArray, isNotNull, lte, gte, notInArray, isNull, sql } from "drizzle-orm";

const router = Router();

// GET /api/reports/overview
router.get("/overview", async (req, res) => {
  try {
    const features = await db.select().from(betaFeaturesTable);
    const featureCountsByStatus: Record<string, number> = {};
    for (const f of features) {
      featureCountsByStatus[f.status] = (featureCountsByStatus[f.status] ?? 0) + 1;
    }

    const [{ value: totalConfirmed }] = await db.select({ value: count() }).from(betaEnrollmentsTable)
      .where(inArray(betaEnrollmentsTable.testerStatus, ["confirmed", "active"] as any));
    const [{ value: totalOutreachSent }] = await db.select({ value: count() }).from(betaEnrollmentsTable)
      .where(eq(betaEnrollmentsTable.testerStatus, "outreach_sent" as any));

    const today = new Date();
    const activeFeatures = features.filter(f => !f.closedAt && new Date(f.startDate) <= today);
    const durations = activeFeatures.map(f =>
      (today.getTime() - new Date(f.startDate).getTime()) / 86400000
    );
    const avgBetaDurationDays = durations.length
      ? Math.round(durations.reduce((a, b) => a + b, 0) / durations.length)
      : null;

    return ok(res, { featureCountsByStatus, totalConfirmed, totalOutreachSent, avgBetaDurationDays });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// GET /api/reports/at-risk
router.get("/at-risk", async (req, res) => {
  try {
    const now = new Date();
    const soonStart = new Date(now.getTime() + 5 * 86400000);

    const underFilledFeatures = await db.select().from(betaFeaturesTable)
      .where(and(
        inArray(betaFeaturesTable.status, ["in_progress"] as any),
        lte(betaFeaturesTable.startDate, soonStart.toISOString().split("T")[0])
      ));

    const featureIds = underFilledFeatures.map(f => f.id);
    const pmIds = [...new Set(underFilledFeatures.map(f => f.ownerPmId))];
    const pms = pmIds.length > 0 ? await db.select().from(usersTable).where(inArray(usersTable.id, pmIds)) : [];
    const pmMap = Object.fromEntries(pms.map(u => [u.id, u]));

    const confirmedCounts: Record<string, number> = {};
    if (featureIds.length > 0) {
      const rows = await db.select({ featureId: betaEnrollmentsTable.featureId, value: count() })
        .from(betaEnrollmentsTable)
        .where(and(
          inArray(betaEnrollmentsTable.featureId, featureIds),
          inArray(betaEnrollmentsTable.testerStatus, ["confirmed", "active"] as any)
        ))
        .groupBy(betaEnrollmentsTable.featureId);
      for (const r of rows) confirmedCounts[r.featureId] = r.value;
    }

    const staleThreshold = new Date(now.getTime() - 48 * 3600000);
    const staleApprovals = await db.select().from(betaEnrollmentsTable)
      .where(and(
        eq(betaEnrollmentsTable.csmApprovalStatus, "pending"),
        lte(betaEnrollmentsTable.createdAt, staleThreshold)
      ));

    const clientIds = [...new Set(staleApprovals.map(e => e.clientId))];
    const saFeatureIds = [...new Set(staleApprovals.map(e => e.featureId))];
    const [saClients, saFeatures] = await Promise.all([
      clientIds.length > 0 ? db.select().from(clientsTable).where(inArray(clientsTable.id, clientIds)) : Promise.resolve([]),
      saFeatureIds.length > 0 ? db.select({ id: betaFeaturesTable.id, name: betaFeaturesTable.name, slug: betaFeaturesTable.slug }).from(betaFeaturesTable).where(inArray(betaFeaturesTable.id, saFeatureIds)) : Promise.resolve([]),
    ]);
    const saClientMap = Object.fromEntries(saClients.map(c => [c.id, c]));
    const saFeatureMap = Object.fromEntries(saFeatures.map(f => [f.id, f]));
    const csmIds = [...new Set(saClients.map(c => c.csmOwnerId))];
    const csmOwners = csmIds.length > 0 ? await db.select().from(usersTable).where(inArray(usersTable.id, csmIds)) : [];
    const csmOwnerMap = Object.fromEntries(csmOwners.map(u => [u.id, u]));

    return ok(res, {
      underFilledFeatures: underFilledFeatures.map(f => ({
        id: f.id, name: f.name, status: f.status, startDate: f.startDate,
        confirmedCount: confirmedCounts[f.id] ?? 0,
        target: f.targetTesterCount,
        ownerPm: pmMap[f.ownerPmId] ?? null,
      })),
      staleApprovals: staleApprovals.map(e => ({
        enrollmentId: e.id,
        feature: saFeatureMap[e.featureId] ?? null,
        client: saClientMap[e.clientId] ? { id: saClientMap[e.clientId].id, name: saClientMap[e.clientId].name } : null,
        csmOwner: saClientMap[e.clientId] ? (csmOwnerMap[saClientMap[e.clientId].csmOwnerId] ?? null) : null,
        pendingSinceDays: Math.round((now.getTime() - new Date(e.createdAt).getTime()) / 86400000),
      })),
    });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// GET /api/reports/features
router.get("/features", async (req, res) => {
  try {
    const features = await db.select().from(betaFeaturesTable).orderBy(desc(betaFeaturesTable.startDate));
    const featureIds = features.map(f => f.id);
    const pmIds = [...new Set(features.map(f => f.ownerPmId))];
    const pms = pmIds.length > 0 ? await db.select().from(usersTable).where(inArray(usersTable.id, pmIds)) : [];
    const pmMap = Object.fromEntries(pms.map(u => [u.id, u]));

    const enrollments = featureIds.length > 0
      ? await db.select().from(betaEnrollmentsTable).where(inArray(betaEnrollmentsTable.featureId, featureIds))
      : [];

    const byFeature = new Map<string, typeof enrollments>();
    for (const e of enrollments) {
      const list = byFeature.get(e.featureId) ?? [];
      list.push(e);
      byFeature.set(e.featureId, list);
    }

    const rows = features.map(f => {
      const fe = byFeature.get(f.id) ?? [];
      const confirmed = fe.filter(e => ["confirmed", "active", "completed"].includes(e.testerStatus));
      const completed = fe.filter(e => e.testerStatus === "completed").length;
      const dropped = fe.filter(e => e.testerStatus === "dropped").length;
      const outreachSent = fe.filter(e => e.outreachSentAt).length;
      const confirmedDates = confirmed.map(e => e.confirmedAt).filter(Boolean).map(d => new Date(d!)).sort((a, b) => a.getTime() - b.getTime());
      const fifteenthConfirmed = confirmedDates[14] ?? null;
      const durationDays = f.closedAt
        ? Math.round((new Date(f.closedAt).getTime() - new Date(f.startDate).getTime()) / 86400000)
        : null;
      return {
        id: f.id, name: f.name, status: f.status, ownerPm: pmMap[f.ownerPmId] ?? null,
        startDate: f.startDate, closedAt: f.closedAt, durationDays,
        timeToFillDays: fifteenthConfirmed ? Math.round((fifteenthConfirmed.getTime() - new Date(f.startDate).getTime()) / 86400000) : null,
        confirmed: confirmed.length, target: f.targetTesterCount,
        fillRate: f.targetTesterCount > 0 ? confirmed.length / f.targetTesterCount : null,
        completionRate: completed + dropped > 0 ? completed / (completed + dropped) : null,
        outreachConversionRate: outreachSent > 0 ? confirmed.length / outreachSent : null,
      };
    });

    return ok(res, { features: rows });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// GET /api/reports/clients
router.get("/clients", async (req, res) => {
  try {
    const clients = await db.select().from(clientsTable).orderBy(clientsTable.tier);
    const clientIds = clients.map(c => c.id);
    const csmIds = [...new Set(clients.map(c => c.csmOwnerId))];
    const csms = csmIds.length > 0 ? await db.select().from(usersTable).where(inArray(usersTable.id, csmIds)) : [];
    const csmMap = Object.fromEntries(csms.map(u => [u.id, u]));

    const enrollments = clientIds.length > 0
      ? await db.select().from(betaEnrollmentsTable).where(inArray(betaEnrollmentsTable.clientId, clientIds))
      : [];

    const byClient = new Map<string, typeof enrollments>();
    for (const e of enrollments) {
      const list = byClient.get(e.clientId) ?? [];
      list.push(e);
      byClient.set(e.clientId, list);
    }

    const rows = clients.map(c => {
      const ce = byClient.get(c.id) ?? [];
      const completed = ce.filter(e => e.testerStatus === "completed").length;
      const dropped = ce.filter(e => e.testerStatus === "dropped").length;
      return {
        id: c.id, name: c.name, tier: c.tier, accountHealth: c.accountHealth,
        csmOwner: csmMap[c.csmOwnerId] ?? null, lastOutreachDate: c.lastOutreachDate,
        totalEnrollments: ce.length, completed, dropped,
        completionRate: completed + dropped > 0 ? completed / (completed + dropped) : null,
      };
    });

    return ok(res, { clients: rows });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// GET /api/reports/csm-responsiveness
router.get("/csm-responsiveness", async (req, res) => {
  try {
    const approved = await db.select({
      csmApprovedById: betaEnrollmentsTable.csmApprovedById,
      csmApprovedAt: betaEnrollmentsTable.csmApprovedAt,
      createdAt: betaEnrollmentsTable.createdAt,
    }).from(betaEnrollmentsTable)
      .where(and(
        eq(betaEnrollmentsTable.csmApprovalStatus, "approved"),
        isNotNull(betaEnrollmentsTable.csmApprovedAt)
      ));

    const byCsm = new Map<string, { totalMs: number; count: number }>();
    for (const e of approved) {
      if (!e.csmApprovedById || !e.csmApprovedAt) continue;
      const ms = new Date(e.csmApprovedAt).getTime() - new Date(e.createdAt).getTime();
      const entry = byCsm.get(e.csmApprovedById) ?? { totalMs: 0, count: 0 };
      entry.totalMs += ms;
      entry.count += 1;
      byCsm.set(e.csmApprovedById, entry);
    }

    const csmIds = [...byCsm.keys()];
    const csms = csmIds.length > 0 ? await db.select().from(usersTable).where(inArray(usersTable.id, csmIds)) : [];
    const csmMap = Object.fromEntries(csms.map(u => [u.id, u]));

    const rows = csmIds.map(id => {
      const { totalMs, count } = byCsm.get(id)!;
      return { id, name: csmMap[id]?.name ?? id, count, avgHours: Math.round(totalMs / count / 3600000) };
    }).sort((a, b) => a.avgHours - b.avgHours);

    return ok(res, { csms: rows });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// GET /api/reports/sentiment-by-beta
router.get("/sentiment-by-beta", async (req, res) => {
  try {
    const activeStatuses = ["draft", "in_progress"];
    const features = await db
      .select({ id: betaFeaturesTable.id, name: betaFeaturesTable.name, slug: betaFeaturesTable.slug, status: betaFeaturesTable.status })
      .from(betaFeaturesTable)
      .where(inArray(betaFeaturesTable.status, activeStatuses as any));

    if (features.length === 0) return ok(res, { features: [] });

    const featureIds = features.map(f => f.id);
    const feedbackRows = await db
      .select({
        featureId: feedbackTable.featureId,
        total:    sql<number>`COUNT(*)`,
        positive: sql<number>`SUM(CASE WHEN ${feedbackTable.sentiment} = 'positive' THEN 1 ELSE 0 END)`,
      })
      .from(feedbackTable)
      .where(inArray(feedbackTable.featureId, featureIds))
      .groupBy(feedbackTable.featureId);

    const feedbackMap = Object.fromEntries(feedbackRows.map(r => [r.featureId, r]));

    const result = features.map(f => {
      const fb = feedbackMap[f.id];
      const total    = fb ? Number(fb.total)    : 0;
      const positive = fb ? Number(fb.positive) : 0;
      return {
        id: f.id, name: f.name, slug: f.slug, status: f.status,
        total,
        positive,
        positiveRate: total > 0 ? positive / total : null,
      };
    });

    return ok(res, { features: result });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// GET /api/reports/activity
router.get("/activity", async (req, res) => {
  try {
    const logs = await db.select().from(auditLogsTable)
      .orderBy(desc(auditLogsTable.createdAt))
      .limit(10);

    if (logs.length === 0) return ok(res, { activities: [] });

    const userIds = [...new Set(logs.map(l => l.changedById))];
    const users = userIds.length > 0
      ? await db.select({ id: usersTable.id, name: usersTable.name }).from(usersTable).where(inArray(usersTable.id, userIds))
      : [];
    const userMap = Object.fromEntries(users.map(u => [u.id, u]));

    const clientIdSet = new Set<string>();
    const featureIdSet = new Set<string>();
    for (const log of logs) {
      const state = (log.nextState ?? log.priorState) as any;
      if (state?.clientId) clientIdSet.add(state.clientId);
      if (state?.featureId) featureIdSet.add(state.featureId);
    }

    const [clients, features] = await Promise.all([
      clientIdSet.size > 0
        ? db.select({ id: clientsTable.id, name: clientsTable.name }).from(clientsTable).where(inArray(clientsTable.id, [...clientIdSet]))
        : Promise.resolve([]),
      featureIdSet.size > 0
        ? db.select({ id: betaFeaturesTable.id, name: betaFeaturesTable.name, slug: betaFeaturesTable.slug }).from(betaFeaturesTable).where(inArray(betaFeaturesTable.id, [...featureIdSet]))
        : Promise.resolve([]),
    ]);
    const clientMap = Object.fromEntries(clients.map(c => [c.id, c]));
    const featureMap = Object.fromEntries(features.map(f => [f.id, f]));

    const activities = logs.map(log => {
      const state = (log.nextState ?? log.priorState) as any;
      const client = state?.clientId ? clientMap[state.clientId] : null;
      const feature = state?.featureId ? featureMap[state.featureId] : null;
      return {
        id: log.id,
        action: log.action,
        entityType: log.entityType,
        clientName: client?.name ?? null,
        featureName: feature?.name ?? null,
        featureSlug: (feature as any)?.slug ?? null,
        actorName: userMap[log.changedById]?.name ?? null,
        createdAt: log.createdAt,
      };
    });

    return ok(res, { activities });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

export default router;
