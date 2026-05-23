import { getAuth, clerkClient } from "@clerk/express";
import { db, usersTable } from "../lib/db";
import { eq } from "drizzle-orm";
import type { Request, Response, NextFunction } from "express";

export function requireRole(...roles: string[]) {
  return async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { userId } = getAuth(req);
      if (!userId) { res.status(401).json({ error: "Unauthorized" }); return; }

      const clerkUser = await clerkClient.users.getUser(userId);
      const email = clerkUser.emailAddresses.find(e => e.id === clerkUser.primaryEmailAddressId)?.emailAddress;
      if (!email) { res.status(403).json({ error: "Forbidden" }); return; }

      const [appUser] = await db.select({ role: usersTable.role }).from(usersTable).where(eq(usersTable.email, email.toLowerCase()));
      if (!appUser || !roles.includes(appUser.role)) {
        res.status(403).json({ error: "Forbidden: insufficient role." });
        return;
      }
      next();
    } catch {
      res.status(403).json({ error: "Forbidden" });
    }
  };
}
