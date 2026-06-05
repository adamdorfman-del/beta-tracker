import { Router } from "express";
import { db, betaFeaturesTable, usersTable, betaEnrollmentsTable, auditLogsTable, feedbackTable, clientsTable, outreachBatchesTable, outreachBatchEnrollmentsTable } from "../lib/db";
import { ok, err, parsePagination } from "../lib/helpers";
import { eq, and, or, asc, desc, count, inArray, notExists, sql } from "drizzle-orm";
import { logger } from "../lib/logger";
import { requireRole } from "../middlewares/requireRole";
import { generateUniqueSlug } from "../lib/slugify";
import { getRequestUser } from "../lib/currentUser";

async function findFeature(slugOrId: string) {
  let [feature] = await db.select().from(betaFeaturesTable).where(eq(betaFeaturesTable.slug, slugOrId));
  if (!feature) [feature] = await db.select().from(betaFeaturesTable).where(eq(betaFeaturesTable.id, slugOrId));
  if (!feature) [feature] = await db.select().from(betaFeaturesTable).where(eq(betaFeaturesTable.previousSlug, slugOrId));
  return feature ?? null;
}

const router = Router();
const pmOrAdmin = requireRole("pm", "admin");

// ── Shared enrollment funnel ─────────────────────────────────────────────────
// Single source of truth used by both list and detail endpoints so they can
// never diverge. All four counts use the same active-enrollment definition:
//   active = tester_status NOT IN ('dropped','cancelled')
//             AND csm_approval_status != 'rejected'
const FUNNEL_SELECT = {
  nominated: sql<number>`COUNT(*) FILTER (WHERE ${betaEnrollmentsTable.testerStatus} IN ('nominated','csm_pending'))`,
  approved:  sql<number>`COUNT(*) FILTER (WHERE ${betaEnrollmentsTable.testerStatus} IN ('csm_approved','outreach_sent','confirmed','active'))`,
  enrolled:  sql<number>`COUNT(*) FILTER (WHERE ${betaEnrollmentsTable.testerStatus} = 'enrolled')`,
  using:     sql<number>`COUNT(*) FILTER (WHERE ${betaEnrollmentsTable.testerStatus} = 'using')`,
  accepted:  sql<number>`COUNT(*) FILTER (WHERE ${betaEnrollmentsTable.testerStatus} = 'accepted')`,
  total:     sql<number>`COUNT(*) FILTER (WHERE ${betaEnrollmentsTable.testerStatus} NOT IN ('dropped','cancelled') AND ${betaEnrollmentsTable.csmApprovalStatus} != 'rejected')`,
};

function parseFunnel(row: any) {
  return {
    nominated: Number(row?.nominated ?? 0),
    approved:  Number(row?.approved  ?? 0),
    enrolled:  Number(row?.enrolled  ?? 0),
    using:     Number(row?.using     ?? 0),
    accepted:  Number(row?.accepted  ?? 0),
    total:     Number(row?.total     ?? 0),
  };
}

async function getEnrollmentFunnel(featureId: string) {
  const [row] = await db.select(FUNNEL_SELECT)
    .from(betaEnrollmentsTable)
    .where(eq(betaEnrollmentsTable.featureId, featureId));
  return parseFunnel(row);
}

