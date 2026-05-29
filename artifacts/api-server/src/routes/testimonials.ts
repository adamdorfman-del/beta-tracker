import { Router } from "express";
import { getAuth, clerkClient } from "@clerk/express";
import { db, testimonialsTable, clientsTable, betaFeaturesTable, usersTable } from "../lib/db";
import { ok, err } from "../lib/helpers";
import { eq, and, desc } from "drizzle-orm";

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

// GET /api/testimonials
router.get("/", async (req, res) => {
  try {
    const { feature_id, client_id, approved } = req.query as Record<string, string>;
    const conditions: any[] = [];
    if (feature_id) conditions.push(eq(testimonialsTable.featureId, feature_id));
    if (client_id)  conditions.push(eq(testimonialsTable.clientId, client_id));
    if (approved === "true")  conditions.push(eq(testimonialsTable.approved, true));
    if (approved === "false") conditions.push(eq(testimonialsTable.approved, false));

    const rows = await db.select({
      id:          testimonialsTable.id,
      quote:       testimonialsTable.quote,
      context:     testimonialsTable.context,
      approved:    testimonialsTable.approved,
      callDate:    testimonialsTable.callDate,
      createdAt:   testimonialsTable.createdAt,
      clientId:    testimonialsTable.clientId,
      clientName:  clientsTable.name,
      featureId:   testimonialsTable.featureId,
      featureName: betaFeaturesTable.name,
      featureSlug: betaFeaturesTable.slug,
      createdById: testimonialsTable.createdById,
      createdByName: usersTable.name,
    })
      .from(testimonialsTable)
      .innerJoin(clientsTable, eq(testimonialsTable.clientId, clientsTable.id))
      .innerJoin(betaFeaturesTable, eq(testimonialsTable.featureId, betaFeaturesTable.id))
      .innerJoin(usersTable, eq(testimonialsTable.createdById, usersTable.id))
      .where(conditions.length ? and(...conditions) : undefined)
      .orderBy(desc(testimonialsTable.createdAt));

    return ok(res, { testimonials: rows });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// POST /api/testimonials
router.post("/", async (req, res) => {
  try {
    const currentUser = await getCurrentDbUser(req);
    if (!currentUser) return err(res, "Unauthorized", 401);
    if (!["csm", "pm", "admin"].includes(currentUser.role)) return err(res, "Forbidden", 403);

    const { clientId, featureId, quote, context, approved, callDate } = req.body;
    if (!clientId || !featureId || !quote?.trim()) {
      return err(res, "clientId, featureId, and quote are required.");
    }

    const [entry] = await db.insert(testimonialsTable).values({
      id: crypto.randomUUID(),
      clientId,
      featureId,
      quote: quote.trim(),
      context: context?.trim() || null,
      approved: approved === true,
      callDate: callDate || null,
      createdById: currentUser.id,
    }).returning();

    return ok(res, entry, 201);
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// PUT /api/testimonials/:id
router.put("/:id", async (req, res) => {
  try {
    const currentUser = await getCurrentDbUser(req);
    if (!currentUser) return err(res, "Unauthorized", 401);

    const [entry] = await db.select().from(testimonialsTable).where(eq(testimonialsTable.id, req.params.id));
    if (!entry) return err(res, "Not found.", 404);

    const canEdit = currentUser.role === "admin" || currentUser.role === "pm" || entry.createdById === currentUser.id;
    if (!canEdit) return err(res, "Forbidden", 403);

    const update: Record<string, unknown> = {};
    if (req.body.quote !== undefined)    update.quote    = req.body.quote?.trim() || entry.quote;
    if (req.body.context !== undefined)  update.context  = req.body.context?.trim() || null;
    if (req.body.approved !== undefined) update.approved = req.body.approved === true;
    if (req.body.callDate !== undefined) update.callDate = req.body.callDate || null;

    const [updated] = await db.update(testimonialsTable).set(update as any).where(eq(testimonialsTable.id, req.params.id)).returning();
    return ok(res, updated);
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// DELETE /api/testimonials/:id
router.delete("/:id", async (req, res) => {
  try {
    const currentUser = await getCurrentDbUser(req);
    if (!currentUser) return err(res, "Unauthorized", 401);

    const [entry] = await db.select().from(testimonialsTable).where(eq(testimonialsTable.id, req.params.id));
    if (!entry) return err(res, "Not found.", 404);

    const canDelete = currentUser.role === "admin" || currentUser.role === "pm" || entry.createdById === currentUser.id;
    if (!canDelete) return err(res, "Forbidden", 403);

    await db.delete(testimonialsTable).where(eq(testimonialsTable.id, req.params.id));
    return res.status(204).end();
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

export default router;
