import { getAuth } from "@clerk/express";
import type { Request, Response, NextFunction } from "express";

export function requireBirdeyeAuth(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  const auth = getAuth(req);

  if (!auth?.userId) {
    res.status(401).json({ error: "Unauthorized" });
    return;
  }

  next();
}
