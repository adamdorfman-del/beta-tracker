import { Router } from "express";
import { getAuth, clerkClient } from "@clerk/express";
import { db, feedbackTable, clientsTable, betaFeaturesTable, usersTable, auditLogsTable } from "../lib/db";
import { ok, err, parsePagination } from "../lib/helpers";
import { eq, and, gte, desc, sql, inArray } from "drizzle-orm";

const router = Router();

async function getCurrentDbUser(req: any) {
  const { userId } = getAuth(req);
  if (!userId) return null;
  const clerkUser = await clerkClient.users.getUser(userId);
  const email = clerkUser.emailAddresses.find((e: any) => e.id === clerkUser.primaryEmailAddressId)?.emailAddress;
  if (!email) return null;
  const [user] = await db.select({ id: usersTable.id, name: usersTable.name, role: usersTable.role })
    .from(usersTable).where(eq(usersTable.email, email.toLowerCase()));
  return user ?? null;
}

async function buildConditions(query: Record<string, string>) {
  const { feature_id, client_id, segment, sentiment, days } = query;
  const conditions: any[] = [];

  if (client_id) {
    const ids = client_id.split(",").filter(Boolean);
    if (ids.length === 1) conditions.push(eq(feedbackTable.clientId, ids[0]));
    else if (ids.length > 1) conditions.push(inArray(feedbackTable.clientId, ids));
  }

  if (feature_id) {
    const ids = feature_id.split(",").filter(Boolean);
    if (ids.length === 1) conditions.push(eq(feedbackTable.featureId, ids[0]));
    else if (ids.length > 1) conditions.push(inArray(feedbackTable.featureId, ids));
  }

  if (sentiment) {
    const vals = sentiment.split(",").filter((s) => ["positive", "neutral", "negative"].includes(s));
    if (vals.length === 1) conditions.push(eq(feedbackTable.sentiment, vals[0] as any));
    else if (vals.length > 1) conditions.push(inArray(feedbackTable.sentiment, vals as any));
  }

  if (days) {
    const cutoff = new Date(Date.now() - Number(days) * 86400000);
    conditions.push(gte(feedbackTable.createdAt, cutoff));
  }

  if (segment) {
    const segs = segment.split(",").filter(Boolean);
    const matchingClients = await db
      .select({ id: clientsTable.id })
      .from(clientsTable)
      .where(segs.length === 1
        ? eq(clientsTable.segment, segs[0] as any)
        : inArray(clientsTable.segment, segs as any));
    const clientIds = matchingClients.map((c) => c.id);
    if (clientIds.length === 0) conditions.push(sql`1 = 0`);
    else conditions.push(inArray(feedbackTable.clientId, clientIds));
  }

  return conditions;
}

