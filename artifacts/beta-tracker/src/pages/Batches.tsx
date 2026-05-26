import { useEffect, useMemo, useRef, useState } from "react";
import { Link } from "wouter";
import { api } from "@/lib/api";
import { BetaStatusBadge } from "@/components/StatusBadge";
import { HealthDot } from "@/components/HealthDot";
import { MultiSelect } from "@/components/MultiSelect";
import type { BatchFeature, OutreachBatch, User } from "@/lib/types";

// ─── Helpers ─────────────────────────────────────────────────────────────────

function daysSince(date: string | Date | null | undefined): number | null {
  if (!date) return null;
  return Math.floor((Date.now() - new Date(date).getTime()) / 86_400_000);
}

function isReminderSuggested(batch: OutreachBatch) {
  const days = daysSince(batch.sentAt);
  return batch.batchStatus === "sent" && days !== null && days >= 5;
}

function isStale(batch: OutreachBatch) {
  return (
    batch.batchStatus !== "sent" &&
    new Date(batch.createdAt) < new Date(Date.now() - 48 * 3_600_000)
  );
}

// ─── Card status badge ───────────────────────────────────────────────────────

function CardBadge({ batch }: { batch: OutreachBatch }) {
  if (isReminderSuggested(batch)) {
    return (
      <span className="inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-medium bg-amber-100 text-amber-700">
        Reminder
      </span>
    );
  }
  if (batch.batchStatus === "sent") {
    return (
      <span className="inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-medium bg-gray-100 text-gray-500">
        Sent
      </span>
    );
  }
  if (batch.batchStatus === "ready") {
    return (
      <span className="inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-medium bg-green-100 text-green-700">
        Ready
      </span>
    );
  }
  return (
    <span className="inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-medium bg-amber-100 text-amber-700">
      Pending
    </span>
  );
}

// ─── Chevron ─────────────────────────────────────────────────────────────────

function Chevron({ open }: { open: boolean }) {
  return (
    <svg
      className={`h-3.5 w-3.5 transition-transform duration-150 ${open ? "rotate-90" : ""}`}
      viewBox="0 0 16 16"
      fill="currentColor"
    >
      <path d="M6 4l4 4-4 4V4z" />
    </svg>
  );
}

// ─── Detail panel ─────────────────────────────────────────────────────────────

