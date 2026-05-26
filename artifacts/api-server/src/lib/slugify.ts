import { db, betaFeaturesTable } from "./db";
import { eq, and, ne } from "drizzle-orm";

export function toSlug(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 80);
}

export async function generateUniqueSlug(name: string, excludeId?: string): Promise<string> {
  const base = toSlug(name);
  let slug = base;
  let i = 2;
  while (true) {
    const where = excludeId
      ? and(eq(betaFeaturesTable.slug, slug), ne(betaFeaturesTable.id, excludeId))
      : eq(betaFeaturesTable.slug, slug);
    const [existing] = await db
      .select({ id: betaFeaturesTable.id })
      .from(betaFeaturesTable)
      .where(where)
      .limit(1);
    if (!existing) return slug;
    slug = `${base}-${i++}`;
  }
}
