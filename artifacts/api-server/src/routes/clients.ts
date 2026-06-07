import { Router } from "express";
import { db, clientsTable, usersTable, betaEnrollmentsTable, betaFeaturesTable, auditLogsTable } from "../lib/db";
import { ok, err, parsePagination } from "../lib/helpers";
import { eq, and, asc, desc, count, inArray, ilike, isNotNull, sql } from "drizzle-orm";
import { getRequestUser } from "../lib/currentUser";

const router = Router();

const VALID_SEGMENTS = ["Strategic", "Enterprise", "Commercial", "Professional", "Channel"] as const;
const VALID_HEALTH   = ["green", "yellow", "red"] as const;

function validateClientBody(body: any, requireAll = true) {
  const { name, crmId, csmOwnerId, aeOwnerId, segment, primaryContactName, primaryContactEmail,
    accountHealth, vertical, contractRenewalDate, productSubscriptions, lastOutreachDate, tier } = body ?? {};
  if (requireAll) {
    if (!name?.trim())               return { error: "Client Name is required." };
    if (!crmId?.trim())              return { error: "Client ID is required." };
    if (!csmOwnerId?.trim())         return { error: "CSM Owner is required." };
    if (!segment || !VALID_SEGMENTS.includes(segment)) return { error: `Segment must be one of: ${VALID_SEGMENTS.join(", ")}.` };
  }
  if (accountHealth && !VALID_HEALTH.includes(accountHealth)) return { error: "Invalid account health value." };
  return {
    data: {
      name: name?.trim(),
      crmId: crmId?.trim() || null,
      csmOwnerId: csmOwnerId?.trim(),
      aeOwnerId: aeOwnerId?.trim() || null,
      segment: segment || null,
      primaryContactName: primaryContactName?.trim() || null,
      primaryContactEmail: primaryContactEmail?.trim()?.toLowerCase() || null,
      accountHealth: accountHealth || "green",
      vertical: vertical?.trim() || null,
      contractRenewalDate: contractRenewalDate || null,
      productSubscriptions: productSubscriptions?.trim() || null,
      lastOutreachDate: lastOutreachDate || null,
      tier: tier ? parseInt(tier, 10) : null,
    }
  };
}

// GET /api/clients/verticals — distinct non-null vertical values (must be before /:id)
router.get("/verticals", async (_req, res) => {
  try {
    const rows = await db.selectDistinct({ vertical: clientsTable.vertical })
      .from(clientsTable)
      .where(isNotNull(clientsTable.vertical))
      .orderBy(asc(clientsTable.vertical));
    return ok(res, { verticals: rows.map(r => r.vertical as string) });
  } catch (e) {
    return err(res, "Internal error", 500);
  }
});

