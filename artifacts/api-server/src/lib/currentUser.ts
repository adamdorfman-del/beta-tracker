import { getAuth, clerkClient } from "@clerk/express";
import { db, usersTable } from "./db";
import { eq } from "drizzle-orm";
import type { Request } from "express";

/**
 * Resolves the current request's Clerk session to an internal DB user.
 * Falls back to the first admin if the session can't be mapped (e.g. service
 * calls or users not yet in the users table).
 */
export async function getRequestUser(req: Request) {
  try {
    const { userId } = getAuth(req);
    if (userId) {
      const clerkUser = await clerkClient.users.getUser(userId);
      const email = clerkUser.emailAddresses
        .find((e: any) => e.id === clerkUser.primaryEmailAddressId)
        ?.emailAddress;
      if (email) {
        const [user] = await db.select().from(usersTable)
          .where(eq(usersTable.email, email.toLowerCase()));
        if (user) return user;
      }
    }
  } catch {
    // fall through to admin fallback
  }

  // Fallback: first admin in the table (preserves existing behaviour for
  // service-level calls that have no session)
  const [admin] = await db.select().from(usersTable)
    .where(eq(usersTable.role, "admin")).limit(1);
  if (admin) return admin;

  const [fallback] = await db.select().from(usersTable).limit(1);
  if (!fallback) throw new Error("No users found in the system.");
  return fallback;
}