async function getEnrollmentFunnels(featureIds: string[]) {
  if (featureIds.length === 0) return {} as Record<string, ReturnType<typeof parseFunnel>>;
  const rows = await db.select({ featureId: betaEnrollmentsTable.featureId, ...FUNNEL_SELECT })
    .from(betaEnrollmentsTable)
    .where(inArray(betaEnrollmentsTable.featureId, featureIds))
    .groupBy(betaEnrollmentsTable.featureId);
  return Object.fromEntries(rows.map(r => [r.featureId, parseFunnel(r)]));
}

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
          ? desc(sql`CASE status WHEN 'draft' THEN 1 WHEN 'in_progress' THEN 2 WHEN 'complete' THEN 3 ELSE 4 END`)
          : asc(sql`CASE status WHEN 'draft' THEN 1 WHEN 'in_progress' THEN 2 WHEN 'complete' THEN 3 ELSE 4 END`);
        case "enrollment": return isDesc ? desc(betaFeaturesTable.targetTesterCount) : asc(betaFeaturesTable.targetTesterCount);
        case "pm":      return isDesc ? desc(betaFeaturesTable.ownerPmId)  : asc(betaFeaturesTable.ownerPmId);
        case "start":   return isDesc ? desc(betaFeaturesTable.startDate)  : asc(betaFeaturesTable.startDate);
        case "end_date": return isDesc
          ? desc(sql`COALESCE(projected_end_date, '9999-12-31')`)
          : asc(sql`COALESCE(projected_end_date, '9999-12-31')`);
        default:        return desc(betaFeaturesTable.createdAt);
      }
    })();

    const features = await db.select({
      ...betaFeaturesTable,
      pendingApprovalCount: sql<number>`(SELECT COUNT(*) FROM beta_enrollments e WHERE e.feature_id = "beta_features".id AND e.csm_approval_status = 'pending')`,
      fbTotal:              sql<number>`(SELECT COUNT(*) FROM feedback fb WHERE fb.feature_id = "beta_features".id)`,
      fbPositive:           sql<number>`(SELECT COUNT(*) FROM feedback fb WHERE fb.feature_id = "beta_features".id AND fb.sentiment = 'positive')`,
      fbNegative:           sql<number>`(SELECT COUNT(*) FROM feedback fb WHERE fb.feature_id = "beta_features".id AND fb.sentiment = 'negative')`,
      fbNeutral:            sql<number>`(SELECT COUNT(*) FROM feedback fb WHERE fb.feature_id = "beta_features".id AND fb.sentiment = 'neutral')`,
    }).from(betaFeaturesTable)
      .where(conditions.length ? and(...conditions) : undefined)
      .orderBy(orderExpr)
      .offset(skip).limit(take);

    const [{ value: total }] = await db.select({ value: count() }).from(betaFeaturesTable)
      .where(conditions.length ? and(...conditions) : undefined);

    const funnelMap = await getEnrollmentFunnels(features.map(f => f.id));

    // Enrich with owner names
    const allUserIds = [...new Set(features.flatMap(f => [f.ownerPmId, f.ownerPmmId]))];
    const owners = allUserIds.length > 0 ? await db.select().from(usersTable).where(inArray(usersTable.id, allUserIds)) : [];
    const ownerMap = Object.fromEntries(owners.map(u => [u.id, u]));

    const enriched = features.map(f => {
      const fbTotal    = Number(f.fbTotal    ?? 0);
      const fbPositive = Number(f.fbPositive ?? 0);
      const fbNegative = Number(f.fbNegative ?? 0);
      const fbNeutral  = Number(f.fbNeutral  ?? 0);
      return {
        ...f,
        ownerPm: ownerMap[f.ownerPmId] ?? null,
        ownerPmm: ownerMap[f.ownerPmmId] ?? null,
        feedbackSummary: {
          total: fbTotal,
          positive: fbPositive,
          negative: fbNegative,
          neutral: fbNeutral,
          positiveRate: fbTotal > 0 ? fbPositive / fbTotal : null,
        },
        enrollmentFunnel: funnelMap[f.id] ?? { nominated: 0, approved: 0, inProgress: 0, total: 0 },
      };
    });

    return ok(res, { features: enriched, total, skip, take });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// POST /api/features
