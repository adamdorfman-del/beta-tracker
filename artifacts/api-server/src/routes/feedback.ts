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
      id:          feedbackTable.id,
      sentiment:   feedbackTable.sentiment,
      notes:       feedbackTable.notes,
      createdAt:   feedbackTable.createdAt,
      clientId:    feedbackTable.clientId,
      clientName:  clientsTable.name,
      featureId:   feedbackTable.featureId,
      featureName: betaFeaturesTable.name,
      featureSlug: betaFeaturesTable.slug,
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

    const { clientId, featureId, sentiment, notes } = req.body;
    if (!clientId || !featureId || !sentiment) {
      return err(res, "clientId, featureId, and sentiment are required.");
    }
    if (!["positive", "neutral", "negative"].includes(sentiment)) {
      return err(res, "sentiment must be positive, neutral, or negative.");
    }

    const [entry] = await db.insert(feedbackTable).values({
      id: crypto.randomUUID(),
      clientId,
      featureId,
      sentiment,
      notes: notes ?? null,
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

export default router;
