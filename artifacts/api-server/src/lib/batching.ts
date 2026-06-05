import { db, outreachBatchesTable, outreachBatchEnrollmentsTable, betaEnrollmentsTable } from "./db";
import { eq, and, count, inArray, notInArray } from "drizzle-orm";

const BATCHABLE_STATUSES = ["csm_approved", "enrolled", "using", "accepted"] as const;

export async function triggerBatching(featureId: string | null): Promise<number> {
  const query = db.select().from(betaEnrollmentsTable)
    .where(and(
      inArray(betaEnrollmentsTable.testerStatus, [...BATCHABLE_STATUSES] as any),
      ...(featureId ? [eq(betaEnrollmentsTable.featureId, featureId)] : []),
    ));

  const unbatched = await query;

  const allBatchEntries = await db.select().from(outreachBatchEnrollmentsTable);
  const batchedEnrollmentIds = new Set(allBatchEntries.map(e => e.enrollmentId));
  const toGroup = unbatched.filter(e => !batchedEnrollmentIds.has(e.id));

  const byClient = new Map<string, typeof toGroup>();
  for (const e of toGroup) {
    const list = byClient.get(e.clientId) ?? [];
    list.push(e);
    byClient.set(e.clientId, list);
  }

  let created = 0;
  for (const [clientId, enrollments] of byClient) {
    const [existingBatch] = await db.select().from(outreachBatchesTable)
      .where(and(
        eq(outreachBatchesTable.clientId, clientId),
        inArray(outreachBatchesTable.batchStatus, ["pending", "ready"] as any)
      )).limit(1);

    let batchId = existingBatch?.id;
    if (!batchId) {
      const [batch] = await db.insert(outreachBatchesTable).values({ clientId, batchStatus: "pending" }).returning();
      batchId = batch.id;
      created++;
    }

    for (const e of enrollments) {
      await db.insert(outreachBatchEnrollmentsTable).values({ batchId, enrollmentId: e.id })
        .onConflictDoNothing();
    }

    const batchEntries = await db.select().from(outreachBatchEnrollmentsTable)
      .where(eq(outreachBatchEnrollmentsTable.batchId, batchId));
    const batchEnrollmentIds = batchEntries.map(be => be.enrollmentId);
    if (batchEnrollmentIds.length > 0) {
      const [{ value: notReadyCount }] = await db.select({ value: count() }).from(betaEnrollmentsTable)
        .where(and(
          inArray(betaEnrollmentsTable.id, batchEnrollmentIds),
          notInArray(betaEnrollmentsTable.testerStatus, [...BATCHABLE_STATUSES] as any)
        ));
      if (notReadyCount === 0) {
        await db.update(outreachBatchesTable).set({ batchStatus: "ready", updatedAt: new Date() })
          .where(and(eq(outreachBatchesTable.id, batchId), eq(outreachBatchesTable.batchStatus, "pending")));
      }
    }
  }

  return created;
}
