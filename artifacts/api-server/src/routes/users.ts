import { Router } from "express";
import { db, usersTable, betaFeaturesTable, betaEnrollmentsTable, clientsTable } from "../lib/db";
import { ok, err } from "../lib/helpers";
import { eq, or, inArray, sql } from "drizzle-orm";
import { requireRole } from "../middlewares/requireRole";

const router = Router();
const pmOrAdmin = requireRole("pm", "admin");

const VALID_ROLES = ["pm", "pmm", "csm", "admin", "ae"] as const;
type Role = typeof VALID_ROLES[number];

function validateUserBody(body: any): { data: { name: string; email: string; role: Role; image: string | null } } | { error: string } {
  const { name, email, role, image } = body ?? {};
  if (!name || typeof name !== "string" || !name.trim()) return { error: "Name is required." };
  if (!email || typeof email !== "string" || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return { error: "A valid email is required." };
  if (!role || !VALID_ROLES.includes(role)) return { error: `Role must be one of: ${VALID_ROLES.join(", ")}.` };
  return { data: { name: name.trim(), email: email.trim().toLowerCase(), role, image: image?.trim() || null } };
}

// GET /api/users/:id/betas — betas and clients this stakeholder is associated with
router.get("/:id/betas", async (req, res) => {
  const { id } = req.params;
  try {
    // Features where user is PM or PMM
    const features = await db.select().from(betaFeaturesTable)
      .where(or(eq(betaFeaturesTable.ownerPmId, id), eq(betaFeaturesTable.ownerPmmId, id)));

    // Enrollments for those features, joined to client names
    const featureIds = features.map(f => f.id);
    const featureEnrollments = featureIds.length > 0
      ? await db.select({
          featureId: betaEnrollmentsTable.featureId,
          clientId:  betaEnrollmentsTable.clientId,
          clientName: clientsTable.name,
          testerStatus: betaEnrollmentsTable.testerStatus,
        })
        .from(betaEnrollmentsTable)
        .innerJoin(clientsTable, eq(betaEnrollmentsTable.clientId, clientsTable.id))
        .where(inArray(betaEnrollmentsTable.featureId, featureIds))
      : [];

    const enrollmentsByFeature: Record<string, typeof featureEnrollments> = {};
    for (const row of featureEnrollments) {
      (enrollmentsByFeature[row.featureId] ??= []).push(row);
    }

    // Clients where user is CSM, with their beta enrollments
    const ownedClients = await db
      .select({ id: clientsTable.id, name: clientsTable.name, segment: clientsTable.segment, accountHealth: clientsTable.accountHealth })
      .from(clientsTable)
      .where(eq(clientsTable.csmOwnerId, id));

    const clientIds = ownedClients.map(c => c.id);
    const clientEnrollments = clientIds.length > 0
      ? await db.select({
          clientId: betaEnrollmentsTable.clientId,
          featureId: betaEnrollmentsTable.featureId,
          featureName: betaFeaturesTable.name,
          featureStatus: betaFeaturesTable.status,
          featureSlug: betaFeaturesTable.slug,
          testerStatus: betaEnrollmentsTable.testerStatus,
        })
        .from(betaEnrollmentsTable)
        .innerJoin(betaFeaturesTable, eq(betaEnrollmentsTable.featureId, betaFeaturesTable.id))
        .where(inArray(betaEnrollmentsTable.clientId, clientIds))

      : [];

    const enrollmentsByClient: Record<string, typeof clientEnrollments> = {};
    for (const row of clientEnrollments) {
      (enrollmentsByClient[row.clientId] ??= []).push(row);
    }

    return ok(res, {
      features: features.map(f => ({ ...f, clients: enrollmentsByFeature[f.id] ?? [] })),
      csmClients: ownedClients.map(c => ({ ...c, betas: enrollmentsByClient[c.id] ?? [] })),
    });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// GET /api/users
router.get("/", async (req, res) => {
  try {
    const users = await db.select({
      id: usersTable.id,
      name: usersTable.name,
      email: usersTable.email,
      role: usersTable.role,
      image: usersTable.image,
      createdAt: usersTable.createdAt,
      betaCount: sql<number>`(
        SELECT COUNT(DISTINCT f.id) FROM beta_features f
        WHERE f.owner_pm = "users".id OR f.owner_pmm = "users".id
      ) + (
        SELECT COUNT(DISTINCT e.feature_id) FROM beta_enrollments e
        JOIN clients c ON e.client_id = c.id
        WHERE c.csm_owner = "users".id
      )`,
    }).from(usersTable).orderBy(usersTable.name);
    return ok(res, { users });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// POST /api/users
router.post("/", pmOrAdmin, async (req, res) => {
  const validated = validateUserBody(req.body);
  if ("error" in validated) return err(res, validated.error, 400);
  try {
    const [user] = await db.insert(usersTable).values(validated.data).returning();
    return ok(res, { user }, 201);
  } catch (e: any) {
    const pgCode = e?.cause?.code ?? e?.code;
    if (pgCode === "23505") return err(res, "A user with that email already exists.", 409);
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// PUT /api/users/:id
router.put("/:id", pmOrAdmin, async (req, res) => {
  const validated = validateUserBody(req.body);
  if ("error" in validated) return err(res, validated.error, 400);
  try {
    const [user] = await db
      .update(usersTable)
      .set(validated.data)
      .where(eq(usersTable.id, req.params.id))
      .returning();
    if (!user) return err(res, "User not found", 404);
    return ok(res, { user });
  } catch (e: any) {
    const pgCode = e?.cause?.code ?? e?.code;
    if (pgCode === "23505") return err(res, "A user with that email already exists.", 409);
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

// DELETE /api/users/:id
router.delete("/:id", pmOrAdmin, async (req, res) => {
  try {
    const [user] = await db
      .delete(usersTable)
      .where(eq(usersTable.id, req.params.id))
      .returning();
    if (!user) return err(res, "User not found", 404);
    return ok(res, { user });
  } catch (e: any) {
    const pgCode = e?.cause?.code ?? e?.code;
    if (pgCode === "23503") return err(res, "Cannot delete: this user is referenced by existing features, clients, or enrollments.", 409);
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

export default router;
