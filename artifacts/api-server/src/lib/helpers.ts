import type { Response } from "express";

export function ok(res: Response, data: unknown, status = 200) {
  return res.status(status).json(data);
}

export function err(res: Response, message: string, status = 400) {
  return res.status(status).json({ error: message });
}

export function parsePagination(query: Record<string, string | undefined>) {
  const page = Math.max(1, parseInt(query.page ?? "1", 10));
  const limit = Math.min(100, Math.max(1, parseInt(query.limit ?? "20", 10)));
  return { skip: (page - 1) * limit, take: limit };
}

export function parseDateRange(query: Record<string, string | undefined>) {
  const from = query.from ? new Date(query.from) : undefined;
  const to = query.to ? new Date(query.to) : undefined;
  return { from, to };
}
