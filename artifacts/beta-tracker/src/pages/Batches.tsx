import { useEffect, useMemo, useState } from "react";
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

// ─── Single-batch drawer ──────────────────────────────────────────────────────

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
      const senderName = sender?.name ?? "the team";
      const clientName = batch.client?.name ?? "the client";
      const csmFirstName = (batch.client?.csmOwner?.name ?? "").split(" ")[0];
      const contactName = batch.client?.primaryContactName ?? clientName;

      const prompt = `You are writing a beta invitation email from ${senderName} (${role.toUpperCase()}) at Birdeye to ${contactName} at ${clientName}.

The goal is to sound like a thoughtful colleague reaching out directly — not a marketing email, not a two-line text. Warm, specific, and human.

Guidelines:
- 100–180 words in the body (not counting sign-off)
- No corporate filler: avoid "I hope this finds you well", "leverage", "unparalleled", "excited to share", "innovative", "scale and sophistication", "invaluable"
- Use the contact's first name naturally
- Do NOT reference the client's size, scale, or sophistication — it sounds forced
- Feedback happens naturally during their regular CSM status calls — do not mention separate feedback sessions, surveys, or additional time commitment beyond using the feature
- Mention the CSM by first name naturally (e.g. "your CSM [first name] is looped in") so the client knows this is coordinated
- Be clear what participation involves: early access to the feature, sharing reactions during their regular CSM calls
- End with a soft, low-pressure CTA
- Sign off with just the sender's first name

Tone by role:
- PM: collegial and product-curious, mentions what we're trying to learn and how their feedback shapes what gets built
- CSM: warm and relationship-grounded, feels like it's coming from someone who knows the account
- AE: concise and opportunity-framed, emphasizes being early and the business value

Context:
- Feature name: ${feature.name}
- Feature description: ${feature.idealClientCriteria ?? ""}
- Ideal beta participant: ${feature.idealClientCriteria ?? ""}
- What we're trying to learn: ${feature.betaGoal || "not specified"}
- Client: ${clientName}
- Primary contact: ${contactName}
- Sender: ${senderName}, ${role.toUpperCase()}
- CSM first name: ${csmFirstName}

If a beta goal is provided, reference it specifically — mention what kind of feedback you're hoping to get. Make it feel like the sender genuinely cares about their specific input, not just participation in general.

Return only a JSON object with two fields: "subject" and "body". Subject should be specific and under 10 words. No markdown, no code blocks, raw JSON only.`;

      const resp = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${key}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: {
              maxOutputTokens: 8192,
              responseMimeType: "application/json",
              thinkingConfig: { thinkingBudget: 0 },
            },
          }),
        },
      );
      const data = await resp.json();
      console.log("Gemini raw response:", data);
      if (!resp.ok) throw new Error(data.error?.message ?? `Gemini error ${resp.status}`);

      const candidate = data.candidates?.[0];
      if (!candidate) throw new Error("No candidates in Gemini response.");
      if (candidate.finishReason === "MAX_TOKENS") throw new Error("Response was cut off — try again.");

      const parts: Array<{ text?: string; thought?: boolean }> = candidate.content?.parts ?? [];
      const outputPart = parts.find((p) => !p.thought) ?? parts[0];
      let text: string = outputPart?.text ?? "";
      text = text.replace(/^```(?:\w+)?\n?([\s\S]*?)\n?```$/m, "$1").trim();
      try {
        const parsed = JSON.parse(text);
        text = `Subject: ${parsed.subject}\n\n${parsed.body}`;
      } catch {
        // not JSON — use as-is
      }
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

    const ccUsers = patchedCcIds
      .map((id) => users.find((u) => u.id === id))
      .filter((u): u is NonNullable<typeof u> => !!u);
    const ccEmails = ccUsers.map((u) => u.email).join(",");

    console.log("Gmail CC debug:", {
      rawCcIds: patchedCcIds,
      resolvedUsers: ccUsers.map((u) => ({ id: u.id, name: u.name, email: u.email })),
      ccEmailString: ccEmails,
      toEmail: to,
    });

    const url = new URL("https://mail.google.com/mail/u/0/");
    url.searchParams.set("view", "cm");
    url.searchParams.set("fs", "1");
    if (to) url.searchParams.set("to", to);
    url.searchParams.set("su", subject);
    if (body) url.searchParams.set("body", body.slice(0, 1800));
    if (ccEmails) url.searchParams.set("cc", ccEmails);
    window.open(url.toString(), "_blank");
  }

  return (
    <div className="flex h-full flex-col">
      <div className="flex shrink-0 items-start justify-between gap-3 border-b border-gray-100 px-5 py-4">
        <div className="min-w-0">
          <p className="text-base font-medium text-gray-900 leading-snug">
            {batch.client?.name ?? "—"}
          </p>
          <p className="mt-0.5 text-xs text-gray-400">
            {batch.client?.segment ?? "—"} · {feature.name}
          </p>
        </div>
        <button
          onClick={onClose}
          className="shrink-0 rounded p-1 text-gray-400 hover:bg-gray-100 hover:text-gray-600"
          aria-label="Close"
        >
          <svg className="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
            <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
          </svg>
        </button>
      </div>

      <div className="flex-1 overflow-y-auto px-5 py-4 space-y-4">
        {showBanner && (
          <div className="rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-xs text-amber-700">
            {reminder
              ? `Last contacted ${daysSinceSent}d ago — reminder suggested`
              : `Pending ${Math.floor((Date.now() - new Date(batch.createdAt).getTime()) / 3_600_000)}h — action needed`}
          </div>
        )}

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

        <div className="space-y-1">
          <label className="text-xs font-medium uppercase tracking-wide text-gray-500">From</label>
          <select
            value={patchedSenderId ?? ""}
            onChange={(e) => onSenderChange(e.target.value || null)}
            className="w-full rounded-lg border border-gray-200 bg-white px-3 py-2 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-400"
          >
            <option value="">— select sender —</option>
            {assignedUsers.length > 0 && (
              <optgroup label="Assigned team">
                {assignedUsers.map((u) => (
                  <option key={u.id} value={u.id}>{userLabelMap[u.id] ?? u.name}</option>
                ))}
              </optgroup>
            )}
            {otherUsers.length > 0 && (
              <optgroup label="Others">
                {otherUsers.map((u) => (
                  <option key={u.id} value={u.id}>{userLabelMap[u.id] ?? u.name}</option>
                ))}
              </optgroup>
            )}
          </select>
        </div>

        <div className="space-y-1">
          <label className="text-xs font-medium uppercase tracking-wide text-gray-500">CC</label>
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

        <div className="space-y-2">
          {!draft && (
            <button
              onClick={generate}
              disabled={generating}
              className={`flex w-full items-center justify-center gap-2 rounded-lg border px-3 py-2 text-sm font-medium transition-colors ${
                generating
                  ? "cursor-not-allowed border-purple-100 bg-purple-50 text-purple-300"
                  : "border-purple-200 bg-white text-purple-700 hover:bg-purple-50"
              }`}
            >
              {generating ? (
                <>
                  <div className="h-3.5 w-3.5 animate-spin rounded-full border-2 border-purple-200 border-t-purple-400" />
                  Generating…
                </>
              ) : (
                <>
                  <svg className="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                    <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                  </svg>
                  Generate draft email
                </>
              )}
            </button>
          )}

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

        {draftError && (
          <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-700">
            {draftError}
          </div>
        )}

        {generating && (
          <div className="flex flex-col gap-2">
            <span className="text-xs font-medium uppercase tracking-wide text-gray-400">Draft</span>
            <div className="min-h-[240px] animate-pulse rounded-lg border border-gray-100 bg-gray-100" />
          </div>
        )}

        {draft && !generating && (
          <div className="flex flex-col gap-2">
            <div className="flex items-center justify-between">
              <span className="text-xs font-medium uppercase tracking-wide text-gray-400">Draft</span>
              <div className="flex items-center gap-3">
                <button onClick={copy} className="text-xs text-gray-500 hover:text-gray-700">
                  {copied ? "Copied!" : "Copy"}
                </button>
                <button
                  onClick={generate}
                  disabled={generating}
                  className="text-xs text-purple-600 hover:text-purple-700 disabled:cursor-not-allowed disabled:text-purple-300"
                >
                  Regenerate
                </button>
              </div>
            </div>
            <textarea
              className="min-h-[240px] w-full rounded-lg border border-gray-200 p-3 font-mono text-xs text-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
              value={draft}
              onChange={(e) => onDraftSaved(e.target.value)}
            />
          </div>
        )}
      </div>
    </div>
  );
}

