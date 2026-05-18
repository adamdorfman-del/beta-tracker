import { Router } from "express";
import { db, clientsTable, usersTable, betaEnrollmentsTable, betaFeaturesTable } from "../lib/db";
import { ok, err, parsePagination } from "../lib/helpers";
import { eq, and, desc, count, inArray, ilike } from "drizzle-orm";

const router = Router();

const VALID_SEGMENTS = ["Enterprise", "Commercial", "Midmarket", "Channel", "SMB"] as const;
const VALID_HEALTH   = ["green", "yellow", "red"] as const;

function validateClientBody(body: any, requireAll = true) {
  const { name, crmId, csmOwnerId, segment, primaryContactName, primaryContactEmail,
    accountHealth, vertical, contractRenewalDate, productSubscriptions, lastOutreachDate, tier } = body ?? {};
  if (requireAll) {
    if (!name?.trim())               return { error: "Client Name is required." };
    if (!crmId?.trim())              return { error: "Client ID is required." };
    if (!csmOwnerId?.trim())         return { error: "CSM Owner is required." };
    if (!segment || !VALID_SEGMENTS.includes(segment)) return { error: `Segment must be one of: ${VALID_SEGMENTS.join(", ")}.` };
    if (!primaryContactName?.trim()) return { error: "Primary Contact Name is required." };
    if (!primaryContactEmail?.trim()) return { error: "Primary Contact Email is required." };
  }
  if (accountHealth && !VALID_HEALTH.includes(accountHealth)) return { error: "Invalid account health value." };
  return {
    data: {
      name: name?.trim(),
      crmId: crmId?.trim() || null,
      csmOwnerId: csmOwnerId?.trim(),
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

// GET /api/clients
router.get("/", async (req, res) => {
  try {
    const { skip, take } = parsePagination(req.query as Record<string, string>);
    const { health, csm, segment, search } = req.query as Record<string, string>;

    const conditions = [];
    if (health)   conditions.push(eq(clientsTable.accountHealth, health as any));
    if (csm)      conditions.push(eq(clientsTable.csmOwnerId, csm));
    if (segment)  conditions.push(eq(clientsTable.segment, segment as any));
    if (search)   conditions.push(ilike(clientsTable.name, `%${search}%`));

    const clients = await db.select().from(clientsTable)
      .where(conditions.length ? and(...conditions) : undefined)
      .orderBy(clientsTable.name)
      .offset(skip).limit(take);

    const [{ value: total }] = await db.select({ value: count() }).from(clientsTable)
      .where(conditions.length ? and(...conditions) : undefined);

    const csmIds = [...new Set(clients.map(c => c.csmOwnerId))];
    const csms = csmIds.length > 0
      ? await db.select({ id: usersTable.id, name: usersTable.name, email: usersTable.email })
          .from(usersTable).where(inArray(usersTable.id, csmIds))
      : [];
    const csmMap = Object.fromEntries(csms.map(u => [u.id, u]));

    const enriched = clients.map(c => ({ ...c, csmOwner: csmMap[c.csmOwnerId] ?? null }));
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
      const pgCode = e?.cause?.code ?? e?.code;
      results.push({ row: i + 1, success: false, error: pgCode === "23503" ? "CSM not found." : "Database error." });
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

    const enrollments = await db.select().from(betaEnrollmentsTable)
      .where(eq(betaEnrollmentsTable.clientId, id))
      .orderBy(desc(betaEnrollmentsTable.createdAt));

    const featureIds = [...new Set(enrollments.map(e => e.featureId))];
    const features = featureIds.length > 0 ? await db.select({
      id: betaFeaturesTable.id, name: betaFeaturesTable.name, status: betaFeaturesTable.status
    }).from(betaFeaturesTable).where(inArray(betaFeaturesTable.id, featureIds)) : [];
    const featureMap = Object.fromEntries(features.map(f => [f.id, f]));
    const enrichedEnrollments = enrollments.map(e => ({ ...e, feature: featureMap[e.featureId] ?? null }));

    return ok(res, { ...client, csmOwner, enrollments: enrichedEnrollments });
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
    const update: any = { updatedAt: new Date() };
    const d = validated.data as any;
    const fields = ["name","crmId","csmOwnerId","segment","primaryContactName","primaryContactEmail",
      "accountHealth","vertical","contractRenewalDate","productSubscriptions","lastOutreachDate","tier"];
    for (const f of fields) { if (req.body[f] !== undefined) update[f] = d[f]; }
    const [client] = await db.update(clientsTable).set(update).where(eq(clientsTable.id, req.params.id)).returning();
    if (!client) return err(res, "Client not found.", 404);
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
      id: betaFeaturesTable.id, name: betaFeaturesTable.name, status: betaFeaturesTable.status, startDate: betaFeaturesTable.startDate
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