function DetailPanel({
  batch,
  feature,
  users,
  userLabelMap,
  patchedSenderId,
  patchedCcIds,
  draft,
  onSenderChange,
  onCcChange,
  onDraftSaved,
  onSend,
  onClose,
}: {
  batch: OutreachBatch;
  feature: BatchFeature;
  users: User[];
  userLabelMap: Record<string, string>;
  patchedSenderId: string | null;
  patchedCcIds: string[];
  draft: string;
  onSenderChange: (id: string | null) => void;
  onCcChange: (ids: string[]) => void;
  onDraftSaved: (text: string) => void;
  onSend: () => void;
  onClose: () => void;
}) {
  const [generating, setGenerating] = useState(false);
  const [draftError, setDraftError] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  const reminder = isReminderSuggested(batch);
  const stale = isStale(batch);
  const showBanner = reminder || stale;

  const daysSinceSent = daysSince(batch.sentAt);
  const daysSinceOutreach = daysSince(batch.client?.lastOutreachDate);

  const featureEnrollments = (batch.enrollments ?? []).filter(
    (be) => be.enrollment?.feature?.id === feature.id,
  );

  // Build assigned-team / others groups for From + CC
  const assignedUsers: User[] = [];
  const assignedIds = new Set<string>();
  function addAssigned(u: User | null | undefined) {
    if (u && !assignedIds.has(u.id)) { assignedIds.add(u.id); assignedUsers.push(u); }
  }
  addAssigned(feature.ownerPm);
  addAssigned(feature.ownerPmm);
  addAssigned(batch.client?.csmOwner);
  addAssigned(batch.client?.aeOwner);

  const otherUsers = users
    .filter((u) => !assignedIds.has(u.id))
    .sort((a, b) => {
      const lastA = a.name.split(" ").pop() ?? a.name;
      const lastB = b.name.split(" ").pop() ?? b.name;
      return lastA.localeCompare(lastB);
    });

  const fromAssigned = assignedUsers;
  const fromOthers = otherUsers;

  const ccAssigned = assignedUsers.filter((u) => u.id !== patchedSenderId);
  const ccOthers = otherUsers.filter((u) => u.id !== patchedSenderId);
  const ccGroups = [
    ...(ccAssigned.length > 0 ? [{ label: "Assigned team", options: ccAssigned.map((u) => u.id) }] : []),
    ...(ccOthers.length > 0 ? [{ label: "Others", options: ccOthers.map((u) => u.id) }] : []),
  ];

  async function generate() {
    const key = import.meta.env.VITE_GEMINI_API_KEY;
    if (!key) {
      setDraftError("VITE_GEMINI_API_KEY is not set. Add it to .env and restart the dev server.");
      return;
    }
    setGenerating(true);
    setDraftError(null);
    const sender = users.find((u) => u.id === patchedSenderId) ?? null;
    try {
      const role = sender?.role ?? "pm";
      const toneNote =
        role === "csm"
          ? "from a customer success perspective, emphasizing ongoing partnership and support"
          : role === "ae"
          ? "from an account executive perspective, emphasizing business value and strategic fit"
          : "from a product management perspective, emphasizing product vision and early-access impact";

      const prompt = `Write a professional beta program outreach email.

Feature: ${feature.name}
${feature.idealClientCriteria ? `Program description: ${feature.idealClientCriteria}` : ""}
Target tester count: ${feature.targetTesterCount ?? 15}

Client: ${batch.client?.name ?? "the client"}
${batch.client?.tier ? `Tier: ${batch.client.tier}` : ""}
${batch.client?.segment ? `Segment: ${batch.client.segment}` : ""}
${batch.client?.vertical ? `Vertical: ${batch.client.vertical}` : ""}
${batch.client?.primaryContactName ? `Contact name: ${batch.client.primaryContactName}` : ""}

Sender: ${sender?.name ?? "the team"} (${role.toUpperCase()})

Write ${toneNote}.

Format:
- First line: "Subject: <subject line>"
- Then the email body (3–4 paragraphs max)
- Professional but warm tone
- Mention it's an exclusive early-access beta opportunity
- End with a clear call to action to confirm participation
- Do not use any placeholder brackets — use the actual names provided`;

      const resp = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${key}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: { maxOutputTokens: 1000 },
          }),
        },
      );
      const data = await resp.json();
      if (!resp.ok) throw new Error(data.error?.message ?? `Gemini error ${resp.status}`);
      const text: string = data.candidates[0].content.parts[0].text ?? "";
      onDraftSaved(text);
    } catch (e: any) {
      setDraftError(e.message ?? "Failed to generate draft.");
    } finally {
      setGenerating(false);
    }
  }

  function copy() {
    navigator.clipboard.writeText(draft);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  function openGmail() {
    const subject =
      draft.match(/^Subject: (.+)$/m)?.[1] ?? `${feature.name} Beta Program`;
    const body = draft ? draft.replace(/^Subject: .+\r?\n\r?\n?/, "") : "";
    const to = batch.client?.primaryContactEmail ?? "";
    const url = new URL("https://mail.google.com/mail/u/0/");
    url.searchParams.set("view", "cm");
    url.searchParams.set("fs", "1");
    if (to) url.searchParams.set("to", to);
    url.searchParams.set("su", subject);
    if (body) url.searchParams.set("body", body.slice(0, 1800));
    window.open(url.toString(), "_blank");
  }

  return (
    <div className="rounded-xl border border-gray-200 bg-white overflow-hidden">
      {/* Header row: client name + close */}
      <div className="flex items-start justify-between gap-4 px-5 pt-4 pb-3 border-b border-gray-100">
        <div>
          {showBanner && (
            <div className="mb-2 inline-flex items-center rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-medium text-amber-700">
              {reminder
                ? `Last contacted ${daysSinceSent}d ago — reminder suggested`
                : `Pending ${Math.floor((Date.now() - new Date(batch.createdAt).getTime()) / 3_600_000)}h — action needed`}
            </div>
          )}
          <p className="text-base font-semibold text-gray-900 leading-snug">
            {batch.client?.name ?? "—"}
          </p>
          <p className="mt-0.5 text-xs text-gray-400">
            {batch.client?.segment ?? "—"} · {feature.name}
          </p>
        </div>
        <button
          onClick={onClose}
          className="mt-0.5 shrink-0 rounded p-0.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100"
          aria-label="Close panel"
        >
          <svg className="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
            <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
          </svg>
        </button>
      </div>

      {/* 2-column body */}
      <div className="flex gap-0 divide-x divide-gray-100">
        {/* Left column: controls */}
        <div className="w-64 shrink-0 p-4 space-y-4">
          {/* Stats */}
          <div className="grid grid-cols-2 gap-2">
            <div className="rounded-lg bg-gray-50 px-3 py-2.5 text-center">
              <p className="text-xl font-semibold text-gray-900">{featureEnrollments.length}</p>
              <p className="text-[11px] text-gray-400">Enrollments</p>
            </div>
            <div className="rounded-lg bg-gray-50 px-3 py-2.5 text-center">
              <p className="text-xl font-semibold text-gray-900">
                {daysSinceOutreach !== null ? `${daysSinceOutreach}d` : "—"}
              </p>
              <p className="text-[11px] text-gray-400">Since outreach</p>
            </div>
          </div>

          {/* From */}
          <div className="space-y-1">
            <label className="text-xs font-medium text-gray-500 uppercase tracking-wide">From</label>
            <select
              value={patchedSenderId ?? ""}
              onChange={(e) => onSenderChange(e.target.value || null)}
              className="w-full rounded-lg border border-gray-200 bg-white px-3 py-2 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-400"
            >
              <option value="">— select sender —</option>
              {fromAssigned.length > 0 && (
                <optgroup label="Assigned team">
                  {fromAssigned.map((u) => (
                    <option key={u.id} value={u.id}>{userLabelMap[u.id] ?? u.name}</option>
                  ))}
                </optgroup>
              )}
              {fromOthers.length > 0 && (
                <optgroup label="Others">
                  {fromOthers.map((u) => (
                    <option key={u.id} value={u.id}>{userLabelMap[u.id] ?? u.name}</option>
                  ))}
                </optgroup>
              )}
            </select>
          </div>

          {/* CC */}
          <div className="space-y-1">
            <label className="text-xs font-medium text-gray-500 uppercase tracking-wide">CC</label>
            <MultiSelect
              label="Add CC"
              groups={ccGroups}
              selected={patchedCcIds}
              onChange={onCcChange}
              labelMap={userLabelMap}
              className="w-full"
            />
          </div>

          <hr className="border-gray-100" />

          {/* Gmail + Mark as sent */}
          <div className="space-y-2">
            <button
              onClick={openGmail}
              className="flex w-full items-center justify-center gap-2 rounded-lg border border-blue-200 bg-white px-3 py-2 text-sm font-medium text-blue-700 hover:bg-blue-50 transition-colors"
            >
              <svg className="h-4 w-4" viewBox="0 0 24 24" fill="currentColor">
                <path d="M24 5.457v13.909c0 .904-.732 1.636-1.636 1.636h-3.819V11.73L12 16.64l-6.545-4.91v9.273H1.636A1.636 1.636 0 010 19.366V5.457c0-2.023 2.309-3.178 3.927-1.964L5.455 4.64 12 9.548l6.545-4.91 1.528-1.145C21.69 2.28 24 3.434 24 5.457z" />
              </svg>
              Open in Gmail
            </button>
            {batch.batchStatus !== "sent" && (
              <button
                onClick={onSend}
                className="w-full rounded-lg bg-blue-600 px-3 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
              >
                Mark as sent
              </button>
            )}
          </div>

          {batch.sentAt && (
            <p className="text-center text-xs text-gray-400">
              Sent {new Date(batch.sentAt).toLocaleDateString()}
              {batch.sentBy ? ` by ${batch.sentBy.name}` : ""}
            </p>
          )}
        </div>

        {/* Right column: draft area */}
        <div className="flex-1 min-w-0 p-4 flex flex-col gap-3">
          {/* Error */}
          {draftError && (
            <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-700">
              {draftError}
            </div>
          )}

          {/* No draft yet */}
          {!draft && !generating && (
            <div className="flex flex-1 flex-col items-center justify-center gap-3 rounded-xl border border-dashed border-gray-200 py-10">
              <p className="text-sm text-gray-400">No draft yet</p>
              <button
                onClick={generate}
                className="flex items-center gap-2 rounded-lg border border-purple-200 bg-white px-4 py-2 text-sm font-medium text-purple-700 hover:bg-purple-50 transition-colors"
              >
                <svg className="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                  <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                </svg>
                Generate draft email
              </button>
            </div>
          )}

          {/* Generating spinner */}
          {generating && (
            <div className="flex flex-1 items-center justify-center gap-2 py-10 text-sm text-gray-400">
              <div className="h-4 w-4 animate-spin rounded-full border-2 border-gray-200 border-t-purple-500" />
              Generating draft…
            </div>
          )}

          {/* Draft textarea */}
          {draft && !generating && (
            <div className="flex flex-1 flex-col gap-2">
              <div className="flex items-center justify-between">
                <span className="text-xs font-medium uppercase tracking-wide text-gray-400">Draft</span>
                <div className="flex items-center gap-3">
                  <button
                    onClick={copy}
                    className="text-xs text-gray-500 hover:text-gray-700"
                  >
                    {copied ? "Copied!" : "Copy"}
                  </button>
                  <button
                    onClick={generate}
                    className="text-xs text-purple-600 hover:text-purple-700"
                  >
                    Regenerate
                  </button>
                </div>
              </div>
              <textarea
                className="flex-1 min-h-[240px] w-full rounded-lg border border-gray-200 p-3 font-mono text-xs text-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
                value={draft}
                onChange={(e) => onDraftSaved(e.target.value)}
              />
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// ─── Main page ────────────────────────────────────────────────────────────────

type SelectedInfo = { batchId: string; featureId: string };

export default function BatchesPage() {
  const [batches, setBatches] = useState<OutreachBatch[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [patches, setPatches] = useState<Record<string, { senderId: string | null; ccIds: string[] }>>({});
  const [collapsedFeatures, setCollapsedFeatures] = useState<Set<string>>(new Set());
  const [selected, setSelected] = useState<SelectedInfo | null>(null);
  const [drafts, setDrafts] = useState<Record<string, string>>({});
  const [toast, setToast] = useState<string | null>(null);
  const collapsedInitialized = useRef(false);

  function showToast(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(null), 3500);
  }

  async function load() {
    setLoading(true);
    try {
      const [batchData, userData] = await Promise.all([api.batches.list(), api.users.list()]);
      setBatches(batchData.batches ?? []);
      setUsers(userData.users ?? []);
      setPatches({});
      collapsedInitialized.current = false;
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  const userLabelMap = useMemo(
    () => Object.fromEntries(users.map((u) => [u.id, `${u.name} (${u.role.toUpperCase()})`])),
    [users],
  );

  const featureGroups = useMemo(() => {
    const map = new Map<string, { feature: BatchFeature; batches: OutreachBatch[] }>();
    for (const batch of batches) {
      const seen = new Set<string>();
      for (const be of batch.enrollments ?? []) {
        const f = be.enrollment?.feature;
        if (!f || seen.has(f.id)) continue;
        seen.add(f.id);
        if (!map.has(f.id)) map.set(f.id, { feature: f, batches: [] });
        map.get(f.id)!.batches.push(batch);
      }
    }
    return [...map.entries()].sort(([, a], [, b]) =>
      a.feature.name.localeCompare(b.feature.name),
    );
  }, [batches]);

  useEffect(() => {
    if (collapsedInitialized.current || featureGroups.length === 0) return;
    collapsedInitialized.current = true;
    const toCollapse = featureGroups
      .filter(([, { batches: fb }]) => fb.every((b) => b.batchStatus === "sent"))
      .map(([fid]) => fid);
    if (toCollapse.length > 0) setCollapsedFeatures(new Set(toCollapse));
  }, [featureGroups]);

  const linkedBatchIds = useMemo(
    () => new Set(featureGroups.flatMap(([, g]) => g.batches.map((b) => b.id))),
    [featureGroups],
  );
  const orphanBatches = useMemo(
    () => batches.filter((b) => !linkedBatchIds.has(b.id)),
    [batches, linkedBatchIds],
  );

  function getEffective(b: OutreachBatch) {
    return patches[b.id] ?? { senderId: b.senderId ?? null, ccIds: b.ccIds ?? [] };
  }

  async function handleSenderChange(batchId: string, senderId: string | null) {
    const prev = getEffective(batches.find((b) => b.id === batchId)!);
    const ccIds = prev.ccIds.filter((id) => id !== senderId);
    setPatches((p) => ({ ...p, [batchId]: { senderId, ccIds } }));
    try {
      await api.batches.update(batchId, { senderId, ccIds });
    } catch {
      setPatches((p) => ({ ...p, [batchId]: prev }));
      showToast("Failed to save sender.");
    }
  }

  async function handleCcChange(batchId: string, ccIds: string[]) {
    const prev = getEffective(batches.find((b) => b.id === batchId)!);
    setPatches((p) => ({ ...p, [batchId]: { ...prev, ccIds } }));
    try {
      await api.batches.update(batchId, { ccIds });
    } catch {
      setPatches((p) => ({ ...p, [batchId]: prev }));
      showToast("Failed to save CC list.");
    }
  }

  async function trigger() {
    try {
      await api.batches.trigger();
      await load();
      showToast("Batch grouping complete.");
    } catch (e: any) {
      alert(e.data?.error ?? "Failed");
    }
  }

  async function triggerForFeature(featureId: string) {
    try {
      const r = await api.batches.triggerForFeature(featureId);
      await load();
      showToast(
        r.batched > 0
          ? `${r.batched} new batch${r.batched !== 1 ? "es" : ""} created.`
          : "No new batches — all approved enrollments are already batched.",
      );
    } catch (e: any) {
      alert(e.data?.error ?? "Failed");
    }
  }

  async function sendBatch(id: string) {
    try {
      await api.batches.send(id, { overrideCooldown: false });
      await load();
      showToast("Batch marked as sent.");
    } catch (e: any) {
      const errData = (e as any).data ?? {};
      if (errData.cooldown) {
        const go = confirm(`${errData.error}\n\nOverride cooldown and send anyway?`);
        if (go) {
          await api.batches.send(id, { overrideCooldown: true });
          await load();
          showToast("Batch marked as sent.");
        }
      } else {
        alert(errData.error ?? "Failed");
      }
    }
  }

  function toggleFeature(fid: string) {
    setCollapsedFeatures((prev) => {
      const next = new Set(prev);
      next.has(fid) ? next.delete(fid) : next.add(fid);
      return next;
    });
  }

  const selectedBatch = selected ? batches.find((b) => b.id === selected.batchId) ?? null : null;
  const selectedFeature = selected
    ? featureGroups.find(([fid]) => fid === selected.featureId)?.[1].feature ?? null
    : null;

  if (loading) {
    return (
      <div className="space-y-6">
        <h1 className="text-2xl font-semibold text-gray-900">Outreach</h1>
        <div className="py-12 text-center text-sm text-gray-400">Loading…</div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {toast && (
        <div className="fixed bottom-6 left-1/2 z-50 -translate-x-1/2 rounded-lg bg-gray-900 px-4 py-2.5 text-sm text-white shadow-lg">
          {toast}
        </div>
      )}

      <div className="flex items-center justify-between gap-3">
        <h1 className="text-2xl font-semibold text-gray-900">Outreach</h1>
        <button
          onClick={trigger}
          className="rounded-lg border border-gray-200 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50"
        >
          Trigger Batch Grouping
        </button>
      </div>

      {batches.length === 0 ? (
        <div className="rounded-xl border border-gray-200 bg-white py-16 text-center">
          <p className="text-lg text-gray-400">No batches yet.</p>
          <p className="mt-1 text-sm text-gray-300">
            Trigger batch grouping to create batches from approved enrollments.
          </p>
        </div>
      ) : (
        <div className="flex items-start gap-6">
          {/* ── Left: batch list (fixed width) ── */}
          <div className="w-[360px] shrink-0 space-y-6">
            {featureGroups.map(([featureId, { feature, batches: fBatches }]) => {
              const collapsed = collapsedFeatures.has(featureId);
              return (
                <div key={featureId}>
                  <div className="mb-2 flex items-center justify-between gap-2 border-b border-gray-100 pb-2">
                    <div className="flex min-w-0 items-center gap-2">
                      <button
                        onClick={() => toggleFeature(featureId)}
                        className="shrink-0 text-gray-400 hover:text-gray-600"
                      >
                        <Chevron open={!collapsed} />
                      </button>
                      <Link
                        href={`/features/${feature.slug ?? featureId}`}
                        className="truncate text-sm font-medium text-gray-900 hover:text-blue-600"
                      >
                        {feature.name}
                      </Link>
                      {feature.status && <BetaStatusBadge status={feature.status} />}
                    </div>
                    <div className="flex shrink-0 items-center gap-3">
                      <span className="text-xs text-gray-400">
                        {fBatches.length} client{fBatches.length !== 1 ? "s" : ""}
                      </span>
                      <button
                        onClick={() => triggerForFeature(featureId)}
                        className="rounded border border-gray-200 px-2 py-0.5 text-xs text-gray-600 hover:bg-gray-50"
                      >
                        Trigger
                      </button>
                    </div>
                  </div>

                  {!collapsed && (
                    <div className="space-y-1.5 pl-5">
                      {fBatches.map((batch) => {
                        const isSelected =
                          selected?.batchId === batch.id && selected?.featureId === featureId;
                        const daysCreated = daysSince(batch.createdAt);
                        const featureEnrollments = (batch.enrollments ?? []).filter(
                          (be) => be.enrollment?.feature?.id === featureId,
                        );
                        const daysSinceOutreach = daysSince(batch.client?.lastOutreachDate);

                        return (
                          <button
                            key={batch.id}
                            onClick={() => setSelected({ batchId: batch.id, featureId })}
                            className={`w-full rounded-lg border bg-white px-3 py-2.5 text-left transition-colors hover:bg-gray-50 ${
                              isSelected
                                ? "border-blue-400 bg-blue-50/40 shadow-sm"
                                : "border-gray-200"
                            }`}
                          >
                            <div className="flex items-center justify-between gap-2">
                              <div className="flex min-w-0 items-center gap-1.5">
                                <HealthDot health={batch.client?.accountHealth ?? "green"} />
                                <span className="truncate text-sm font-medium text-gray-900">
                                  {batch.client?.name ?? "—"}
                                </span>
                              </div>
                              <CardBadge batch={batch} />
                            </div>
                            <p className="mt-0.5 truncate text-xs text-gray-400">
                              {[
                                batch.client?.segment,
                                `${featureEnrollments.length} enrolled`,
                                daysSinceOutreach !== null
                                  ? `${daysSinceOutreach}d since outreach`
                                  : "no prior outreach",
                                batch.sentAt
                                  ? `Sent ${new Date(batch.sentAt).toLocaleDateString()}`
                                  : `Created ${daysCreated !== null ? `${daysCreated}d` : ""} ago`,
                              ]
                                .filter(Boolean)
                                .join(" · ")}
                            </p>
                          </button>
                        );
                      })}
                    </div>
                  )}
                </div>
              );
            })}

            {orphanBatches.length > 0 && (
              <div>
                <div className="mb-2 border-b border-gray-100 pb-2">
                  <p className="text-xs font-medium text-gray-400">Other batches</p>
                </div>
                <div className="space-y-1.5">
                  {orphanBatches.map((batch) => {
                    const isSelected = selected?.batchId === batch.id && !selected?.featureId;
                    return (
                      <button
                        key={batch.id}
                        onClick={() => setSelected({ batchId: batch.id, featureId: "" })}
                        className={`w-full rounded-lg border bg-white px-3 py-2.5 text-left transition-colors hover:bg-gray-50 ${
                          isSelected ? "border-blue-400 bg-blue-50/40 shadow-sm" : "border-gray-200"
                        }`}
                      >
                        <div className="flex items-center justify-between gap-2">
                          <div className="flex min-w-0 items-center gap-1.5">
                            <HealthDot health={batch.client?.accountHealth ?? "green"} />
                            <span className="truncate text-sm font-medium text-gray-900">
                              {batch.client?.name ?? "—"}
                            </span>
                          </div>
                          <CardBadge batch={batch} />
                        </div>
                        <p className="mt-0.5 truncate text-xs text-gray-400">
                          Created {new Date(batch.createdAt).toLocaleDateString()}
                        </p>
                      </button>
                    );
                  })}
                </div>
              </div>
            )}
          </div>

          {/* ── Right: detail panel (fills remaining page width) ── */}
          {selectedBatch && selectedFeature && (
            <div className="flex-1 min-w-0">
              <div className="sticky top-4">
                <DetailPanel
                  batch={selectedBatch}
                  feature={selectedFeature}
                  users={users}
                  userLabelMap={userLabelMap}
                  patchedSenderId={getEffective(selectedBatch).senderId}
                  patchedCcIds={getEffective(selectedBatch).ccIds}
                  draft={drafts[selectedBatch.id] ?? ""}
                  onSenderChange={(id) => handleSenderChange(selectedBatch.id, id)}
                  onCcChange={(ids) => handleCcChange(selectedBatch.id, ids)}
                  onDraftSaved={(text) => setDrafts((prev) => ({ ...prev, [selectedBatch.id]: text }))}
                  onSend={() => sendBatch(selectedBatch.id)}
                  onClose={() => setSelected(null)}
                />
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
