import { useState, useEffect } from "react";
import { api } from "@/lib/api";

type Sentiment = "positive" | "neutral" | "negative";

interface FeedbackItem {
  sentiment: Sentiment;
  notes: string;
  is_blocking_request: boolean;
  gating_description: string;
}

interface Testimonial {
  quote: string;
  context: string;
  approved: boolean;
}

const SENTIMENT_LABELS: Record<Sentiment, string> = {
  positive: "Positive",
  neutral:  "Neutral",
  negative: "Negative",
};

const SENTIMENT_ACTIVE: Record<Sentiment, string> = {
  positive: "bg-green-100 text-green-700",
  neutral:  "bg-gray-100 text-gray-600",
  negative: "bg-red-100 text-red-700",
};

export function TranscriptImportModal({
  defaultClientId,
  defaultClientName,
  defaultFeatureId,
  defaultFeatureName,
  onClose,
  onSaved,
}: {
  defaultClientId?: string;
  defaultClientName?: string;
  defaultFeatureId?: string;
  defaultFeatureName?: string;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [screen, setScreen] = useState<"input" | "review">("input");

  const [clientId, setClientId]   = useState(defaultClientId ?? "");
  const [featureId, setFeatureId] = useState(defaultFeatureId ?? "");
  const [callDate, setCallDate]   = useState(new Date().toISOString().slice(0, 10));
  const [transcript, setTranscript] = useState("");
  const [analyzing, setAnalyzing]   = useState(false);
  const [analyzeError, setAnalyzeError] = useState("");

  const [clients, setClients]   = useState<any[]>([]);
  const [features, setFeatures] = useState<any[]>([]);

  const [summary, setSummary]             = useState("");
  const [feedbackItems, setFeedbackItems] = useState<FeedbackItem[]>([]);
  const [testimonials, setTestimonials]   = useState<Testimonial[]>([]);
  const [saving, setSaving]               = useState(false);
  const [saveError, setSaveError]         = useState("");

  useEffect(() => {
    api.clients.list({ limit: "500" }).then((d: any) => setClients(d.clients ?? [])).catch(() => {});
    api.features.list({ limit: "200" }).then((d: any) => setFeatures(d.features ?? [])).catch(() => {});
  }, []);

  async function analyze() {
    if (!clientId || !featureId || !transcript.trim()) {
      setAnalyzeError("Select a client, feature, and paste a transcript.");
      return;
    }
    setAnalyzeError("");
    setAnalyzing(true);

    const featureName = defaultFeatureName ?? features.find((f) => f.id === featureId)?.name ?? "";
    const clientName  = defaultClientName  ?? clients.find((c) => c.id === clientId)?.name ?? "";

    const prompt = `You are analyzing a customer call transcript for a software beta program.

Beta feature: "${featureName}"
Customer: "${clientName}"

Extract structured feedback from the following transcript. Return a JSON object with exactly these fields:
- overall_sentiment: "positive", "neutral", or "negative"
- summary: A concise 1-2 sentence summary of the customer's overall feedback
- feedback_items: Array of discrete feedback points, each with:
  - sentiment: "positive", "neutral", or "negative"
  - notes: The specific feedback point (1-2 sentences, in third person)
  - is_blocking_request: true only if this is a feature gap blocking the customer from fully adopting the beta
  - gating_description: Short description of the blocker (required if is_blocking_request is true, otherwise null)
- testimonials: Positive quotes suitable for use as testimonials (verbatim from the transcript), each with:
  - quote: The exact verbatim quote
  - context: One sentence of context (who said it, the situation)

Only include testimonials that are genuinely positive and quotable. Return an empty array if none qualify.

Transcript:
${transcript}`;

    try {
      const key = import.meta.env.VITE_GEMINI_API_KEY;
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
        }
      );
      if (!resp.ok) throw new Error("Gemini API error");
      const geminiData = await resp.json();
      const rawText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text ?? "{}";
      const parsed = JSON.parse(rawText);

      setSummary(parsed.summary ?? "");
      setFeedbackItems(
        (parsed.feedback_items ?? []).map((item: any) => ({
          sentiment:           (item.sentiment ?? "neutral") as Sentiment,
          notes:               item.notes ?? "",
          is_blocking_request: item.is_blocking_request === true,
          gating_description:  item.gating_description ?? "",
        }))
      );
      setTestimonials(
        (parsed.testimonials ?? []).map((t: any) => ({
          quote:    t.quote ?? "",
          context:  t.context ?? "",
          approved: false,
        }))
      );
      setScreen("review");
    } catch {
      setAnalyzeError("Failed to analyze transcript. Check the API key and try again.");
    } finally {
      setAnalyzing(false);
    }
  }

  function updateFeedbackItem(idx: number, patch: Partial<FeedbackItem>) {
    setFeedbackItems((prev) => prev.map((item, i) => i === idx ? { ...item, ...patch } : item));
  }

  function removeFeedbackItem(idx: number) {
    setFeedbackItems((prev) => prev.filter((_, i) => i !== idx));
  }

  function addFeedbackItem() {
    setFeedbackItems((prev) => [...prev, { sentiment: "neutral", notes: "", is_blocking_request: false, gating_description: "" }]);
  }

  function updateTestimonial(idx: number, patch: Partial<Testimonial>) {
    setTestimonials((prev) => prev.map((t, i) => i === idx ? { ...t, ...patch } : t));
  }

  function removeTestimonial(idx: number) {
    setTestimonials((prev) => prev.filter((_, i) => i !== idx));
  }

  async function saveAll() {
    setSaving(true);
    setSaveError("");
    try {
      for (const item of feedbackItems) {
        if (!item.notes.trim()) continue;
        await api.feedback.create({
          clientId,
          featureId,
          sentiment: item.sentiment,
          notes: item.notes.trim(),
          isGatingRequest: item.is_blocking_request,
          gatingDescription: item.is_blocking_request ? (item.gating_description.trim() || null) : null,
        });
      }
      for (const t of testimonials) {
        if (!t.quote.trim()) continue;
        await api.testimonials.create({
          clientId,
          featureId,
          quote:    t.quote.trim(),
          context:  t.context.trim() || null,
          approved: t.approved,
          callDate: callDate || null,
        });
      }
      onSaved();
      onClose();
    } catch (e: any) {
      setSaveError(e?.data?.error ?? "Failed to save. Please try again.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-2xl rounded-xl bg-white shadow-xl flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 shrink-0">
          <h2 className="text-base font-semibold text-gray-900">
            {screen === "input" ? "Import from transcript" : "Review extracted feedback"}
          </h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600">
            <svg className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
            </svg>
          </button>
        </div>

        {/* Body */}
        <div className="overflow-y-auto flex-1 px-6 py-5 space-y-4">
          {screen === "input" ? (
            <>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-1">Client <span className="text-red-500">*</span></label>
                  {defaultClientId && defaultClientName ? (
                    <div className="w-full rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-sm text-gray-700">
                      {defaultClientName}
                    </div>
                  ) : (
                    <select
                      value={clientId}
                      onChange={(e) => setClientId(e.target.value)}
                      className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm bg-white outline-none focus:border-blue-400"
                    >
                      <option value="">Select client…</option>
                      {clients.map((c: any) => (
                        <option key={c.id} value={c.id}>{c.name}</option>
                      ))}
                    </select>
                  )}
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-1">Feature <span className="text-red-500">*</span></label>
                  {defaultFeatureId && defaultFeatureName ? (
                    <div className="w-full rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-sm text-gray-700">
                      {defaultFeatureName}
                    </div>
                  ) : (
                    <select
                      value={featureId}
                      onChange={(e) => setFeatureId(e.target.value)}
                      className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm bg-white outline-none focus:border-blue-400"
                    >
                      <option value="">Select feature…</option>
                      {features.map((f: any) => (
                        <option key={f.id} value={f.id}>{f.name}</option>
                      ))}
                    </select>
                  )}
                </div>
              </div>
              <div className="w-40">
                <label className="block text-xs font-medium text-gray-500 mb-1">Call date</label>
                <input
                  type="date"
                  value={callDate}
                  onChange={(e) => setCallDate(e.target.value)}
                  className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-blue-400"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1">Transcript <span className="text-red-500">*</span></label>
                <textarea
                  value={transcript}
                  onChange={(e) => setTranscript(e.target.value)}
                  rows={10}
                  placeholder="Paste the Zoom call transcript here…"
                  className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm resize-none outline-none focus:border-blue-400 font-mono"
                />
              </div>
              {analyzeError && <p className="text-sm text-red-600">{analyzeError}</p>}
            </>
          ) : (
            <>
              {/* Summary */}
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1">Summary</label>
                <textarea
                  value={summary}
                  onChange={(e) => setSummary(e.target.value)}
                  rows={3}
                  className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm resize-none outline-none focus:border-blue-400"
                />
              </div>

              {/* Feedback items */}
              <div>
                <div className="flex items-center justify-between mb-2">
                  <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">Feedback items ({feedbackItems.length})</p>
                  <button
                    onClick={addFeedbackItem}
                    className="text-xs font-medium text-blue-600 hover:text-blue-800"
                  >
                    + Add item
                  </button>
                </div>
                {feedbackItems.length === 0 && (
                  <p className="text-xs text-gray-400 py-2">No feedback items extracted.</p>
                )}
                <div className="space-y-3">
                  {feedbackItems.map((item, idx) => (
                    <div key={idx} className="rounded-lg border border-gray-200 p-3 space-y-2">
                      <div className="flex items-center justify-between">
                        <div className="flex overflow-hidden rounded border border-gray-200">
                          {(["positive", "neutral", "negative"] as const).map((s) => (
                            <button
                              key={s}
                              type="button"
                              onClick={() => updateFeedbackItem(idx, { sentiment: s })}
                              className={`px-2.5 py-1 text-xs font-medium transition-colors ${item.sentiment === s ? SENTIMENT_ACTIVE[s] : "text-gray-400 hover:bg-gray-50"}`}
                            >
                              {SENTIMENT_LABELS[s]}
                            </button>
                          ))}
                        </div>
                        <button
                          onClick={() => removeFeedbackItem(idx)}
                          className="text-gray-300 hover:text-red-500 text-xs"
                        >
                          Remove
                        </button>
                      </div>
                      <textarea
                        value={item.notes}
                        onChange={(e) => updateFeedbackItem(idx, { notes: e.target.value })}
                        rows={2}
                        placeholder="Feedback notes…"
                        className="w-full rounded border border-gray-200 px-2 py-1.5 text-xs resize-none outline-none focus:border-blue-300"
                      />
                      <label className="flex items-center gap-1.5 cursor-pointer">
                        <input
                          type="checkbox"
                          checked={item.is_blocking_request}
                          onChange={(e) => updateFeedbackItem(idx, { is_blocking_request: e.target.checked })}
                          className="rounded border-gray-300 text-red-600 focus:ring-red-500"
                        />
                        <span className="text-xs text-gray-600">Blocking feature request</span>
                      </label>
                      {item.is_blocking_request && (
                        <textarea
                          value={item.gating_description}
                          onChange={(e) => updateFeedbackItem(idx, { gating_description: e.target.value })}
                          rows={2}
                          placeholder="Describe the blocking feature request…"
                          className="w-full rounded border border-gray-200 px-2 py-1.5 text-xs resize-none outline-none focus:border-blue-300"
                        />
                      )}
                    </div>
                  ))}
                </div>
              </div>

              {/* Testimonials */}
              {testimonials.length > 0 && (
                <div>
                  <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">Testimonials ({testimonials.length})</p>
                  <div className="space-y-3">
                    {testimonials.map((t, idx) => (
                      <div key={idx} className="rounded-lg border border-gray-200 p-3 space-y-2">
                        <div className="flex items-start gap-2">
                          <blockquote className="flex-1 text-sm italic text-gray-700 leading-relaxed">"{t.quote}"</blockquote>
                          <button
                            onClick={() => removeTestimonial(idx)}
                            className="shrink-0 text-gray-300 hover:text-red-500 text-xs mt-0.5"
                          >
                            Remove
                          </button>
                        </div>
                        <textarea
                          value={t.context}
                          onChange={(e) => updateTestimonial(idx, { context: e.target.value })}
                          rows={1}
                          placeholder="Context…"
                          className="w-full rounded border border-gray-200 px-2 py-1.5 text-xs resize-none outline-none focus:border-blue-300"
                        />
                        <div className="flex items-center justify-between">
                          <label className="flex items-center gap-1.5 cursor-pointer">
                            <input
                              type="checkbox"
                              checked={t.approved}
                              onChange={(e) => updateTestimonial(idx, { approved: e.target.checked })}
                              className="rounded border-gray-300 text-green-600 focus:ring-green-500"
                            />
                            <span className="text-xs text-gray-600">Approved for use</span>
                          </label>
                          <button
                            onClick={() => navigator.clipboard.writeText(t.quote)}
                            className="text-xs text-gray-400 hover:text-blue-600"
                          >
                            Copy quote
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {saveError && <p className="text-sm text-red-600">{saveError}</p>}
            </>
          )}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-between border-t border-gray-100 px-6 py-4 shrink-0">
          {screen === "input" ? (
            <>
              <button
                onClick={onClose}
                disabled={analyzing}
                className="rounded-lg border border-gray-200 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 disabled:opacity-50"
              >
                Cancel
              </button>
              <button
                onClick={analyze}
                disabled={analyzing}
                className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50 flex items-center gap-2"
              >
                {analyzing && (
                  <svg className="h-4 w-4 animate-spin" viewBox="0 0 24 24" fill="none">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
                  </svg>
                )}
                {analyzing ? "Analyzing…" : "Analyze transcript"}
              </button>
            </>
          ) : (
            <>
              <button
                onClick={() => setScreen("input")}
                disabled={saving}
                className="rounded-lg border border-gray-200 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 disabled:opacity-50"
              >
                Re-analyze
              </button>
              <div className="flex items-center gap-3">
                <button
                  onClick={onClose}
                  disabled={saving}
                  className="rounded-lg border border-gray-200 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 disabled:opacity-50"
                >
                  Cancel
                </button>
                <button
                  onClick={saveAll}
                  disabled={saving}
                  className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
                >
                  {saving ? "Saving…" : "Save all feedback"}
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
