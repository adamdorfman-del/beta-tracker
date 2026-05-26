import { useEffect, useMemo, useState } from "react";
import { Link } from "wouter";
import { api } from "@/lib/api";
import { BatchStatusBadge, BetaStatusBadge } from "@/components/StatusBadge";
import { HealthDot } from "@/components/HealthDot";
import { MultiSelect } from "@/components/MultiSelect";
import type { BatchFeature, OutreachBatch, User } from "@/lib/types";

// ─── Draft modal ────────────────────────────────────────────────────────────

function DraftModal({
  batch,
  feature,
  sender,
  onClose,
}: {
  batch: OutreachBatch;
  feature: BatchFeature;
  sender: User | null;
  onClose: () => void;
}) {
  const [draft, setDraft] = useState("");
  const [generating, setGenerating] = useState(false);
  const [copied, setCopied] = useState(false);

  async function generate() {
    const key = (import.meta as any).env?.VITE_ANTHROPIC_API_KEY;
    if (!key) {
      alert("Set VITE_ANTHROPIC_API_KEY in your .env to enable AI drafts.");
      return;
    }
    setGenerating(true);
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

      const resp = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "x-api-key": key,
          "anthropic-version": "2023-06-01",
          "content-type": "application/json",
          "anthropic-dangerous-direct-browser-access": "true",
        },
        body: JSON.stringify({
          model: "claude-sonnet-4-6",
          max_tokens: 1024,
          messages: [{ role: "user", content: prompt }],
        }),
      });
      const data = await resp.json();
      setDraft(data.content?.[0]?.text ?? "");
    } catch {
      alert("Failed to generate draft. Check VITE_ANTHROPIC_API_KEY and network access.");
    } finally {
      setGenerating(false);
    }
  }

  function copy() {
    navigator.clipboard.writeText(draft);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="flex w-full max-w-2xl flex-col rounded-xl bg-white shadow-xl" style={{ maxHeight: "90vh" }}>
        <div className="flex items-center justify-between border-b border-gray-200 px-6 py-4">
          <div>
            <h2 className="text-base font-semibold text-gray-900">AI Draft Email</h2>
            <p className="text-xs text-gray-500">
              {feature.name} → {batch.client?.name}
              {sender && <> · Sender: {sender.name}</>}
            </p>
          </div>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600">
            <svg className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
            </svg>
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-6 space-y-4">
          {!draft ? (
            <div className="rounded-lg border border-gray-200 bg-gray-50 p-4 text-sm">
              <p className="font-medium text-gray-700 mb-2">Ready to generate</p>
              <dl className="space-y-1 text-gray-500">
                <div className="flex gap-2"><dt className="w-20 shrink-0">Feature</dt><dd className="font-medium text-gray-700">{feature.name}</dd></div>
                <div className="flex gap-2"><dt className="w-20 shrink-0">Client</dt><dd className="font-medium text-gray-700">{batch.client?.name}</dd></div>
                <div className="flex gap-2"><dt className="w-20 shrink-0">Sender</dt><dd className="font-medium text-gray-700">{sender ? `${sender.name} (${sender.role.toUpperCase()})` : "None selected"}</dd></div>
              </dl>
            </div>
          ) : (
            <textarea
              className="h-72 w-full rounded-lg border border-gray-200 p-3 font-mono text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
              value={draft}
              onChange={(e) => setDraft(e.target.value)}
            />
          )}
        </div>

        <div className="flex items-center justify-between border-t border-gray-200 px-6 py-4">
          <button onClick={onClose} className="text-sm text-gray-500 hover:text-gray-700">Close</button>
          <div className="flex gap-3">
            {draft && (
              <button
                onClick={copy}
                className="rounded-lg border border-gray-300 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50"
              >
                {copied ? "Copied!" : "Copy"}
              </button>
            )}
            <button
              onClick={generate}
              disabled={generating}
              className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
            >
              {generating ? "Generating…" : draft ? "Regenerate" : "Generate Draft"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Batch card ──────────────────────────────────────────────────────────────

function BatchCard({
  batch,
  feature,
  users,
  userLabelMap,
  patchedSenderId,
  patchedCcIds,
  onSenderChange,
  onCcChange,
  onOpenDraft,
  onSend,
}: {
  batch: OutreachBatch;
  feature: BatchFeature;
  users: User[];
  userLabelMap: Record<string, string>;
  patchedSenderId: string | null;
  patchedCcIds: string[];
  onSenderChange: (id: string | null) => void;
  onCcChange: (ids: string[]) => void;
  onOpenDraft: () => void;
  onSend: () => void;
}) {
  const staleThreshold = new Date(Date.now() - 48 * 3600000);
  const isStale = batch.batchStatus !== "sent" && new Date(batch.createdAt) < staleThreshold;

  const featureEnrollments = (batch.enrollments ?? []).filter(
    be => be.enrollment?.feature?.id === feature.id
  );
  const pendingApprovals = featureEnrollments.filter(be => !be.enrollment?.csmApprovedBy).length;

  const sender = users.find(u => u.id === patchedSenderId) ?? null;
  const ccOptions = users.map(u => u.id).filter(id => id !== patchedSenderId);

  const daysSinceOutreach = batch.client?.lastOutreachDate
    ? Math.floor((Date.now() - new Date(batch.client.lastOutreachDate).getTime()) / 86400000)
    : null;

  return (
    <div className={`rounded-lg border bg-white p-4 space-y-3 ${isStale ? "border-red-200" : "border-gray-200"}`}>
      {/* Client header */}
      <div className="flex items-center justify-between flex-wrap gap-2">
        <div className="flex items-center gap-2">
          <HealthDot health={batch.client?.accountHealth ?? "green"} />
          <div>
            <p className="text-sm font-semibold text-gray-900">{batch.client?.name}</p>
            <p className="text-xs text-gray-400">
              {batch.client?.tier ? `Tier ${batch.client.tier}` : ""}
              {batch.client?.segment ? ` · ${batch.client.segment}` : ""}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <BatchStatusBadge status={batch.batchStatus} />
          {isStale && <span className="text-xs font-medium text-red-600">Pending 48h+</span>}
          {pendingApprovals > 0 && (
            <span className="text-xs text-amber-600">{pendingApprovals} CSM approval{pendingApprovals !== 1 ? "s" : ""} pending</span>
          )}
        </div>
      </div>

      {/* Sender + CC row */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="flex items-center gap-2 text-xs text-gray-500">
          <span className="w-12 shrink-0 font-medium">From</span>
          <select
            value={patchedSenderId ?? ""}
            onChange={(e) => onSenderChange(e.target.value || null)}
            className="rounded border border-gray-200 bg-white px-2 py-1 text-xs text-gray-700 focus:outline-none focus:ring-1 focus:ring-blue-400"
          >
            <option value="">— select sender —</option>
            {users.map(u => (
              <option key={u.id} value={u.id}>{userLabelMap[u.id]}</option>
            ))}
          </select>
        </div>
        <div className="flex items-center gap-2 text-xs text-gray-500">
          <span className="w-12 shrink-0 font-medium">CC</span>
          <MultiSelect
            label="Add CC"
            options={ccOptions}
            selected={patchedCcIds}
            onChange={onCcChange}
            labelMap={userLabelMap}
            className="min-w-[160px]"
          />
        </div>
        <button
          onClick={onOpenDraft}
          className="ml-auto rounded border border-purple-200 bg-purple-50 px-3 py-1 text-xs font-medium text-purple-700 hover:bg-purple-100"
        >
          Draft Email
        </button>
      </div>

      {/* Timing info */}
      <div className="flex flex-wrap items-center gap-x-5 gap-y-1 text-xs text-gray-400">
        <span>{featureEnrollments.length} enrollment{featureEnrollments.length !== 1 ? "s" : ""} in this feature</span>
        <span>Created {new Date(batch.createdAt).toLocaleDateString()}</span>
        {batch.sentAt && (
          <span>Sent {new Date(batch.sentAt).toLocaleDateString()}{batch.sentBy ? ` by ${batch.sentBy.name}` : ""}</span>
        )}
        {daysSinceOutreach !== null ? (
          <span className={daysSinceOutreach < 30 ? "text-amber-500" : "text-gray-400"}>
            Last outreach {daysSinceOutreach}d ago
          </span>
        ) : (
          <span>No prior outreach</span>
        )}
      </div>

      {/* Send button */}
      {batch.batchStatus !== "sent" && (
        <div className="flex justify-end pt-1">
          <button
            onClick={onSend}
            className="rounded-lg bg-blue-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-blue-700"
          >
            Send
          </button>
        </div>
      )}
    </div>
  );
}

// ─── Main page ───────────────────────────────────────────────────────────────

export default function BatchesPage() {
  const [batches, setBatches] = useState<OutreachBatch[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [patches, setPatches] = useState<Record<string, { senderId: string | null; ccIds: string[] }>>({});
  const [collapsedFeatures, setCollapsedFeatures] = useState<Set<string>>(new Set());
  const [draftInfo, setDraftInfo] = useState<{ batch: OutreachBatch; feature: BatchFeature } | null>(null);
  const [toast, setToast] = useState<string | null>(null);

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
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  const userLabelMap = useMemo(() =>
    Object.fromEntries(users.map(u => [u.id, `${u.name} (${u.role.toUpperCase()})`])),
    [users]
  );

  // Effective sender/cc for a batch (patches take priority over DB values)
  function getEffective(b: OutreachBatch) {
    return patches[b.id] ?? { senderId: b.senderId ?? null, ccIds: b.ccIds ?? [] };
  }

  async function handleSenderChange(batchId: string, senderId: string | null) {
    const prev = getEffective(batches.find(b => b.id === batchId)!);
    const ccIds = prev.ccIds.filter(id => id !== senderId);
    setPatches(p => ({ ...p, [batchId]: { senderId, ccIds } }));
    try {
      await api.batches.update(batchId, { senderId, ccIds });
    } catch {
      setPatches(p => ({ ...p, [batchId]: prev }));
      showToast("Failed to save sender.");
    }
  }

  async function handleCcChange(batchId: string, ccIds: string[]) {
    const prev = getEffective(batches.find(b => b.id === batchId)!);
    setPatches(p => ({ ...p, [batchId]: { ...prev, ccIds } }));
    try {
      await api.batches.update(batchId, { ccIds });
    } catch {
      setPatches(p => ({ ...p, [batchId]: prev }));
      showToast("Failed to save CC list.");
    }
  }

  async function trigger() {
    try { await api.batches.trigger(); await load(); showToast("Batch grouping complete."); }
    catch (e: any) { alert(e.data?.error ?? "Failed"); }
  }

  async function triggerForFeature(featureId: string) {
    try {
      const r = await api.batches.triggerForFeature(featureId);
      await load();
      showToast(r.batched > 0 ? `${r.batched} new batch${r.batched !== 1 ? "es" : ""} created.` : "No new batches — all approved enrollments are already batched.");
    } catch (e: any) { alert(e.data?.error ?? "Failed"); }
  }

  async function sendBatch(id: string, overrideCooldown = false) {
    if (!confirm("Send this outreach batch?")) return;
    try {
      await api.batches.send(id, { overrideCooldown });
      await load();
      showToast("Batch marked as sent.");
    } catch (e: any) {
      const errData = (e as any).data ?? {};
      if (errData.cooldown) {
        const go = confirm(`${errData.error}\n\nOverride cooldown and send anyway?`);
        if (go) { await api.batches.send(id, { overrideCooldown: true }); await load(); showToast("Batch marked as sent."); }
      } else {
        alert(errData.error ?? "Failed");
      }
    }
  }

  // Group batches by feature (a batch can appear in multiple groups)
  const featureGroups = useMemo(() => {
    const map = new Map<string, { feature: BatchFeature; batches: OutreachBatch[] }>();
    for (const batch of batches) {
      const seen = new Set<string>();
      for (const be of (batch.enrollments ?? [])) {
        const f = be.enrollment?.feature;
        if (!f || seen.has(f.id)) continue;
        seen.add(f.id);
        if (!map.has(f.id)) map.set(f.id, { feature: f, batches: [] });
        map.get(f.id)!.batches.push(batch);
      }
    }
    return [...map.entries()]
      .sort(([, a], [, b]) => a.feature.name.localeCompare(b.feature.name));
  }, [batches]);

  const linkedBatchIds = useMemo(() =>
    new Set(featureGroups.flatMap(([, g]) => g.batches.map(b => b.id))),
    [featureGroups]
  );
  const orphanBatches = useMemo(() =>
    batches.filter(b => !linkedBatchIds.has(b.id)),
    [batches, linkedBatchIds]
  );

  function toggleFeature(fid: string) {
    setCollapsedFeatures(prev => {
      const next = new Set(prev);
      next.has(fid) ? next.delete(fid) : next.add(fid);
      return next;
    });
  }

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

      <div className="flex flex-wrap items-center justify-between gap-3">
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
        <div className="space-y-8">
          {featureGroups.map(([featureId, { feature, batches: fBatches }]) => {
            const collapsed = collapsedFeatures.has(featureId);
            const featureHref = `/features/${feature.slug ?? featureId}`;
            return (
              <div key={featureId} className="space-y-3">
                {/* Feature section header */}
                <div className="flex items-center justify-between gap-3 border-b border-gray-100 pb-2">
                  <div className="flex items-center gap-3">
                    <button
                      onClick={() => toggleFeature(featureId)}
                      className="text-gray-400 hover:text-gray-600"
                      aria-label={collapsed ? "Expand" : "Collapse"}
                    >
                      <svg
                        className={`h-4 w-4 transition-transform ${collapsed ? "-rotate-90" : ""}`}
                        viewBox="0 0 20 20" fill="currentColor"
                      >
                        <path fillRule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.17l3.71-3.94a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clipRule="evenodd" />
                      </svg>
                    </button>
                    <Link href={featureHref} className="text-base font-semibold text-gray-900 hover:text-blue-600">
                      {feature.name}
                    </Link>
                    {feature.status && <BetaStatusBadge status={feature.status} />}
                    <span className="text-xs text-gray-400">{fBatches.length} client{fBatches.length !== 1 ? "s" : ""}</span>
                  </div>
                  <button
                    onClick={() => triggerForFeature(featureId)}
                    className="rounded border border-gray-200 px-2.5 py-1 text-xs text-gray-600 hover:bg-gray-50"
                  >
                    Trigger
                  </button>
                </div>

                {/* Batch cards */}
                {!collapsed && (
                  <div className="space-y-3 pl-7">
                    {fBatches.map(batch => {
                      const { senderId, ccIds } = getEffective(batch);
                      const senderUser = users.find(u => u.id === senderId) ?? null;
                      return (
                        <BatchCard
                          key={batch.id}
                          batch={batch}
                          feature={feature}
                          users={users}
                          userLabelMap={userLabelMap}
                          patchedSenderId={senderId}
                          patchedCcIds={ccIds}
                          onSenderChange={id => handleSenderChange(batch.id, id)}
                          onCcChange={ids => handleCcChange(batch.id, ids)}
                          onOpenDraft={() => setDraftInfo({ batch, feature })}
                          onSend={() => sendBatch(batch.id)}
                        />
                      );
                    })}
                  </div>
                )}
              </div>
            );
          })}

          {/* Orphan batches (not linked to any feature) */}
          {orphanBatches.length > 0 && (
            <div className="space-y-3">
              <div className="flex items-center gap-3 border-b border-gray-100 pb-2">
                <p className="text-sm font-medium text-gray-400">Other batches</p>
              </div>
              <div className="space-y-3">
                {orphanBatches.map(batch => {
                  const featureNames = [...new Set(
                    (batch.enrollments ?? []).map(be => be.enrollment?.feature?.name).filter(Boolean)
                  )];
                  const { senderId, ccIds } = getEffective(batch);
                  const stale = batch.batchStatus !== "sent" && new Date(batch.createdAt) < new Date(Date.now() - 48 * 3600000);
                  return (
                    <div key={batch.id} className={`rounded-lg border bg-white p-4 space-y-2 ${stale ? "border-red-200" : "border-gray-200"}`}>
                      <div className="flex items-center justify-between gap-2">
                        <div className="flex items-center gap-2">
                          <HealthDot health={batch.client?.accountHealth ?? "green"} />
                          <p className="text-sm font-semibold text-gray-900">{batch.client?.name}</p>
                        </div>
                        <div className="flex items-center gap-2">
                          <BatchStatusBadge status={batch.batchStatus} />
                          {stale && <span className="text-xs text-red-600">Pending 48h+</span>}
                          {batch.batchStatus !== "sent" && (
                            <button onClick={() => sendBatch(batch.id)} className="rounded-lg bg-blue-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-blue-700">Send</button>
                          )}
                        </div>
                      </div>
                      <div className="flex flex-wrap gap-1.5">
                        {featureNames.map(n => (
                          <span key={n} className="rounded-full bg-gray-100 px-2.5 py-0.5 text-xs text-gray-600">{n}</span>
                        ))}
                      </div>
                      <p className="text-xs text-gray-400">Created {new Date(batch.createdAt).toLocaleDateString()}</p>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      )}

      {draftInfo && (
        <DraftModal
          batch={draftInfo.batch}
          feature={draftInfo.feature}
          sender={users.find(u => u.id === getEffective(draftInfo.batch).senderId) ?? null}
          onClose={() => setDraftInfo(null)}
        />
      )}
    </div>
  );
}