router.post("/", pmOrAdmin, async (req, res) => {
  try {
    const { name, ownerPmId, ownerPmmId, startDate, outreachDeadline, idealClientCriteria, betaGoal, targetTesterCount, jiraEpicLink, projectedEndDate } = req.body;
    if (!name || !ownerPmId || !ownerPmmId || !startDate || !outreachDeadline || !jiraEpicLink) {
      return err(res, "name, ownerPmId, ownerPmmId, startDate, outreachDeadline, and jiraEpicLink are required.");
    }
    const slug = await generateUniqueSlug(name);
    const [feature] = await db.insert(betaFeaturesTable).values({
      name, ownerPmId, ownerPmmId,
      startDate,
      outreachDeadline,
      idealClientCriteria,
      betaGoal,
      jiraEpicLink,
      slug,
      targetTesterCount: targetTesterCount ?? 15,
      projectedEndDate: projectedEndDate ?? null,
    }).returning();
    const adminUser = await getRequestUser(req);
    await db.insert(auditLogsTable).values({
      entityType: "BetaFeature", entityId: feature.id, action: "created",
      changedById: adminUser.id, nextState: feature as any,
    });
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
    const clientIds = [...new Set(enrollments.map(e => e.clientId))];
    const clients = clientIds.length > 0 ? await db.select().from(clientsTable).where(inArray(clientsTable.id, clientIds)) : [];
    const clientMap = Object.fromEntries(clients.map(c => [c.id, c]));
    const assignedByIds = [...new Set(enrollments.map(e => e.assignedById))];
    const approvedByIds = [...new Set(enrollments.map(e => e.csmApprovedById).filter(Boolean) as string[])];
    const allUserIds = [...new Set([...assignedByIds, ...approvedByIds])];
    const users = allUserIds.length > 0 ? await db.select().from(usersTable).where(inArray(usersTable.id, allUserIds)) : [];
    const userMap = Object.fromEntries(users.map(u => [u.id, u]));

    const csmOwnerIds = [...new Set(clients.map(c => c.csmOwnerId))];
    const aeOwnerIds = [...new Set(clients.map(c => c.aeOwnerId).filter(Boolean) as string[])];
    const allClientOwnerIds = [...new Set([...csmOwnerIds, ...aeOwnerIds])];
    const clientOwners = allClientOwnerIds.length > 0 ? await db.select().from(usersTable).where(inArray(usersTable.id, allClientOwnerIds)) : [];
    const clientOwnerMap = Object.fromEntries(clientOwners.map(u => [u.id, u]));

    const enrichedEnrollments = enrollments.map(e => ({
      ...e,
      client: clientMap[e.clientId] ? {
        ...clientMap[e.clientId],
        csmOwner: clientOwnerMap[clientMap[e.clientId].csmOwnerId] ?? null,
        aeOwner: clientMap[e.clientId].aeOwnerId ? (clientOwnerMap[clientMap[e.clientId].aeOwnerId!] ?? null) : null,
      } : null,
      assignedBy: userMap[e.assignedById] ?? null,
      csmApprovedBy: e.csmApprovedById ? (userMap[e.csmApprovedById] ?? null) : null,
    }));

    // Feedback summary
    const [fbRow] = await db.select({
      total:    sql<number>`COUNT(*)`,
      positive: sql<number>`SUM(CASE WHEN ${feedbackTable.sentiment} = 'positive' THEN 1 ELSE 0 END)`,
      negative: sql<number>`SUM(CASE WHEN ${feedbackTable.sentiment} = 'negative' THEN 1 ELSE 0 END)`,
      neutral:  sql<number>`SUM(CASE WHEN ${feedbackTable.sentiment} = 'neutral'  THEN 1 ELSE 0 END)`,
    }).from(feedbackTable).where(eq(feedbackTable.featureId, feature.id));

    const fbTotal    = Number(fbRow?.total    ?? 0);
    const fbPositive = Number(fbRow?.positive ?? 0);
    const feedbackSummary = {
      total:        fbTotal,
      positive:     fbPositive,
      negative:     Number(fbRow?.negative ?? 0),
      neutral:      Number(fbRow?.neutral  ?? 0),
      positiveRate: fbTotal > 0 ? fbPositive / fbTotal : null,
    };

    // Recent feedback (last 5)
    const recentFeedback = await db.select({
      id:                   feedbackTable.id,
      sentiment:            feedbackTable.sentiment,
      notes:                feedbackTable.notes,
      isGatingRequest:      feedbackTable.isGatingRequest,
      gatingDescription:    feedbackTable.gatingDescription,
      jiraTicketUrl:        feedbackTable.jiraTicketUrl,
      createdAt:            feedbackTable.createdAt,
      clientName:           clientsTable.name,
      feedbackProviderName: usersTable.name,
    }).from(feedbackTable)
      .innerJoin(clientsTable, eq(feedbackTable.clientId, clientsTable.id))
      .innerJoin(usersTable, eq(feedbackTable.feedbackProviderId, usersTable.id))
      .where(eq(feedbackTable.featureId, feature.id))
      .orderBy(desc(feedbackTable.createdAt))
      .limit(5);

    const enrollmentFunnel = await getEnrollmentFunnel(feature.id);

    return ok(res, { ...feature, ownerPm, ownerPmm, enrollments: enrichedEnrollments, feedbackSummary, recentFeedback, enrollmentFunnel });
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
    if (body.status !== undefined) update.status = body.status as any;
    if (body.idealClientCriteria !== undefined) update.idealClientCriteria = body.idealClientCriteria;
    if (body.betaGoal !== undefined) update.betaGoal = body.betaGoal;
    if (body.outreachDeadline !== undefined) update.outreachDeadline = body.outreachDeadline;
    if (body.startDate !== undefined) update.startDate = body.startDate;
    if (body.projectedEndDate !== undefined) update.projectedEndDate = body.projectedEndDate || null;
    if (body.targetTesterCount !== undefined) update.targetTesterCount = body.targetTesterCount;
    if (body.jiraEpicLink !== undefined) update.jiraEpicLink = body.jiraEpicLink;
    if (body.ownerPmId !== undefined) update.ownerPmId = body.ownerPmId;
    if (body.ownerPmmId !== undefined) update.ownerPmmId = body.ownerPmmId;
    update.updatedAt = new Date();
    const [updated] = await db.update(betaFeaturesTable).set(update as any).where(eq(betaFeaturesTable.id, id)).returning();
    if (!updated) return err(res, "Feature not found.", 404);
    const adminUser = await getRequestUser(req);
    await db.insert(auditLogsTable).values({
      entityType: "BetaFeature", entityId: id, action: "updated",
      changedById: adminUser.id, priorState: existing as any, nextState: updated as any,
    });
    return ok(res, updated);
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// POST /api/features/:id/close
router.post("/:id/close", pmOrAdmin, async (req, res) => {
  try {
    const adminUser = await getRequestUser(req);
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
      .set({ status: "complete" as any, closedAt: new Date(), closeReason, closeNotes, updatedAt: new Date() })
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
    const adminUser = await getRequestUser(req);
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

// DELETE /api/features/:id
router.delete("/:id", pmOrAdmin, async (req, res) => {
  try {
    const feature = await findFeature(req.params.id);
    if (!feature) return err(res, "Feature not found.", 404);
    const id = feature.id;

    // Get enrollment IDs for this feature
    const enrollments = await db
      .select({ id: betaEnrollmentsTable.id })
      .from(betaEnrollmentsTable)
      .where(eq(betaEnrollmentsTable.featureId, id));
    const enrollmentIds = enrollments.map(e => e.id);

    // Get batch IDs that will become orphaned after we remove their enrollment links
    let orphanedBatchIds: string[] = [];
    if (enrollmentIds.length > 0) {
      const batchRows = await db
        .selectDistinct({ batchId: outreachBatchEnrollmentsTable.batchId })
        .from(outreachBatchEnrollmentsTable)
        .where(inArray(outreachBatchEnrollmentsTable.enrollmentId, enrollmentIds));
      orphanedBatchIds = batchRows.map(r => r.batchId);
    }

    // 1. feedback
    await db.delete(feedbackTable).where(eq(feedbackTable.featureId, id));

    // 2. outreach_batch_enrollments for these enrollments
    if (enrollmentIds.length > 0) {
      await db.delete(outreachBatchEnrollmentsTable)
        .where(inArray(outreachBatchEnrollmentsTable.enrollmentId, enrollmentIds));
    }

    // 3. outreach_batches that are now empty
    if (orphanedBatchIds.length > 0) {
      await db.delete(outreachBatchesTable).where(
        and(
          inArray(outreachBatchesTable.id, orphanedBatchIds),
          notExists(
            db.select({ x: outreachBatchEnrollmentsTable.batchId })
              .from(outreachBatchEnrollmentsTable)
              .where(eq(outreachBatchEnrollmentsTable.batchId, outreachBatchesTable.id))
          )
        )
      );
    }

    // 4. beta_enrollments
    await db.delete(betaEnrollmentsTable).where(eq(betaEnrollmentsTable.featureId, id));

    // 5. audit_logs for this feature
    await db.delete(auditLogsTable)
      .where(and(eq(auditLogsTable.entityType, "BetaFeature"), eq(auditLogsTable.entityId, id)));

    // 6. the feature itself
    await db.delete(betaFeaturesTable).where(eq(betaFeaturesTable.id, id));

    // Log deletion after cascade so this entry isn't swept (no FK on entityId)
    const adminUser = await getRequestUser(req);
    await db.insert(auditLogsTable).values({
      entityType: "BetaFeature", entityId: id, action: "deleted",
      changedById: adminUser.id, priorState: feature as any,
    });

    return res.status(204).end();
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

export default router;
