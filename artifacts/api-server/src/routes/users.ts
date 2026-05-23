import { Router } from "express";
import { db, usersTable } from "../lib/db";
import { ok, err } from "../lib/helpers";
import { eq } from "drizzle-orm";
import { requireRole } from "../middlewares/requireRole";

const router = Router();
const pmOrAdmin = requireRole("pm", "admin");

const VALID_ROLES = ["pm", "pmm", "csm", "admin"] as const;
type Role = typeof VALID_ROLES[number];

function validateUserBody(body: any): { data: { name: string; email: string; role: Role; image: string | null } } | { error: string } {
  const { name, email, role, image } = body ?? {};
  if (!name || typeof name !== "string" || !name.trim()) return { error: "Name is required." };
  if (!email || typeof email !== "string" || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return { error: "A valid email is required." };
  if (!role || !VALID_ROLES.includes(role)) return { error: `Role must be one of: ${VALID_ROLES.join(", ")}.` };
  return { data: { name: name.trim(), email: email.trim().toLowerCase(), role, image: image?.trim() || null } };
}

// GET /api/users
router.get("/", async (req, res) => {
  try {
    const users = await db.select().from(usersTable).orderBy(usersTable.name);
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