// GET /api/clients
router.get("/", async (req, res) => {
  try {
    const { skip, take } = parsePagination(req.query as Record<string, string>);
    const { health, csm, ae, segment, vertical, search, sort, dir } = req.query as Record<string, string>;

    const splitParam = (v: string | undefined) => v ? v.split(",").map(s => s.trim()).filter(Boolean) : [];
    const healthVals = splitParam(health);
    const segmentVals = splitParam(segment);
    const verticalVals = splitParam(vertical);

    const conditions = [];
    if (healthVals.length === 1) conditions.push(eq(clientsTable.accountHealth, healthVals[0] as any));
    if (healthVals.length > 1)  conditions.push(inArray(clientsTable.accountHealth, healthVals as any));
    if (csm)                    conditions.push(eq(clientsTable.csmOwnerId, csm));
    if (ae)                     conditions.push(eq(clientsTable.aeOwnerId, ae));
    if (segmentVals.length === 1) conditions.push(eq(clientsTable.segment, segmentVals[0] as any));
    if (segmentVals.length > 1)  conditions.push(inArray(clientsTable.segment, segmentVals as any));
    if (verticalVals.length === 1) conditions.push(eq(clientsTable.vertical, verticalVals[0]));
    if (verticalVals.length > 1)  conditions.push(inArray(clientsTable.vertical, verticalVals));
    if (search)                 conditions.push(ilike(clientsTable.name, `%${search}%`));

    const isDesc = dir === "desc";
    const orderExpr = (() => {
      switch (sort) {
        case "segment":  return isDesc ? desc(clientsTable.segment)  : asc(clientsTable.segment);
        case "health":   return isDesc
          ? desc(sql`CASE account_health WHEN 'green' THEN 1 WHEN 'yellow' THEN 2 WHEN 'red' THEN 3 END`)
          : asc(sql`CASE account_health WHEN 'green' THEN 1 WHEN 'yellow' THEN 2 WHEN 'red' THEN 3 END`);
        case "vertical": return isDesc ? desc(clientsTable.vertical) : asc(clientsTable.vertical);
        case "csm":      return isDesc ? desc(clientsTable.csmOwnerId) : asc(clientsTable.csmOwnerId);
        case "betas":    return isDesc
          ? desc(sql`(SELECT COUNT(*) FROM beta_enrollments e WHERE e.client_id = "clients".id)`)
          : asc(sql`(SELECT COUNT(*) FROM beta_enrollments e WHERE e.client_id = "clients".id)`);
        default:         return isDesc ? desc(clientsTable.name)     : asc(clientsTable.name);
      }
    })();

    const clients = await db.select({
      id: clientsTable.id,
      name: clientsTable.name,
      crmId: clientsTable.crmId,
      csmOwnerId: clientsTable.csmOwnerId,
      aeOwnerId: clientsTable.aeOwnerId,
      tier: clientsTable.tier,
      segment: clientsTable.segment,
      primaryContactName: clientsTable.primaryContactName,
      primaryContactEmail: clientsTable.primaryContactEmail,
      accountHealth: clientsTable.accountHealth,
      vertical: clientsTable.vertical,
      contractRenewalDate: clientsTable.contractRenewalDate,
      productSubscriptions: clientsTable.productSubscriptions,
      outreachLock: clientsTable.outreachLock,
      betaEligibleOverride: clientsTable.betaEligibleOverride,
      lastOutreachDate: clientsTable.lastOutreachDate,
      notes: clientsTable.notes,
      createdAt: clientsTable.createdAt,
      betaCount: sql<number>`(SELECT COUNT(*) FROM beta_enrollments e WHERE e.client_id = "clients".id)`,
    }).from(clientsTable)
      .where(conditions.length ? and(...conditions) : undefined)
      .orderBy(orderExpr)
      .offset(skip).limit(take);

    const [{ value: total }] = await db.select({ value: count() }).from(clientsTable)
      .where(conditions.length ? and(...conditions) : undefined);

    const allOwnerIds = [...new Set([
      ...clients.map(c => c.csmOwnerId),
      ...clients.map(c => c.aeOwnerId).filter(Boolean) as string[],
    ])];
    const owners = allOwnerIds.length > 0
      ? await db.select({ id: usersTable.id, name: usersTable.name, email: usersTable.email })
          .from(usersTable).where(inArray(usersTable.id, allOwnerIds))
      : [];
    const ownerMap = Object.fromEntries(owners.map(u => [u.id, u]));

    const enriched = clients.map(c => ({
      ...c,
      csmOwner: ownerMap[c.csmOwnerId] ?? null,
      aeOwner: c.aeOwnerId ? (ownerMap[c.aeOwnerId] ?? null) : null,
    }));
    return ok(res, { clients: enriched, total, skip, take });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// POST /api/clients
router.post("/", async (req, res) => {
  const validated = validateClientBody(req.body, true);
  if ("error" in validated) return err(res, validated.error, 400);
  try {
    const [client] = await db.insert(clientsTable).values(validated.data as any).returning();
    return ok(res, { client }, 201);
  } catch (e: any) {
    const pgCode = e?.cause?.code ?? e?.code;
    if (pgCode === "23505") return err(res, "A client with that ID already exists.", 409);
    if (pgCode === "23503") return err(res, "CSM owner not found.", 400);
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// POST /api/clients/bulk — must be before /:id
router.post("/bulk", async (req, res) => {
  const rows: any[] = req.body?.rows ?? [];
  if (!Array.isArray(rows) || rows.length === 0) return err(res, "rows array is required.", 400);

  // Resolve CSM emails to IDs upfront
  const allCsmEmails = [...new Set(rows.map(r => r.csmEmail?.trim()?.toLowerCase()).filter(Boolean))];
  const csmUsers = allCsmEmails.length > 0
    ? await db.select({ id: usersTable.id, email: usersTable.email })
        .from(usersTable)
        .where(inArray(usersTable.email, allCsmEmails))
    : [];
  const csmByEmail = Object.fromEntries(csmUsers.map(u => [u.email, u.id]));

  const results: { row: number; success: boolean; error?: string; client?: any }[] = [];
  for (let i = 0; i < rows.length; i++) {
    const raw = rows[i];
    // Resolve CSM
    const csmEmail = raw.csmEmail?.trim()?.toLowerCase();
    const csmOwnerId = csmEmail ? csmByEmail[csmEmail] : undefined;
    if (!csmOwnerId) {
      results.push({ row: i + 1, success: false, error: `CSM email "${raw.csmEmail}" not found.` });
      continue;
    }
    const validated = validateClientBody({ ...raw, csmOwnerId }, true);
    if ("error" in validated) {
      results.push({ row: i + 1, success: false, error: validated.error });
      continue;
    }
    try {
      const [client] = await db.insert(clientsTable).values(validated.data as any).returning();
      results.push({ row: i + 1, success: true, client });
    } catch (e: any) {
      req.log.error({ row: i + 1, err: e }, "bulk import row failed");
      const pgCode = e?.cause?.code ?? e?.code;
      const error = pgCode === "23505"
        ? `Client ID "${raw.crmId}" already exists.`
        : pgCode === "23503" ? "CSM not found."
        : e?.cause?.message ?? e?.message ?? "Database error.";
      results.push({ row: i + 1, success: false, error });
    }
  }

  const succeeded = results.filter(r => r.success).length;
  return ok(res, { results, succeeded, failed: results.length - succeeded });
});

// GET /api/clients/:id
router.get("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [client] = await db.select().from(clientsTable).where(eq(clientsTable.id, id));
    if (!client) return err(res, "Client not found.", 404);

    const [csmOwner] = await db.select({ id: usersTable.id, name: usersTable.name, email: usersTable.email })
      .from(usersTable).where(eq(usersTable.id, client.csmOwnerId));

    const aeOwner = client.aeOwnerId
      ? (await db.select({ id: usersTable.id, name: usersTable.name, email: usersTable.email })
          .from(usersTable).where(eq(usersTable.id, client.aeOwnerId)))[0] ?? null
      : null;

    const enrollments = await db.select().from(betaEnrollmentsTable)
      .where(eq(betaEnrollmentsTable.clientId, id))
      .orderBy(desc(betaEnrollmentsTable.createdAt));

    const featureIds = [...new Set(enrollments.map(e => e.featureId))];
    const features = featureIds.length > 0 ? await db.select({
      id: betaFeaturesTable.id, name: betaFeaturesTable.name, status: betaFeaturesTable.status, slug: betaFeaturesTable.slug
    }).from(betaFeaturesTable).where(inArray(betaFeaturesTable.id, featureIds)) : [];
    const featureMap = Object.fromEntries(features.map(f => [f.id, f]));
    const enrichedEnrollments = enrollments.map(e => ({ ...e, feature: featureMap[e.featureId] ?? null }));

    return ok(res, { ...client, csmOwner, aeOwner, enrollments: enrichedEnrollments });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// PUT /api/clients/:id
router.put("/:id", async (req, res) => {
  const validated = validateClientBody(req.body, false);
  if ("error" in validated) return err(res, validated.error, 400);
  try {
    const requestUser = await getRequestUser(req);

    if (req.body.betaEligibleOverride !== undefined && requestUser.role !== "admin") {
      return err(res, "Only admins can update beta eligibility override.", 403);
    }

    const [existing] = await db.select().from(clientsTable).where(eq(clientsTable.id, req.params.id));
    if (!existing) return err(res, "Client not found.", 404);

    const update: any = { updatedAt: new Date() };
    const d = validated.data as any;
    const fields = ["name","crmId","csmOwnerId","aeOwnerId","segment","primaryContactName","primaryContactEmail",
      "accountHealth","vertical","contractRenewalDate","productSubscriptions","lastOutreachDate","tier"];
    for (const f of fields) { if (req.body[f] !== undefined) update[f] = d[f]; }

    const betaEligibleOverride = req.body.betaEligibleOverride;
    if (betaEligibleOverride !== undefined) update.betaEligibleOverride = !!betaEligibleOverride;

    const [client] = await db.update(clientsTable).set(update).where(eq(clientsTable.id, req.params.id)).returning();
    if (!client) return err(res, "Client not found.", 404);

    if (betaEligibleOverride !== undefined && !!betaEligibleOverride !== existing.betaEligibleOverride) {
      await db.insert(auditLogsTable).values({
        entityType: "Client",
        entityId: client.id,
        action: "beta_eligibility_override",
        changedById: requestUser.id,
        priorState: { betaEligibleOverride: existing.betaEligibleOverride, clientName: existing.name } as any,
        nextState: { betaEligibleOverride: client.betaEligibleOverride, clientName: client.name } as any,
      });
    }

    return ok(res, { client });
  } catch (e: any) {
    const pgCode = e?.cause?.code ?? e?.code;
    if (pgCode === "23503") return err(res, "CSM owner not found.", 400);
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// DELETE /api/clients/:id
router.delete("/:id", async (req, res) => {
  try {
    const [client] = await db.delete(clientsTable).where(eq(clientsTable.id, req.params.id)).returning();
    if (!client) return err(res, "Client not found.", 404);
    return ok(res, { client });
  } catch (e: any) {
    const pgCode = e?.cause?.code ?? e?.code;
    if (pgCode === "23503") return err(res, "Cannot delete: client has existing beta enrollments.", 409);
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// GET /api/clients/:id/betas
router.get("/:id/betas", async (req, res) => {
  try {
    const { id } = req.params;
    const { skip, take } = parsePagination(req.query as Record<string, string>);
    const [exists] = await db.select({ id: clientsTable.id }).from(clientsTable).where(eq(clientsTable.id, id));
    if (!exists) return err(res, "Client not found.", 404);
    const enrollments = await db.select().from(betaEnrollmentsTable)
      .where(eq(betaEnrollmentsTable.clientId, id))
      .orderBy(desc(betaEnrollmentsTable.createdAt))
      .offset(skip).limit(take);
    const [{ value: total }] = await db.select({ value: count() }).from(betaEnrollmentsTable)
      .where(eq(betaEnrollmentsTable.clientId, id));
    const featureIds = [...new Set(enrollments.map(e => e.featureId))];
    const features = featureIds.length > 0 ? await db.select({
      id: betaFeaturesTable.id, name: betaFeaturesTable.name, status: betaFeaturesTable.status, startDate: betaFeaturesTable.startDate, slug: betaFeaturesTable.slug
    }).from(betaFeaturesTable).where(inArray(betaFeaturesTable.id, featureIds)) : [];
    const featureMap = Object.fromEntries(features.map(f => [f.id, f]));
    const enriched = enrollments.map(e => ({ ...e, feature: featureMap[e.featureId] ?? null }));
    return ok(res, { enrollments: enriched, total, skip, take });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

export default router;