// ─── Multi-batch drawer ───────────────────────────────────────────────────────

function MultiDetailPanel({
  client,
  batches,
  features,
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
  client: OutreachBatch["client"];
  batches: OutreachBatch[];
  features: BatchFeature[];
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

  const totalEnrolled = batches.reduce(
    (sum, b) => sum + (b.enrollments ?? []).filter((be) => be.enrollment?.feature != null).length,
    0,
  );
  const daysSinceOutreach = daysSince(client?.lastOutreachDate);

  const assignedUsers: User[] = [];
  const assignedIds = new Set<string>();
  function addAssigned(u: User | null | undefined) {
    if (u && !assignedIds.has(u.id)) { assignedIds.add(u.id); assignedUsers.push(u); }
  }
  for (const f of features) {
    addAssigned(f.ownerPm);
    addAssigned(f.ownerPmm);
  }
  addAssigned(client?.csmOwner);
  addAssigned((client as any)?.aeOwner);

  const otherUsers = users
    .filter((u) => !assignedIds.has(u.id))
    .sort((a, b) => {
      const lastA = a.name.split(" ").pop() ?? a.name;
      const lastB = b.name.split(" ").pop() ?? b.name;
      return lastA.localeCompare(lastB);
    });

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
      const senderName = sender?.name ?? "the team";
      const clientName = client?.name ?? "the client";
      const csmFirstName = (client?.csmOwner?.name ?? "").split(" ")[0];
      const contactName = client?.primaryContactName ?? clientName;

      const featureDetailsStr = features
        .map(
          (f, i) =>
            `${i + 1}. ${f.name}: ${f.idealClientCriteria || ""}. Goal: ${f.betaGoal || "not specified"}`,
        )
        .join("\n");

      const prompt = `You are writing a beta invitation email from ${senderName} (${role.toUpperCase()}) at Birdeye to ${contactName} at ${clientName}.

This client is being invited to ${features.length} beta program${features.length !== 1 ? "s" : ""}:
${featureDetailsStr}

Write a single email that naturally covers all of them. Do not list them mechanically — weave them together where they're related, or introduce them as a suite of initiatives. Keep the total email under 200 words.

Guidelines:
- No corporate filler: avoid "I hope this finds you well", "leverage", "unparalleled", "excited to share", "innovative", "scale and sophistication", "invaluable"
- Use the contact's first name naturally
- Do NOT reference the client's size, scale, or sophistication
- Feedback happens naturally during their regular CSM status calls — do not mention separate feedback sessions or surveys
- Mention the CSM by first name naturally (e.g. "your CSM [first name] is looped in")
- Be clear what participation involves: early access to the features, sharing reactions during CSM calls
- End with a soft, low-pressure CTA
- Sign off with just the sender's first name

Tone by role:
- PM: collegial and product-curious, mentions what we're trying to learn and how their feedback shapes what gets built
- CSM: warm and relationship-grounded
- AE: concise and opportunity-framed, emphasizes being early and the business value

Context:
- Client: ${clientName}
- Primary contact: ${contactName}
- Sender: ${senderName}, ${role.toUpperCase()}
- CSM first name: ${csmFirstName}

Return only a JSON object with two fields: "subject" and "body". Subject should be specific and under 10 words. No markdown, no code blocks, raw JSON only.`;

      console.log("[Multi-beta generate] batches:", batches.length, "features passed:", features.map(f => f.name), "\nPrompt:\n", prompt);

      const resp = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${key}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: {
              maxOutputTokens: 8192,
              responseMimeType: "application/json",
              thinkingConfig: { thinkingBudget: 0 },
            },
          }),
        },
      );
      const data = await resp.json();
      console.log("Gemini raw response (multi):", data);
      if (!resp.ok) throw new Error(data.error?.message ?? `Gemini error ${resp.status}`);

      const candidate = data.candidates?.[0];
      if (!candidate) throw new Error("No candidates in Gemini response.");
      if (candidate.finishReason === "MAX_TOKENS") throw new Error("Response was cut off — try again.");

      const parts: Array<{ text?: string; thought?: boolean }> = candidate.content?.parts ?? [];
      const outputPart = parts.find((p) => !p.thought) ?? parts[0];
      let text: string = outputPart?.text ?? "";
      text = text.replace(/^```(?:\w+)?\n?([\s\S]*?)\n?```$/m, "$1").trim();
      try {
        const parsed = JSON.parse(text);
        text = `Subject: ${parsed.subject}\n\n${parsed.body}`;
      } catch {
        // not JSON — use as-is
      }
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
      draft.match(/^Subject: (.+)$/m)?.[1] ?? `Beta Program Invitation`;
    const body = draft ? draft.replace(/^Subject: .+\r?\n\r?\n?/, "") : "";
    const to = client?.primaryContactEmail ?? "";
    const ccUsers = patchedCcIds
      .map((id) => users.find((u) => u.id === id))
      .filter((u): u is NonNullable<typeof u> => !!u);
    const ccEmails = ccUsers.map((u) => u.email).join(",");
    const url = new URL("https://mail.google.com/mail/u/0/");
    url.searchParams.set("view", "cm");
    url.searchParams.set("fs", "1");
    if (to) url.searchParams.set("to", to);
    url.searchParams.set("su", subject);
    if (body) url.searchParams.set("body", body.slice(0, 1800));
    if (ccEmails) url.searchParams.set("cc", ccEmails);
    window.open(url.toString(), "_blank");
  }

  return (
    <div className="flex h-full flex-col">
      <div className="flex shrink-0 items-start justify-between gap-3 border-b border-gray-100 px-5 py-4">
        <div className="min-w-0">
          <p className="text-base font-medium text-gray-900 leading-snug">{client?.name ?? "—"}</p>
          <p className="mt-0.5 text-xs text-gray-400">
            {client?.segment ?? "—"} · {features.length} beta{features.length !== 1 ? "s" : ""}
          </p>
        </div>
        <button
          onClick={onClose}
          className="shrink-0 rounded p-1 text-gray-400 hover:bg-gray-100 hover:text-gray-600"
          aria-label="Close"
        >
          <svg className="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
            <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
          </svg>
        </button>
      </div>

      <div className="flex-1 overflow-y-auto px-5 py-4 space-y-4">
        <div className="grid grid-cols-2 gap-2">
          <div className="rounded-lg bg-gray-50 px-3 py-2.5 text-center">
            <p className="text-xl font-semibold text-gray-900">{totalEnrolled}</p>
            <p className="text-[11px] text-gray-400">Total enrollments</p>
          </div>
          <div className="rounded-lg bg-gray-50 px-3 py-2.5 text-center">
            <p className="text-xl font-semibold text-gray-900">
              {daysSinceOutreach !== null ? `${daysSinceOutreach}d` : "—"}
            </p>
            <p className="text-[11px] text-gray-400">Since outreach</p>
          </div>
        </div>

        <div className="space-y-1.5">
          <p className="text-xs font-medium uppercase tracking-wide text-gray-500">Betas included</p>
          <div className="flex flex-wrap gap-1.5">
            {features.map((f) => (
              <span
                key={f.id}
                className="inline-flex items-center rounded-full border border-blue-200 bg-blue-50 px-2.5 py-1 text-xs font-medium text-blue-700"
              >
                {f.name}
              </span>
            ))}
          </div>
        </div>

        <div className="space-y-1">
          <label className="text-xs font-medium uppercase tracking-wide text-gray-500">From</label>
          <select
            value={patchedSenderId ?? ""}
            onChange={(e) => onSenderChange(e.target.value || null)}
            className="w-full rounded-lg border border-gray-200 bg-white px-3 py-2 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-400"
          >
            <option value="">— select sender —</option>
            {assignedUsers.length > 0 && (
              <optgroup label="Assigned team">
                {assignedUsers.map((u) => (
                  <option key={u.id} value={u.id}>{userLabelMap[u.id] ?? u.name}</option>
                ))}
              </optgroup>
            )}
            {otherUsers.length > 0 && (
              <optgroup label="Others">
                {otherUsers.map((u) => (
                  <option key={u.id} value={u.id}>{userLabelMap[u.id] ?? u.name}</option>
                ))}
              </optgroup>
            )}
          </select>
        </div>

        <div className="space-y-1">
          <label className="text-xs font-medium uppercase tracking-wide text-gray-500">CC</label>
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

        <div className="space-y-2">
          {!draft && (
            <button
              onClick={generate}
              disabled={generating}
              className={`flex w-full items-center justify-center gap-2 rounded-lg border px-3 py-2 text-sm font-medium transition-colors ${
                generating
                  ? "cursor-not-allowed border-purple-100 bg-purple-50 text-purple-300"
                  : "border-purple-200 bg-white text-purple-700 hover:bg-purple-50"
              }`}
            >
              {generating ? (
                <>
                  <div className="h-3.5 w-3.5 animate-spin rounded-full border-2 border-purple-200 border-t-purple-400" />
                  Generating…
                </>
              ) : (
                <>
                  <svg className="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                    <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                  </svg>
                  Generate combined draft
                </>
              )}
            </button>
          )}

          <button
            onClick={openGmail}
            className="flex w-full items-center justify-center gap-2 rounded-lg border border-blue-200 bg-white px-3 py-2 text-sm font-medium text-blue-700 hover:bg-blue-50 transition-colors"
          >
            <svg className="h-4 w-4" viewBox="0 0 24 24" fill="currentColor">
              <path d="M24 5.457v13.909c0 .904-.732 1.636-1.636 1.636h-3.819V11.73L12 16.64l-6.545-4.91v9.273H1.636A1.636 1.636 0 010 19.366V5.457c0-2.023 2.309-3.178 3.927-1.964L5.455 4.64 12 9.548l6.545-4.91 1.528-1.145C21.69 2.28 24 3.434 24 5.457z" />
            </svg>
            Open in Gmail
          </button>

          <button
            onClick={onSend}
            className="w-full rounded-lg bg-blue-600 px-3 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
          >
            Mark all as sent
          </button>
        </div>

        {draftError && (
          <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-700">
            {draftError}
          </div>
        )}

        {generating && (
          <div className="flex flex-col gap-2">
            <span className="text-xs font-medium uppercase tracking-wide text-gray-400">Draft</span>
            <div className="min-h-[240px] animate-pulse rounded-lg border border-gray-100 bg-gray-100" />
          </div>
        )}

        {draft && !generating && (
          <div className="flex flex-col gap-2">
            <div className="flex items-center justify-between">
              <span className="text-xs font-medium uppercase tracking-wide text-gray-400">Draft</span>
              <div className="flex items-center gap-3">
                <button onClick={copy} className="text-xs text-gray-500 hover:text-gray-700">
                  {copied ? "Copied!" : "Copy"}
                </button>
                <button
                  onClick={generate}
                  disabled={generating}
                  className="text-xs text-purple-600 hover:text-purple-700 disabled:cursor-not-allowed disabled:text-purple-300"
                >
                  Regenerate
                </button>
              </div>
            </div>
            <textarea
              className="min-h-[240px] w-full rounded-lg border border-gray-200 p-3 font-mono text-xs text-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
              value={draft}
              onChange={(e) => onDraftSaved(e.target.value)}
            />
          </div>
        )}
      </div>
    </div>
  );
}

