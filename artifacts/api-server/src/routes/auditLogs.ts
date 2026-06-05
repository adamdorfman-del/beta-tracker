import { Router } from "express";
import { db, auditLogsTable, usersTable, clientsTable, betaFeaturesTable, betaEnrollmentsTable, feedbackTable, outreachBatchesTable } from "../lib/db";
import { ok, err } from "../lib/helpers";
import { eq, and, desc, inArray, gte, sql } from "drizzle-orm";

const router = Router();

const PAGE_LIMIT = 50;

function describeLog(log: any, clientMap: Record<string, string>, featureMap: Record<string, string>): string {
  const state = (log.nextState ?? log.priorState) as any;
  const clientName = state?.clientId ? (clientMap[state.clientId] ?? "a client") : null;
  const featureName = state?.featureId
    ? (featureMap[state.featureId] ?? null)
    : (state?.name ?? null);
  const statusLabel = (state?.testerStatus ?? "").replace(/_/g, " ");

  switch (log.action) {
    case "nominated":           return `Added ${clientName ?? "a client"}${featureName ? ` to ${featureName}` : ""}`;
    case "removed":             return `Removed ${clientName ?? "a client"}${featureName ? ` from ${featureName}` : ""}`;
    case "status_change":       return `Changed ${clientName ?? "a client"}'s status${featureName ? ` in ${featureName}` : ""} to ${statusLabel}`;
    case "csm_approved":        return `Approved ${clientName ?? "a client"}${featureName ? ` for ${featureName}` : ""}`;
    case "csm_approval_revoked":return `Revoked approval for ${clientName ?? "a client"}${featureName ? ` in ${featureName}` : ""}`;
    case "csm_rejected":        return `Rejected ${clientName ?? "a client"}${featureName ? ` from ${featureName}` : ""}`;
    case "feedback_logged":     return `Logged feedback for ${clientName ?? "a client"}${featureName ? ` on ${featureName}` : ""}`;
    case "feedback_edited":     return `Edited feedback for ${clientName ?? "a client"}${featureName ? ` on ${featureName}` : ""}`;
    case "feedback_deleted":    return `Deleted feedback for ${clientName ?? "a client"}${featureName ? ` on ${featureName}` : ""}`;
    case "outreach_sent":       return `Sent outreach to ${clientName ?? "a client"}`;
    case "created":             return `Created beta${featureName ? `: ${featureName}` : ""}`;
    case "updated":             return `Updated beta${featureName ? `: ${featureName}` : ""}`;
    case "deleted":             return `Deleted beta${featureName ? `: ${featureName}` : ""}`;
    case "closed":              return `Closed beta${featureName ? `: ${featureName}` : ""}`;
    case "cloned":              return `Cloned beta${featureName ? `: ${featureName}` : ""}`;
    default:                    return log.action.replace(/_/g, " ").replace(/^\w/, (c: string) => c.toUpperCase());
  }
}

function categoryForAction(action: string): string {
  switch (action) {
    case "nominated":                           return "enrollment";
    case "removed":                             return "removal";
    case "csm_approved":                        return "approval";
    case "csm_approval_revoked":
    case "csm_rejected":                        return "removal";
    case "feedback_logged":
    case "feedback_edited":                     return "feedback";
    case "feedback_deleted":                    return "removal";
    case "outreach_sent":                       return "outreach";
    case "status_change":                       return "status";
    case "deleted":                             return "removal";
    default:                                    return "feature";
  }
}

// GET /api/audit-logs
router.get("/", async (req, res) => {
  try {
    const { user_id, action, feature_id, days, limit, offset } = req.query as Record<string, string>;
    const take = Math.min(Number(limit) || PAGE_LIMIT, 200);
    const skip = Number(offset) || 0;

    const conditions: any[] = [];

    if (user_id) conditions.push(eq(auditLogsTable.changedById, user_id));
    if (action)  conditions.push(eq(auditLogsTable.action, action));
    if (days)    conditions.push(gte(auditLogsTable.createdAt, new Date(Date.now() - Number(days) * 86400000)));
    if (feature_id) {
      conditions.push(sql`(
        (${auditLogsTable.entityType} = 'BetaFeature' AND ${auditLogsTable.entityId} = ${feature_id})
        OR (${auditLogsTable.nextState}->>'featureId' = ${feature_id})
        OR (${auditLogsTable.priorState}->>'featureId' = ${feature_id})
      )`);
    }

    const where = conditions.length ? and(...conditions) : undefined;

    const [logs, [{ value: total }]] = await Promise.all([
      db.select().from(auditLogsTable)
        .where(where)
        .orderBy(desc(auditLogsTable.createdAt))
        .offset(skip)
        .limit(take),
      db.select({ value: sql<number>`COUNT(*)` }).from(auditLogsTable).where(where),
    ]);

    if (logs.length === 0) return ok(res, { logs: [], total: Number(total), skip, take });

    const userIds = [...new Set(logs.map(l => l.changedById))];
    const users = await db.select({ id: usersTable.id, name: usersTable.name })
      .from(usersTable).where(inArray(usersTable.id, userIds));
    const userMap = Object.fromEntries(users.map(u => [u.id, u.name]));

    const clientIdSet = new Set<string>();
    const featureIdSet = new Set<string>();
    for (const log of logs) {
      const state = (log.nextState ?? log.priorState) as any;
      if (state?.clientId) clientIdSet.add(state.clientId);
      if (state?.featureId) featureIdSet.add(state.featureId);
      // BetaFeature logs have entity = the feature itself
      if (log.entityType === "BetaFeature" && state?.name) featureIdSet.add(log.entityId);
    }

    const [clientRows, featureRows] = await Promise.all([
      clientIdSet.size > 0
        ? db.select({ id: clientsTable.id, name: clientsTable.name }).from(clientsTable).where(inArray(clientsTable.id, [...clientIdSet]))
        : Promise.resolve([]),
      featureIdSet.size > 0
        ? db.select({ id: betaFeaturesTable.id, name: betaFeaturesTable.name }).from(betaFeaturesTable).where(inArray(betaFeaturesTable.id, [...featureIdSet]))
        : Promise.resolve([]),
    ]);
    const clientMap = Object.fromEntries(clientRows.map(c => [c.id, c.name]));
    const featureMap = Object.fromEntries(featureRows.map(f => [f.id, f.name]));

    // For BetaFeature logs, also capture name from priorState (deleted features won't be in DB)
    for (const log of logs) {
      if (log.entityType === "BetaFeature" && !featureMap[log.entityId]) {
        const state = (log.nextState ?? log.priorState) as any;
        if (state?.name) featureMap[log.entityId] = state.name;
      }
    }

    const result = logs.map(log => ({
      id: log.id,
      action: log.action,
      category: categoryForAction(log.action),
      description: describeLog(log, clientMap, featureMap),
      actorId: log.changedById,
      actorName: userMap[log.changedById] ?? null,
      entityType: log.entityType,
      entityId: log.entityId,
      createdAt: log.createdAt,
    }));

    return ok(res, { logs: result, total: Number(total), skip, take });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// GET /api/audit-logs/actions — distinct action values for filter dropdown
router.get("/actions", async (_req, res) => {
  try {
    const rows = await db.selectDistinct({ action: auditLogsTable.action })
      .from(auditLogsTable)
      .orderBy(auditLogsTable.action);
    return ok(res, { actions: rows.map(r => r.action) });
  } catch (e) {
    return err(res, "Internal error", 500);
  }
});

export default router;
