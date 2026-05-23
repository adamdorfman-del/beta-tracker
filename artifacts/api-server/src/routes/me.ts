import { Router } from "express";
import { getAuth, clerkClient } from "@clerk/express";
import { db, usersTable } from "../lib/db";
import { eq } from "drizzle-orm";
import { ok, err } from "../lib/helpers";

const router = Router();

router.get("/", async (req, res) => {
  try {
    const { userId } = getAuth(req);
    if (!userId) return err(res, "Unauthorized", 401);

    const clerkUser = await clerkClient.users.getUser(userId);
    const email = clerkUser.emailAddresses.find(e => e.id === clerkUser.primaryEmailAddressId)?.emailAddress;
    if (!email) return err(res, "No email on Clerk account", 400);

    const [user] = await db.select({ id: usersTable.id, name: usersTable.name, email: usersTable.email, role: usersTable.role })
      .from(usersTable)
      .where(eq(usersTable.email, email.toLowerCase()));

    if (!user) return err(res, "User not found in app", 404);
    return ok(res, { user });
  } catch (e) {
    req.log.error(e);
    return err(res, "Internal error", 500);
  }
});

export default router;