// ─── Main page ────────────────────────────────────────────────────────────────

type SelectedInfo = { batchId: string; featureId: string };

const SEGMENT_ORDER = ["Enterprise", "Strategic", "Commercial", "Professional", "Channel"];

export default function BatchesPage() {
  const [batches, setBatches] = useState<OutreachBatch[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [initialLoad, setInitialLoad] = useState(true);
  const [loading, setLoading] = useState(false);
  const [patches, setPatches] = useState<Record<string, { senderId: string | null; ccIds: string[] }>>({});
  const [collapsedFeatures, setCollapsedFeatures] = useState<Set<string>>(new Set());
  const [selected, setSelected] = useState<SelectedInfo | null>(null);
  const [selectedClientId, setSelectedClientId] = useState<string | null>(null);
  const [drafts, setDrafts] = useState<Record<string, string>>({});
  const [toast, setToast] = useState<string | null>(null);
  const [view, setView] = useState<"feature" | "client">(() => {
    const saved = localStorage.getItem("outreach-view");
    return saved === "client" ? "client" : "feature";
  });

  function showToast(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(null), 3500);
  }

  function setViewAndPersist(v: "feature" | "client") {
    setView(v);
    localStorage.setItem("outreach-view", v);
    setSelected(null);
    setSelectedClientId(null);
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
      setInitialLoad(false);
    }
  }

  useEffect(() => { load(); }, []);

  useEffect(() => {
    function handleKey(e: KeyboardEvent) {
      if (e.key === "Escape") {
        setSelected(null);
        setSelectedClientId(null);
      }
    }
    document.addEventListener("keydown", handleKey);
    return () => document.removeEventListener("keydown", handleKey);
  }, []);

  const userLabelMap = useMemo(
    () => Object.fromEntries(users.map((u) => [u.id, `${u.name} (${u.role.toUpperCase()})`])),
    [users],
  );

  // ─── By-feature grouping ───────────────────────────────────────────────────

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

  const linkedBatchIds = useMemo(
    () => new Set(featureGroups.flatMap(([, g]) => g.batches.map((b) => b.id))),
    [featureGroups],
  );
  const orphanBatches = useMemo(
    () => batches.filter((b) => !linkedBatchIds.has(b.id)),
    [batches, linkedBatchIds],
  );

  // ─── By-client grouping ────────────────────────────────────────────────────

  const clientData = useMemo(() => {
    const map = new Map<string, { client: OutreachBatch["client"]; batches: OutreachBatch[]; pendingBatches: OutreachBatch[] }>();
    for (const batch of batches) {
      const cid = batch.clientId;
      if (!map.has(cid)) map.set(cid, { client: batch.client, batches: [], pendingBatches: [] });
      const entry = map.get(cid)!;
      entry.batches.push(batch);
      if (batch.batchStatus !== "sent") entry.pendingBatches.push(batch);
    }
    return map;
  }, [batches]);

  const clientSegmentGroups = useMemo(() => {
    const bySegment = new Map<string, Array<{ clientId: string; client: OutreachBatch["client"]; batches: OutreachBatch[]; pendingBatches: OutreachBatch[] }>>();
    for (const [clientId, data] of clientData) {
      const seg = data.client?.segment ?? "Other";
      if (!bySegment.has(seg)) bySegment.set(seg, []);
      bySegment.get(seg)!.push({ clientId, ...data });
    }
    for (const [, clients] of bySegment) {
      clients.sort((a, b) => {
        const diff = b.pendingBatches.length - a.pendingBatches.length;
        if (diff !== 0) return diff;
        return (a.client?.name ?? "").localeCompare(b.client?.name ?? "");
      });
    }
    return [...bySegment.entries()].sort(([a], [b]) => {
      const ia = SEGMENT_ORDER.indexOf(a);
      const ib = SEGMENT_ORDER.indexOf(b);
      if (ia === -1 && ib === -1) return a.localeCompare(b);
      if (ia === -1) return 1;
      if (ib === -1) return -1;
      return ia - ib;
    });
  }, [clientData]);

  // Count of pending batches per client — used for "N betas" badge in feature view
  const clientPendingCounts = useMemo(() => {
    const counts = new Map<string, number>();
    for (const [cid, data] of clientData) {
      counts.set(cid, data.pendingBatches.length);
    }
    return counts;
  }, [clientData]);

  // ─── Drawer derived state ──────────────────────────────────────────────────

  function getEffective(b: OutreachBatch) {
    return patches[b.id] ?? { senderId: b.senderId ?? null, ccIds: b.ccIds ?? [] };
  }

  const selectedBatch = selected ? batches.find((b) => b.id === selected.batchId) ?? null : null;
  const selectedFeature = selected
    ? featureGroups.find(([fid]) => fid === selected.featureId)?.[1].feature ?? null
    : null;

  // Client view drawer state
  const clientDrawerData = selectedClientId ? (clientData.get(selectedClientId) ?? null) : null;
  const clientDrawerPendingBatches = clientDrawerData?.pendingBatches ?? [];
  // Primary batch: first pending, fallback to first overall (for all-sent clients)
  const clientDrawerPrimaryBatch =
    clientDrawerPendingBatches[0] ?? clientDrawerData?.batches[0] ?? null;
  // Unique features across all pending batches — one batch can contain many features
  const clientDrawerFeatures = useMemo(() => {
    const map = new Map<string, BatchFeature>();
    for (const b of clientDrawerPendingBatches) {
      for (const be of b.enrollments ?? []) {
        const f = be.enrollment?.feature;
        if (f && !map.has(f.id)) map.set(f.id, f as BatchFeature);
      }
    }
    return [...map.values()];
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedClientId, batches]);
  // Multi = 2+ distinct features (all may live in a single batch — triggerBatching merges them)
  const clientDrawerIsMulti = clientDrawerFeatures.length > 1;
  // Single-beta: first feature found in the primary batch
  const clientDrawerSingleFeature: BatchFeature | null =
    clientDrawerPrimaryBatch?.enrollments?.find((be) => be.enrollment?.feature != null)
      ?.enrollment?.feature as BatchFeature | null ?? null;

  const featureDrawerOpen = !!(selected && selectedBatch && selectedFeature);
  const clientDrawerOpen =
    view === "client" && !!selectedClientId && !!clientDrawerData;
  const drawerOpen = featureDrawerOpen || clientDrawerOpen;

  // Multi-beta draft keyed by client ID so it's separate from per-batch drafts
  function getClientDraftKey(clientId: string) { return `client:${clientId}`; }

  // ─── Handlers ─────────────────────────────────────────────────────────────

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

  async function handleMultiSenderChange(pendingBatches: OutreachBatch[], senderId: string | null) {
    if (pendingBatches.length === 0) return;
    const ccIds = getEffective(pendingBatches[0]).ccIds.filter((id) => id !== senderId);
    setPatches((p) => {
      const next = { ...p };
      for (const b of pendingBatches) next[b.id] = { senderId, ccIds };
      return next;
    });
    try {
      await Promise.all(pendingBatches.map((b) => api.batches.update(b.id, { senderId, ccIds })));
    } catch {
      setPatches((p) => {
        const next = { ...p };
        for (const b of pendingBatches) delete next[b.id];
        return next;
      });
      showToast("Failed to save sender.");
    }
  }

  async function handleMultiCcChange(pendingBatches: OutreachBatch[], ccIds: string[]) {
    if (pendingBatches.length === 0) return;
    const prev = getEffective(pendingBatches[0]);
    setPatches((p) => {
      const next = { ...p };
      for (const b of pendingBatches) next[b.id] = { ...prev, ccIds };
      return next;
    });
    try {
      await Promise.all(pendingBatches.map((b) => api.batches.update(b.id, { ccIds })));
    } catch {
      setPatches((p) => {
        const next = { ...p };
        for (const b of pendingBatches) delete next[b.id];
        return next;
      });
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

  async function sendClientBatches(pendingBatches: OutreachBatch[]) {
    try {
      for (let i = 0; i < pendingBatches.length; i++) {
        // After the first send, lastOutreachDate is "now", so subsequent sends must override cooldown
        const overrideCooldown = i > 0;
        try {
          await api.batches.send(pendingBatches[i].id, { overrideCooldown });
        } catch (e: any) {
          const errData = (e as any).data ?? {};
          if (errData.cooldown && i === 0) {
            const go = confirm(`${errData.error}\n\nOverride cooldown and send anyway?`);
            if (!go) return;
            await api.batches.send(pendingBatches[i].id, { overrideCooldown: true });
          } else {
            throw e;
          }
        }
      }
      await load();
      showToast(
        pendingBatches.length > 1
          ? `${pendingBatches.length} batches marked as sent.`
          : "Batch marked as sent.",
      );
    } catch (e: any) {
      alert((e as any).data?.error ?? "Failed");
    }
  }

  function toggleFeature(fid: string) {
    setCollapsedFeatures((prev) => {
      const next = new Set(prev);
      next.has(fid) ? next.delete(fid) : next.add(fid);
      return next;
    });
  }

  function closeDrawer() {
    setSelected(null);
    setSelectedClientId(null);
  }

  if (initialLoad) {
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

      {/* View toggle */}
      <div className="inline-flex items-center rounded-lg border border-gray-200 bg-gray-100 p-0.5">
        <button
          onClick={() => setViewAndPersist("feature")}
          className={`rounded-md px-3 py-1.5 text-xs font-medium transition-all ${
            view === "feature" ? "bg-white text-gray-900 shadow-sm" : "text-gray-500 hover:text-gray-700"
          }`}
        >
          By feature
        </button>
        <button
          onClick={() => setViewAndPersist("client")}
          className={`rounded-md px-3 py-1.5 text-xs font-medium transition-all ${
            view === "client" ? "bg-white text-gray-900 shadow-sm" : "text-gray-500 hover:text-gray-700"
          }`}
        >
          By client
        </button>
      </div>

      {batches.length === 0 ? (
        <div className="rounded-xl border border-gray-200 bg-white py-16 text-center">
          <p className="text-lg text-gray-400">No batches yet.</p>
          <p className="mt-1 text-sm text-gray-300">
            Trigger batch grouping to create batches from approved enrollments.
          </p>
        </div>
      ) : view === "feature" ? (
        // ─── By feature view ───────────────────────────────────────────────
        <div className="space-y-6">
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
                      className="text-sm font-medium text-gray-900 hover:text-blue-600"
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
                      // Show purple "N betas" badge if this client has multiple pending batches
                      const pendingCount = clientPendingCounts.get(batch.clientId) ?? 0;
                      const showMultiBetaBadge =
                        batch.batchStatus !== "sent" && pendingCount >= 2;

                      return (
                        <button
                          key={batch.id}
                          onClick={() =>
                            setSelected(isSelected ? null : { batchId: batch.id, featureId })
                          }
                          className={`w-full rounded-lg border bg-white px-3 py-2.5 text-left transition-colors hover:bg-gray-50 ${
                            isSelected
                              ? "border-blue-400 bg-blue-50/40 shadow-sm"
                              : "border-gray-200"
                          }`}
                        >
                          <div className="flex items-center justify-between gap-2">
                            <div className="flex min-w-0 items-center gap-1.5">
                              <HealthDot health={batch.client?.accountHealth ?? "green"} />
                              <span className="text-sm font-medium text-gray-900">
                                {batch.client?.name ?? "—"}
                              </span>
                            </div>
                            {showMultiBetaBadge ? (
                              <span className="inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-medium bg-blue-100 text-blue-700">
                                {pendingCount} betas
                              </span>
                            ) : (
                              <CardBadge batch={batch} />
                            )}
                          </div>
                          <p className="mt-0.5 text-xs text-gray-400">
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
                  const isSelected = selected?.batchId === batch.id && selected?.featureId === "";
                  return (
                    <button
                      key={batch.id}
                      onClick={() =>
                        setSelected(isSelected ? null : { batchId: batch.id, featureId: "" })
                      }
                      className={`w-full rounded-lg border bg-white px-3 py-2.5 text-left transition-colors hover:bg-gray-50 ${
                        isSelected ? "border-blue-400 bg-blue-50/40 shadow-sm" : "border-gray-200"
                      }`}
                    >
                      <div className="flex items-center justify-between gap-2">
                        <div className="flex min-w-0 items-center gap-1.5">
                          <HealthDot health={batch.client?.accountHealth ?? "green"} />
                          <span className="text-sm font-medium text-gray-900">
                            {batch.client?.name ?? "—"}
                          </span>
                        </div>
                        <CardBadge batch={batch} />
                      </div>
                      <p className="mt-0.5 text-xs text-gray-400">
                        Created {new Date(batch.createdAt).toLocaleDateString()}
                      </p>
                    </button>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      ) : (
        // ─── By client view ────────────────────────────────────────────────
        <div className="space-y-6">
          <div className="rounded-lg border border-blue-200 bg-blue-50 px-4 py-2.5 text-sm text-blue-700">
            Clients enrolled in multiple betas are highlighted — select them to send a single combined email.
          </div>

          {clientSegmentGroups.map(([segment, clients]) => (
            <div key={segment}>
              <div className="mb-2 border-b border-gray-100 pb-2">
                <p className="text-xs font-medium uppercase tracking-wide text-gray-500">
                  {segment}
                </p>
              </div>
              <div className="space-y-1.5">
                {clients.map(({ clientId, client, batches: cBatches, pendingBatches }) => {
                  const isSelected = selectedClientId === clientId;
                  const daysSinceOut = daysSince(client?.lastOutreachDate);
                  const totalEnrolled = pendingBatches.reduce(
                    (sum, b) =>
                      sum +
                      (b.enrollments ?? []).filter((be) => be.enrollment?.feature != null).length,
                    0,
                  );
                  // Unique features across pending batches — must compute before isMulti
                  const pendingFeatureMap = new Map<string, BatchFeature>();
                  for (const b of pendingBatches) {
                    for (const be of b.enrollments ?? []) {
                      const f = be.enrollment?.feature;
                      if (f && !pendingFeatureMap.has(f.id))
                        pendingFeatureMap.set(f.id, f as BatchFeature);
                    }
                  }
                  const pendingFeatures = [...pendingFeatureMap.values()];
                  // Multi means 2+ distinct features across pending batches (all may be in one batch)
                  const isMulti = pendingFeatureMap.size > 1;

                  return (
                    <button
                      key={clientId}
                      onClick={() => setSelectedClientId(isSelected ? null : clientId)}
                      className={`w-full rounded-lg border bg-white px-3 py-2.5 text-left transition-colors hover:bg-gray-50 ${
                        isSelected
                          ? "border-blue-400 bg-blue-50/40 shadow-sm"
                          : "border-gray-200"
                      }`}
                    >
                      <div className="flex items-center justify-between gap-2">
                        <div className="flex min-w-0 items-center gap-1.5">
                          <HealthDot health={client?.accountHealth ?? "green"} />
                          <span className="text-sm font-medium text-gray-900">
                            {client?.name ?? "—"}
                          </span>
                        </div>
                        {isMulti ? (
                          <span className="inline-flex shrink-0 items-center rounded-full px-2 py-0.5 text-[10px] font-medium bg-blue-100 text-blue-700">
                            {pendingFeatureMap.size} betas · combine
                          </span>
                        ) : pendingBatches.length >= 1 ? (
                          <span className="inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-medium bg-green-100 text-green-700">
                            Ready
                          </span>
                        ) : (
                          <CardBadge batch={cBatches[0]} />
                        )}
                      </div>

                      {pendingFeatures.length > 0 && (
                        <div className="mt-1.5 flex flex-wrap gap-1">
                          {pendingFeatures.map((f) => (
                            <span
                              key={f.id}
                              className="rounded-full border border-blue-100 bg-blue-50 px-2 py-0.5 text-[10px] font-medium text-blue-700"
                            >
                              {f.name}
                            </span>
                          ))}
                        </div>
                      )}

                      <p className="mt-1 text-xs text-gray-400">
                        {[
                          totalEnrolled > 0 ? `${totalEnrolled} enrolled` : null,
                          daysSinceOut !== null
                            ? `${daysSinceOut}d since outreach`
                            : "no prior outreach",
                        ]
                          .filter(Boolean)
                          .join(" · ")}
                      </p>
                    </button>
                  );
                })}
              </div>
            </div>
          ))}

          {clientSegmentGroups.length === 0 && (
            <div className="rounded-xl border border-gray-200 bg-white py-16 text-center">
              <p className="text-lg text-gray-400">No batches yet.</p>
            </div>
          )}
        </div>
      )}

      {/* Backdrop */}
      <div
        onClick={closeDrawer}
        className="fixed inset-0 z-40 transition-opacity duration-200"
        style={{
          backgroundColor: "rgba(0,0,0,0.15)",
          opacity: drawerOpen ? 1 : 0,
          pointerEvents: drawerOpen ? "auto" : "none",
        }}
      />

      {/* Slide-over drawer */}
      <div
        className="fixed inset-y-0 right-0 z-50 flex w-[600px] flex-col overflow-hidden bg-white shadow-xl transition-transform duration-200 ease-out"
        style={{ transform: drawerOpen ? "translateX(0)" : "translateX(100%)" }}
      >
        {/* Feature view — single batch */}
        {view === "feature" && selectedBatch && selectedFeature && (
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
            onDraftSaved={(text) =>
              setDrafts((prev) => ({ ...prev, [selectedBatch.id]: text }))
            }
            onSend={() => sendBatch(selectedBatch.id)}
            onClose={closeDrawer}
          />
        )}

        {/* Client view — single pending batch */}
        {view === "client" &&
          selectedClientId &&
          clientDrawerData &&
          !clientDrawerIsMulti &&
          clientDrawerPrimaryBatch &&
          clientDrawerSingleFeature && (
            <DetailPanel
              batch={clientDrawerPrimaryBatch}
              feature={clientDrawerSingleFeature}
              users={users}
              userLabelMap={userLabelMap}
              patchedSenderId={getEffective(clientDrawerPrimaryBatch).senderId}
              patchedCcIds={getEffective(clientDrawerPrimaryBatch).ccIds}
              draft={drafts[clientDrawerPrimaryBatch.id] ?? ""}
              onSenderChange={(id) => handleSenderChange(clientDrawerPrimaryBatch.id, id)}
              onCcChange={(ids) => handleCcChange(clientDrawerPrimaryBatch.id, ids)}
              onDraftSaved={(text) =>
                setDrafts((prev) => ({ ...prev, [clientDrawerPrimaryBatch.id]: text }))
              }
              onSend={() => sendBatch(clientDrawerPrimaryBatch.id)}
              onClose={closeDrawer}
            />
          )}

        {/* Client view — multiple pending batches */}
        {view === "client" &&
          selectedClientId &&
          clientDrawerData &&
          clientDrawerIsMulti && (
            <MultiDetailPanel
              client={clientDrawerData.client}
              batches={clientDrawerPendingBatches}
              features={clientDrawerFeatures}
              users={users}
              userLabelMap={userLabelMap}
              patchedSenderId={
                clientDrawerPendingBatches[0]
                  ? getEffective(clientDrawerPendingBatches[0]).senderId
                  : null
              }
              patchedCcIds={
                clientDrawerPendingBatches[0]
                  ? getEffective(clientDrawerPendingBatches[0]).ccIds
                  : []
              }
              draft={drafts[getClientDraftKey(selectedClientId)] ?? ""}
              onSenderChange={(id) =>
                handleMultiSenderChange(clientDrawerPendingBatches, id)
              }
              onCcChange={(ids) => handleMultiCcChange(clientDrawerPendingBatches, ids)}
              onDraftSaved={(text) =>
                setDrafts((prev) => ({
                  ...prev,
                  [getClientDraftKey(selectedClientId)]: text,
                }))
              }
              onSend={() => sendClientBatches(clientDrawerPendingBatches)}
              onClose={closeDrawer}
            />
          )}
      </div>
    </div>
  );
}