// GET /api/feedback/summary
router.get("/summary", async (req, res) => {
  try {
    const q = req.query as Record<string, string>;
    const conditions = await buildConditions(q);
    const where = conditions.length ? and(...conditions) : undefined;

    const [totals] = await db.select({
      total:    sql<number>`COUNT(*)`,
      positive: sql<number>`SUM(CASE WHEN ${feedbackTable.sentiment} = 'positive' THEN 1 ELSE 0 END)`,
      neutral:  sql<number>`SUM(CASE WHEN ${feedbackTable.sentiment} = 'neutral'  THEN 1 ELSE 0 END)`,
      negative: sql<number>`SUM(CASE WHEN ${feedbackTable.sentiment} = 'negative' THEN 1 ELSE 0 END)`,
      gating:   sql<number>`SUM(CASE WHEN ${feedbackTable.isGatingRequest} = true THEN 1 ELSE 0 END)`,
    }).from(feedbackTable).where(where);

    const byFeatureRows = await db.select({
      featureId:   feedbackTable.featureId,
      featureName: betaFeaturesTable.name,
      featureSlug: betaFeaturesTable.slug,
      total:    sql<number>`COUNT(*)`,
      positive: sql<number>`SUM(CASE WHEN ${feedbackTable.sentiment} = 'positive' THEN 1 ELSE 0 END)`,
      neutral:  sql<number>`SUM(CASE WHEN ${feedbackTable.sentiment} = 'neutral'  THEN 1 ELSE 0 END)`,
      negative: sql<number>`SUM(CASE WHEN ${feedbackTable.sentiment} = 'negative' THEN 1 ELSE 0 END)`,
    })
      .from(feedbackTable)
      .innerJoin(betaFeaturesTable, eq(feedbackTable.featureId, betaFeaturesTable.id))
      .where(where)
      .groupBy(feedbackTable.featureId, betaFeaturesTable.name, betaFeaturesTable.slug);

    return ok(res, {
      totals: {
        total:    Number(totals?.total ?? 0),
        positive: Number(totals?.positive ?? 0),
        neutral:  Number(totals?.neutral ?? 0),
        negative: Number(totals?.negative ?? 0),
        gating:   Number(totals?.gating ?? 0),
      },
      byFeature: byFeatureRows.map((r) => ({
        ...r,
        total:    Number(r.total),
        positive: Number(r.positive),
        neutral:  Number(r.neutral),
        negative: Number(r.negative),
      })),
    });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// GET /api/feedback
router.get("/", async (req, res) => {
  try {
    const q = req.query as Record<string, string>;
    const { skip, take } = parsePagination(q);
    const conditions = await buildConditions(q);
    const where = conditions.length ? and(...conditions) : undefined;

    const rows = await db.select({
      id:               feedbackTable.id,
      sentiment:        feedbackTable.sentiment,
      notes:            feedbackTable.notes,
      isGatingRequest:   feedbackTable.isGatingRequest,
      gatingDescription: feedbackTable.gatingDescription,
      jiraTicketUrl:     feedbackTable.jiraTicketUrl,
      createdAt:         feedbackTable.createdAt,
      clientId:         feedbackTable.clientId,
      clientName:       clientsTable.name,
      featureId:        feedbackTable.featureId,
      featureName:      betaFeaturesTable.name,
      featureSlug:      betaFeaturesTable.slug,
      feedbackProviderId:   feedbackTable.feedbackProviderId,
      feedbackProviderName: usersTable.name,
    })
      .from(feedbackTable)
      .innerJoin(clientsTable, eq(feedbackTable.clientId, clientsTable.id))
      .innerJoin(betaFeaturesTable, eq(feedbackTable.featureId, betaFeaturesTable.id))
      .innerJoin(usersTable, eq(feedbackTable.feedbackProviderId, usersTable.id))
      .where(where)
      .orderBy(desc(feedbackTable.createdAt))
      .offset(skip).limit(take);

    const [{ value: total }] = await db.select({ value: sql<number>`COUNT(*)` })
      .from(feedbackTable)
      .innerJoin(clientsTable, eq(feedbackTable.clientId, clientsTable.id))
      .where(where);

    return ok(res, { feedback: rows, total: Number(total), skip, take });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// POST /api/feedback
router.post("/", async (req, res) => {
  try {
    const currentUser = await getCurrentDbUser(req);
    if (!currentUser) return err(res, "Unauthorized", 401);
    if (!["csm", "pm", "admin"].includes(currentUser.role)) {
      return err(res, "Forbidden", 403);
    }

    const { clientId, featureId, sentiment, notes, isGatingRequest, gatingDescription, jiraTicketUrl } = req.body;
    if (!clientId || !featureId || !sentiment) {
      return err(res, "clientId, featureId, and sentiment are required.");
    }
    if (!["positive", "neutral", "negative"].includes(sentiment)) {
      return err(res, "sentiment must be positive, neutral, or negative.");
    }
    if (isGatingRequest && !gatingDescription?.trim()) {
      return err(res, "gatingDescription is required when isGatingRequest is true.");
    }
    if (jiraTicketUrl && !String(jiraTicketUrl).startsWith("https://")) {
      return err(res, "jiraTicketUrl must start with https://");
    }

    const [entry] = await db.insert(feedbackTable).values({
      id: crypto.randomUUID(),
      clientId,
      featureId,
      sentiment,
      notes: notes ?? null,
      isGatingRequest: isGatingRequest === true,
      gatingDescription: isGatingRequest ? (gatingDescription?.trim() || null) : null,
      jiraTicketUrl: jiraTicketUrl || null,
      feedbackProviderId: currentUser.id,
    }).returning();

    await db.insert(auditLogsTable).values({
      entityType: "Feedback",
      entityId: entry.id,
      action: "feedback_logged",
      changedById: currentUser.id,
      nextState: entry as any,
    });

    return ok(res, entry, 201);
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// PUT /api/feedback/:id
router.put("/:id", async (req, res) => {
  try {
    const currentUser = await getCurrentDbUser(req);
    if (!currentUser) return err(res, "Unauthorized", 401);

    const [entry] = await db.select().from(feedbackTable).where(eq(feedbackTable.id, req.params.id));
    if (!entry) return err(res, "Not found.", 404);

    const canEdit = currentUser.role === "admin" || currentUser.role === "pm" || entry.feedbackProviderId === currentUser.id;
    if (!canEdit) return err(res, "Forbidden", 403);

    const { sentiment, notes, feedbackProviderId, isGatingRequest, gatingDescription, jiraTicketUrl } = req.body;
    if (sentiment && !["positive", "neutral", "negative"].includes(sentiment)) {
      return err(res, "sentiment must be positive, neutral, or negative.");
    }
    if (jiraTicketUrl && !String(jiraTicketUrl).startsWith("https://")) {
      return err(res, "jiraTicketUrl must start with https://");
    }

    const update: Record<string, unknown> = {};
    if (sentiment !== undefined)           update.sentiment           = sentiment;
    if (notes !== undefined)               update.notes               = notes ?? null;
    if (feedbackProviderId !== undefined)  update.feedbackProviderId  = feedbackProviderId;
    if (isGatingRequest !== undefined)     update.isGatingRequest     = isGatingRequest === true;
    if (gatingDescription !== undefined)   update.gatingDescription   = isGatingRequest ? (gatingDescription?.trim() || null) : null;
    if (jiraTicketUrl !== undefined)       update.jiraTicketUrl       = jiraTicketUrl || null;

    const [updated] = await db.update(feedbackTable).set(update as any).where(eq(feedbackTable.id, req.params.id)).returning();
    await db.insert(auditLogsTable).values({
      entityType: "Feedback", entityId: entry.id, action: "feedback_edited",
      changedById: currentUser.id, priorState: entry as any, nextState: updated as any,
    });
    return ok(res, updated);
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// DELETE /api/feedback/:id
router.delete("/:id", async (req, res) => {
  try {
    const currentUser = await getCurrentDbUser(req);
    if (!currentUser) return err(res, "Unauthorized", 401);

    const [entry] = await db.select().from(feedbackTable).where(eq(feedbackTable.id, req.params.id));
    if (!entry) return err(res, "Not found.", 404);

    const canDelete = currentUser.role === "admin" || currentUser.role === "pm" || entry.feedbackProviderId === currentUser.id;
    if (!canDelete) return err(res, "Forbidden", 403);

    await db.delete(feedbackTable).where(eq(feedbackTable.id, req.params.id));
    await db.insert(auditLogsTable).values({
      entityType: "Feedback", entityId: entry.id, action: "feedback_deleted",
      changedById: currentUser.id, priorState: entry as any,
    });
    return res.status(204).end();
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

export default router;
