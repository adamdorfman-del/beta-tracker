import { useEffect, useRef, useState, useCallback } from "react";
import { Link, useSearch } from "wouter";
import { api } from "@/lib/api";
import { TranscriptImportModal } from "@/components/TranscriptImportModal";
import { FeedbackDetailModal } from "@/components/FeedbackDetailModal";

function PencilIcon() {
  return (
    <svg className="h-3.5 w-3.5" viewBox="0 0 20 20" fill="currentColor">
      <path d="M5.433 13.917l1.262-3.155A4 4 0 017.58 9.42l6.92-6.918a2.121 2.121 0 013 3l-6.92 6.918a4 4 0 01-1.343.885l-3.154 1.262a.5.5 0 01-.63-.63z" />
    </svg>
  );
}

function TrashIcon() {
  return (
    <svg className="h-3.5 w-3.5" viewBox="0 0 20 20" fill="currentColor">
      <path fillRule="evenodd" d="M8.75 1A2.75 2.75 0 006 3.75v.443c-.795.077-1.584.176-2.365.298a.75.75 0 10.23 1.482l.149-.022.841 10.518A2.75 2.75 0 007.596 19h4.807a2.75 2.75 0 002.742-2.53l.841-10.52.149.023a.75.75 0 00.23-1.482A41.03 41.03 0 0014 4.193V3.75A2.75 2.75 0 0011.25 1h-2.5zM10 4c.84 0 1.673.025 2.5.075V3.75c0-.69-.56-1.25-1.25-1.25h-2.5c-.69 0-1.25.56-1.25 1.25v.325C8.327 4.025 9.16 4 10 4zM8.58 7.72a.75.75 0 00-1.5.06l.3 7.5a.75.75 0 101.5-.06l-.3-7.5zm4.34.06a.75.75 0 10-1.5-.06l-.3 7.5a.75.75 0 101.5.06l.3-7.5z" clipRule="evenodd" />
    </svg>
  );
}

function EditFeedbackModal({ entry, onClose, onSaved, focusJira = false }: {
  entry: any;
  onClose: () => void;
  onSaved: () => void;
  focusJira?: boolean;
}) {
  const [sentiment, setSentiment] = useState<Sentiment>(entry.sentiment);
  const [notes, setNotes] = useState(entry.notes ?? "");
  const [providerId, setProviderId] = useState(entry.feedbackProviderId ?? "");
  const [isGatingRequest, setIsGatingRequest] = useState<boolean>(entry.isGatingRequest ?? false);
  const [gatingDescription, setGatingDescription] = useState(entry.gatingDescription ?? "");
  const [jiraTicketUrl, setJiraTicketUrl] = useState(entry.jiraTicketUrl ?? "");
  const [users, setUsers] = useState<any[]>([]);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const jiraRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    api.users.list().then((d: any) => setUsers(d.users ?? d ?? [])).catch(() => {});
  }, []);

  useEffect(() => {
    if (focusJira && isGatingRequest) {
      setTimeout(() => jiraRef.current?.focus(), 50);
    }
  }, [focusJira, isGatingRequest]);

  async function save() {
    if (isGatingRequest && !gatingDescription.trim()) {
      setError("Gating description is required when marking as a blocking feature request.");
      return;
    }
    if (jiraTicketUrl && !jiraTicketUrl.startsWith("https://")) {
      setError("JIRA ticket URL must start with https://");
      return;
    }
    setSaving(true); setError("");
    try {
      await api.feedback.update(entry.id, {
        sentiment,
        notes: notes || null,
        feedbackProviderId: providerId,
        isGatingRequest,
        gatingDescription: isGatingRequest ? (gatingDescription.trim() || null) : null,
        jiraTicketUrl: jiraTicketUrl || null,
      });
      onSaved();
      onClose();
    } catch (e: any) {
      setError(e?.data?.error ?? "Failed to save");
    } finally {
      setSaving(false);
    }
  }

  const SENTIMENTS: Sentiment[] = ["positive", "neutral", "negative"];
  const SENTIMENT_STYLE_MAP: Record<Sentiment, string> = {
    positive: "bg-green-100 text-green-700",
    neutral:  "bg-gray-100 text-gray-600",
    negative: "bg-red-100 text-red-700",
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-md rounded-xl bg-white shadow-xl">
        <div className="px-6 py-5 border-b border-gray-100">
          <h2 className="text-base font-semibold text-gray-900">Edit Feedback</h2>
        </div>
        <div className="px-6 py-4 space-y-4 max-h-[70vh] overflow-y-auto">
          <div>
            <p className="text-xs font-medium text-gray-500 mb-1">Client</p>
            <p className="text-sm text-gray-900">{entry.clientName}</p>
          </div>
          <div>
            <p className="text-xs font-medium text-gray-500 mb-1">Feature</p>
            <p className="text-sm text-gray-900">{entry.featureName}</p>
          </div>
          <div>
            <p className="text-xs font-medium text-gray-500 mb-1">Sentiment</p>
            <div className="flex overflow-hidden rounded-lg border border-gray-200">
              {SENTIMENTS.map((s) => (
                <button key={s} type="button" onClick={() => setSentiment(s)}
                  className={`flex-1 py-1.5 text-sm font-medium transition-colors ${sentiment === s ? SENTIMENT_STYLE_MAP[s] : "text-gray-400 hover:bg-gray-50"}`}>
                  {s.charAt(0).toUpperCase() + s.slice(1)}
                </button>
              ))}
            </div>
          </div>
          <div>
            <p className="text-xs font-medium text-gray-500 mb-1">Notes</p>
            <textarea value={notes} onChange={(e) => setNotes(e.target.value)} rows={3}
              className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm resize-none outline-none focus:border-blue-400" />
          </div>
          <div>
            <p className="text-xs font-medium text-gray-500 mb-1">Feedback provider</p>
            <select value={providerId} onChange={(e) => setProviderId(e.target.value)}
              className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-blue-400 bg-white">
              {users.map((u: any) => <option key={u.id} value={u.id}>{u.name}</option>)}
            </select>
          </div>
          <label className="flex items-start gap-2 cursor-pointer">
            <input type="checkbox" checked={isGatingRequest} onChange={(e) => setIsGatingRequest(e.target.checked)}
              className="mt-0.5 rounded border-gray-300 text-red-600 focus:ring-red-500" />
            <span className="text-sm text-gray-700">Blocking feature request</span>
          </label>
          {isGatingRequest && (
            <>
              <div>
                <p className="text-xs font-medium text-gray-500 mb-1">Gating description <span className="text-red-500">*</span></p>
                <textarea value={gatingDescription} onChange={(e) => setGatingDescription(e.target.value)} rows={3}
                  placeholder="Describe the feature request that is blocking this client from fully adopting the beta."
                  className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm resize-none outline-none focus:border-blue-400" />
              </div>
              <div>
                <p className="text-xs font-medium text-gray-500 mb-1">JIRA ticket URL <span className="text-gray-400">(optional)</span></p>
                <input ref={jiraRef} type="url" value={jiraTicketUrl} onChange={(e) => setJiraTicketUrl(e.target.value)}
                  placeholder="https://birdeye.atlassian.net/..."
                  className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-blue-400" />
              </div>
            </>
          )}
          {error && <p className="text-sm text-red-600">{error}</p>}
        </div>
        <div className="flex justify-end gap-3 border-t border-gray-100 px-6 py-4">
          <button onClick={onClose} disabled={saving}
            className="rounded-lg border border-gray-200 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 disabled:opacity-50">
            Cancel
          </button>
          <button onClick={save} disabled={saving}
            className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50">
            {saving ? "Saving…" : "Save changes"}
          </button>
        </div>
      </div>
    </div>
  );
}

type Sentiment = "positive" | "neutral" | "negative";

const SENTIMENT_STYLE: Record<Sentiment, { label: string; badge: string }> = {
  positive: { label: "Positive", badge: "bg-green-100 text-green-700" },
  neutral:  { label: "Neutral",  badge: "bg-gray-100 text-gray-600"  },
  negative: { label: "Negative", badge: "bg-red-100 text-red-700"    },
};

function SentimentBadge({ sentiment }: { sentiment: Sentiment }) {
  const s = SENTIMENT_STYLE[sentiment] ?? SENTIMENT_STYLE.neutral;
  return (
    <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${s.badge}`}>
      {s.label}
    </span>
  );
}

function SortIcon({ col, sortCol, sortDir }: { col: string; sortCol: string; sortDir: "asc" | "desc" }) {
  if (col !== sortCol) return <svg className="ml-1 h-3 w-3 text-gray-300 inline" viewBox="0 0 16 16" fill="currentColor"><path d="M8 3l3 4H5l3-4zm0 10L5 9h6l-3 4z"/></svg>;
  return sortDir === "asc"
    ? <svg className="ml-1 h-3 w-3 text-blue-500 inline" viewBox="0 0 16 16" fill="currentColor"><path d="M8 3l4 5H4l4-5z"/></svg>
    : <svg className="ml-1 h-3 w-3 text-blue-500 inline" viewBox="0 0 16 16" fill="currentColor"><path d="M8 13L4 8h8l-4 5z"/></svg>;
}

function MultiSelect({ label, options, selected, onChange, width = "w-36" }: {
  label: string;
  options: { value: string; label: string }[];
  selected: string[];
  onChange: (v: string[]) => void;
  width?: string;
}) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function handle(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener("mousedown", handle);
    return () => document.removeEventListener("mousedown", handle);
  }, []);

  function toggle(val: string) {
    onChange(selected.includes(val) ? selected.filter((v) => v !== val) : [...selected, val]);
  }

  const buttonLabel = selected.length === 0
    ? label
    : selected.length === 1
      ? (options.find((o) => o.value === selected[0])?.label ?? selected[0])
      : `${label} (${selected.length})`;

  return (
    <div ref={ref} className={`relative ${width}`}>
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className={`w-full flex items-center justify-between rounded-lg border px-3 py-1.5 text-sm bg-white ${
          selected.length > 0 ? "border-blue-400 text-blue-700 font-medium" : "border-gray-200 text-gray-700"
        }`}
      >
        <span className="truncate">{buttonLabel}</span>
        <svg className="ml-1.5 h-3.5 w-3.5 flex-shrink-0 text-gray-400" viewBox="0 0 20 20" fill="currentColor">
          <path fillRule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.17l3.71-3.94a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clipRule="evenodd" />
        </svg>
      </button>
      {open && (
        <div className="absolute z-20 mt-1 w-full min-w-max rounded-lg border border-gray-200 bg-white py-1 shadow-lg">
          {options.map((opt) => (
            <label key={opt.value} className="flex cursor-pointer items-center gap-2 px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-50">
              <input
                type="checkbox"
                checked={selected.includes(opt.value)}
                onChange={() => toggle(opt.value)}
                className="rounded border-gray-300 text-blue-600"
              />
              {opt.label}
            </label>
          ))}
        </div>
      )}
    </div>
  );
}

const SEGMENTS = ["Strategic", "Enterprise", "Commercial", "Professional", "Channel"] as const;
const DATE_RANGES = [
  { label: "All time",     value: "" },
  { label: "Last 7 days",  value: "7" },
  { label: "Last 30 days", value: "30" },
  { label: "Last 90 days", value: "90" },
];

export default function FeedbackPage() {
  const searchString = useSearch();
  const initialFeatureId = new URLSearchParams(searchString).get("feature_id");

  const [filterFeatures,   setFilterFeatures]   = useState<string[]>(initialFeatureId ? [initialFeatureId] : []);
  const [filterSegments,   setFilterSegments]   = useState<string[]>([]);
  const [filterSentiments, setFilterSentiments] = useState<string[]>([]);
  const [filterDays,       setFilterDays]       = useState("");

  const [summary,    setSummary]    = useState<any>(null);
  const [feedbacks,  setFeedbacks]  = useState<any[]>([]);
  const [features,   setFeatures]   = useState<any[]>([]);
  const [loading,    setLoading]    = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const [rollupSort, setRollupSort] = useState("total");
  const [rollupDir,  setRollupDir]  = useState<"asc" | "desc">("desc");

  const [logSort, setLogSort] = useState("createdAt");
  const [logDir,  setLogDir]  = useState<"asc" | "desc">("desc");

  const [editEntry,   setEditEntry]   = useState<any>(null);
  const [focusJira,   setFocusJira]   = useState(false);
  const [gatingOpen,  setGatingOpen]  = useState(false);
  const [deleteId,    setDeleteId]    = useState<string | null>(null);
  const [deleting,    setDeleting]    = useState(false);
  const [showImport,  setShowImport]  = useState(false);
  const [logOpen,     setLogOpen]     = useState(!!initialFeatureId);
  const [feedbackDetail, setFeedbackDetail] = useState<any>(null);
  const [testimonials,    setTestimonials]    = useState<any[]>([]);
  const [testimonialsOpen, setTestimonialsOpen] = useState(false);
  const [testimonialsLoading, setTestimonialsLoading] = useState(false);

  function openEdit(f: any, withJiraFocus = false) {
    setFocusJira(withJiraFocus);
    setEditEntry(f);
  }

  function loadTestimonials() {
    setTestimonialsLoading(true);
    api.testimonials.list()
      .then((d: any) => setTestimonials(d.testimonials ?? []))
      .catch(console.error)
      .finally(() => setTestimonialsLoading(false));
  }

  function filterParams() {
    const p: Record<string, string> = {};
    if (filterFeatures.length)   p.feature_id = filterFeatures.join(",");
    if (filterSegments.length)   p.segment    = filterSegments.join(",");
    if (filterSentiments.length) p.sentiment  = filterSentiments.join(",");
    if (filterDays)              p.days       = filterDays;
    return p;
  }

  const loadDataRef = useRef<number>(0);

  function loadData(isInitial = false) {
    const seq = ++loadDataRef.current;
    if (isInitial) setLoading(true); else setRefreshing(true);
    const p = filterParams();
    Promise.all([
      api.feedback.summary(p),
      api.feedback.list({ ...p, limit: "500" }),
    ])
      .then(([s, f]) => {
        if (seq !== loadDataRef.current) return; // superseded
        setSummary(s);
        setFeedbacks(f.feedback ?? []);
      })
      .catch(console.error)
      .finally(() => { setLoading(false); setRefreshing(false); });
  }

  useEffect(() => {
    api.features.list({ limit: "200" }).then((d: any) => setFeatures(d.features ?? [])).catch(() => {});
    loadData(true);
  }, []);

  useEffect(() => { if (summary !== null) loadData(); }, [filterFeatures, filterSegments, filterSentiments, filterDays]);

  const totals = summary?.totals ?? { total: 0, positive: 0, neutral: 0, negative: 0 };
  const hasFilter = filterFeatures.length || filterSegments.length || filterSentiments.length || filterDays;

  // Rollup sort
  const sortedRollup = [...(summary?.byFeature ?? [])].sort((a: any, b: any) => {
    const getVal = (r: any) => rollupSort === "rate" ? (r.total > 0 ? r.positive / r.total : 0) : (r[rollupSort] ?? 0);
    const va = getVal(a), vb = getVal(b);
    if (typeof va === "string") return rollupDir === "asc" ? va.localeCompare(vb) : vb.localeCompare(va);
    return rollupDir === "asc" ? va - vb : vb - va;
  });

  function toggleRollup(col: string) {
    if (rollupSort === col) setRollupDir((d) => d === "asc" ? "desc" : "asc");
    else { setRollupSort(col); setRollupDir("desc"); }
  }

  // Log sort
  const sortedLog = [...feedbacks].sort((a: any, b: any) => {
    const dir = logDir === "asc" ? 1 : -1;
    switch (logSort) {
      case "clientName":   return dir * (a.clientName ?? "").localeCompare(b.clientName ?? "");
      case "featureName":  return dir * (a.featureName ?? "").localeCompare(b.featureName ?? "");
      case "sentiment":    return dir * (a.sentiment ?? "").localeCompare(b.sentiment ?? "");
      case "feedbackProviderName": return dir * (a.feedbackProviderName ?? "").localeCompare(b.feedbackProviderName ?? "");
      case "createdAt":    return dir * (new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime());
      default:             return 0;
    }
  });

  function toggleLog(col: string) {
    if (logSort === col) setLogDir((d) => d === "asc" ? "desc" : "asc");
    else { setLogSort(col); setLogDir("desc"); }
  }

  function shortName(full: string) {
    const parts = (full ?? "").trim().split(/\s+/);
    return parts.length >= 2 ? `${parts[0][0]}. ${parts[parts.length - 1]}` : full;
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-gray-900">Feedback</h1>
        <button
          onClick={() => setShowImport(true)}
          className="rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-sm font-medium text-gray-700 hover:bg-gray-50"
        >
          Import from transcript
        </button>
      </div>

      {/* Filter bar */}
      <div className="flex flex-wrap items-center gap-2">
        <MultiSelect
          label="Feature" width="w-44"
          options={features.map((f: any) => ({ value: f.id, label: f.name }))}
          selected={filterFeatures} onChange={setFilterFeatures}
        />
        <MultiSelect
          label="Segment" width="w-36"
          options={SEGMENTS.map((s) => ({ value: s, label: s }))}
          selected={filterSegments} onChange={setFilterSegments}
        />
        <MultiSelect
          label="Sentiment" width="w-36"
          options={[
            { value: "positive", label: "Positive" },
            { value: "neutral",  label: "Neutral"  },
            { value: "negative", label: "Negative" },
          ]}
          selected={filterSentiments} onChange={setFilterSentiments}
        />
        <select value={filterDays} onChange={(e) => setFilterDays(e.target.value)}
          className="w-36 rounded-lg border border-gray-200 px-3 py-1.5 text-sm bg-white text-gray-700">
          {DATE_RANGES.map((r) => <option key={r.value} value={r.value}>{r.label}</option>)}
        </select>
        {hasFilter ? (
          <button onClick={() => { setFilterFeatures([]); setFilterSegments([]); setFilterSentiments([]); setFilterDays(""); }}
            className="rounded-lg border border-gray-200 px-3 py-1.5 text-sm text-gray-500 bg-white hover:bg-gray-50">
            Clear filters
          </button>
        ) : null}
        {refreshing && (
          <svg className="h-4 w-4 animate-spin text-gray-400 ml-1" viewBox="0 0 24 24" fill="none">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z" />
          </svg>
        )}
      </div>

      {/* Summary stats */}
      <div className={`grid grid-cols-2 gap-3 sm:grid-cols-4 transition-opacity duration-150 ${refreshing ? "opacity-50" : ""}`}>
        {[
          { label: "Total responses", value: totals.total,    cls: "text-gray-900" },
          { label: "Positive",        value: totals.positive, cls: "text-green-600" },
          { label: "Negative",        value: totals.negative, cls: "text-red-600" },
          { label: "Neutral",         value: totals.neutral,  cls: "text-gray-500" },
        ].map(({ label, value, cls }) => (
          <div key={label} className="rounded-xl border border-gray-200 bg-white p-4">
            <p className="text-xs text-gray-400 uppercase tracking-wide">{label}</p>
            <p className={`mt-1 text-2xl font-bold ${cls}`}>{loading ? "—" : value}</p>
          </div>
        ))}
      </div>

      {/* By feature rollup */}
      {!loading && sortedRollup.length > 0 && (
        <div className="overflow-hidden rounded-xl border border-gray-200 bg-white">
          <div className="border-b border-gray-100 px-4 py-3">
            <h2 className="text-sm font-semibold text-gray-700">By feature</h2>
          </div>
          <table className="min-w-full divide-y divide-gray-100">
            <thead className="bg-gray-50">
              <tr>
                {([
                  { key: "featureName", label: "Feature" },
                  { key: "total",       label: "Total" },
                  { key: "positive",    label: "Positive" },
                  { key: "negative",    label: "Negative" },
                  { key: "neutral",     label: "Neutral" },
                  { key: "rate",        label: "Positive rate" },
                ] as const).map(({ key, label }) => (
                  <th key={key}
                    className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500 cursor-pointer select-none hover:text-gray-700"
                    onClick={() => toggleRollup(key)}>
                    {label}<SortIcon col={key} sortCol={rollupSort} sortDir={rollupDir} />
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {sortedRollup.map((row: any) => {
                const rate = row.total > 0 ? Math.round((row.positive / row.total) * 100) : 0;
                return (
                  <tr key={row.featureId} className="hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <Link href={`/features/${row.featureSlug ?? row.featureId}`}
                        className="text-sm font-medium text-gray-900 hover:text-blue-600">
                        {row.featureName}
                      </Link>
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-700">{row.total}</td>
                    <td className="px-4 py-3 text-sm text-green-700 font-medium">{row.positive}</td>
                    <td className="px-4 py-3 text-sm text-red-700 font-medium">{row.negative}</td>
                    <td className="px-4 py-3 text-sm text-gray-500">{row.neutral}</td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <div className="h-1.5 w-20 rounded-full bg-gray-200 flex-shrink-0">
                          <div className="h-1.5 rounded-full"
                            style={{ width: `${rate}%`, backgroundColor: rate >= 80 ? '#1D9E75' : rate >= 60 ? '#EF9F27' : '#E24B4A' }} />
                        </div>
                        <span className="text-xs font-medium tabular-nums"
                          style={{ color: rate >= 80 ? '#1D9E75' : rate >= 60 ? '#EF9F27' : '#E24B4A' }}>
                          {rate}%
                        </span>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {/* Gating Requests */}
      {(summary !== null) && (
        <div className="overflow-hidden rounded-xl border border-gray-200 bg-white">
          <button
            onClick={() => setGatingOpen((o) => !o)}
            className="w-full flex items-center justify-between px-4 py-3 text-left hover:bg-gray-50 transition-colors"
          >
            <h2 className="text-sm font-semibold text-gray-700">
              Blocking Feature Requests
              <span className={`ml-2 rounded-full px-2 py-0.5 text-xs font-medium ${feedbacks.filter(f => f.isGatingRequest).length > 0 ? "bg-red-100 text-red-700" : "bg-gray-100 text-gray-500"}`}>
                {feedbacks.filter(f => f.isGatingRequest).length}
              </span>
            </h2>
            <svg className={`h-4 w-4 text-gray-400 transition-transform ${gatingOpen ? "rotate-180" : ""}`} viewBox="0 0 20 20" fill="currentColor">
              <path fillRule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.17l3.71-3.94a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clipRule="evenodd" />
            </svg>
          </button>
          {gatingOpen && (() => {
            const gatingRows = feedbacks.filter(f => f.isGatingRequest);
            if (gatingRows.length === 0) {
              return <p className="px-4 pb-4 text-sm text-gray-400">No blocking feature requests in the current filters.</p>;
            }
            return (
              <table className="min-w-full divide-y divide-gray-100 border-t border-gray-100">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">Client</th>
                    <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">Feature</th>
                    <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500 hidden md:table-cell">Gating description</th>
                    <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">Sentiment</th>
                    <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500 hidden sm:table-cell">JIRA</th>
                    <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500 hidden sm:table-cell">Date</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {gatingRows.map((f: any) => {
                    const dateStr = new Date(f.createdAt).toLocaleDateString("en-US", { month: "short", day: "numeric" });
                    return (
                      <tr key={f.id} className="hover:bg-gray-50">
                        <td className="px-4 py-3 text-sm font-medium text-gray-900">{f.clientName}</td>
                        <td className="px-4 py-3">
                          <Link href={`/features/${f.featureSlug ?? f.featureId}`}
                            className="inline-flex items-center rounded-full bg-purple-100 px-2.5 py-0.5 text-xs font-medium text-purple-700 hover:bg-purple-200">
                            {f.featureName}
                          </Link>
                        </td>
                        <td className="px-4 py-3 text-sm text-gray-600 hidden md:table-cell max-w-xs">
                          {f.gatingDescription ?? <span className="text-gray-300">—</span>}
                        </td>
                        <td className="px-4 py-3"><SentimentBadge sentiment={f.sentiment} /></td>
                        <td className="px-4 py-3 hidden sm:table-cell">
                          {f.jiraTicketUrl ? (
                            <a href={f.jiraTicketUrl} target="_blank" rel="noopener noreferrer"
                              className="text-xs font-medium text-blue-600 hover:text-blue-800">
                              View →
                            </a>
                          ) : (
                            <button onClick={() => openEdit(f, true)}
                              className="text-xs text-gray-400 hover:text-blue-600">
                              Add ticket
                            </button>
                          )}
                        </td>
                        <td className="px-4 py-3 text-sm text-gray-500 hidden sm:table-cell">{dateStr}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            );
          })()}
        </div>
      )}

      {/* Testimonials */}
      {(summary !== null) && (
        <div className="overflow-hidden rounded-xl border border-gray-200 bg-white">
          <button
            onClick={() => {
              if (!testimonialsOpen) loadTestimonials();
              setTestimonialsOpen((o) => !o);
            }}
            className="w-full flex items-center justify-between px-4 py-3 text-left hover:bg-gray-50 transition-colors"
          >
            <h2 className="text-sm font-semibold text-gray-700">Testimonials</h2>
            <svg className={`h-4 w-4 text-gray-400 transition-transform ${testimonialsOpen ? "rotate-180" : ""}`} viewBox="0 0 20 20" fill="currentColor">
              <path fillRule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.17l3.71-3.94a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clipRule="evenodd" />
            </svg>
          </button>
          {testimonialsOpen && (
            testimonialsLoading ? (
              <p className="px-4 pb-4 text-sm text-gray-400">Loading…</p>
            ) : testimonials.length === 0 ? (
              <p className="px-4 pb-4 text-sm text-gray-400">No testimonials yet. Import from a transcript to add them.</p>
            ) : (
              <table className="min-w-full divide-y divide-gray-100 border-t border-gray-100">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">Client</th>
                    <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500 hidden sm:table-cell">Feature</th>
                    <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">Quote</th>
                    <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500 hidden md:table-cell">Context</th>
                    <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">Approved</th>
                    <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500 hidden sm:table-cell">Date</th>
                    <th className="px-4 py-3" />
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {testimonials.map((t: any) => {
                    const dateStr = t.callDate
                      ? new Date(t.callDate + 'T00:00:00').toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })
                      : "—";
                    return (
                      <tr key={t.id} className="hover:bg-gray-50">
                        <td className="px-4 py-3 text-sm font-medium text-gray-900 whitespace-nowrap">{t.clientName}</td>
                        <td className="px-4 py-3 hidden sm:table-cell">
                          <Link href={`/features/${t.featureSlug ?? t.featureId}`}
                            className="inline-flex items-center rounded-full bg-purple-100 px-2.5 py-0.5 text-xs font-medium text-purple-700 hover:bg-purple-200">
                            {t.featureName}
                          </Link>
                        </td>
                        <td className="px-4 py-3 text-sm italic text-gray-700 max-w-xs">
                          <span className="line-clamp-2">"{t.quote}"</span>
                        </td>
                        <td className="px-4 py-3 text-sm text-gray-500 hidden md:table-cell max-w-xs">
                          {t.context ?? <span className="text-gray-300">—</span>}
                        </td>
                        <td className="px-4 py-3">
                          <button
                            onClick={async () => {
                              await api.testimonials.update(t.id, { approved: !t.approved });
                              loadTestimonials();
                            }}
                            className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${t.approved ? "bg-green-100 text-green-700" : "bg-gray-100 text-gray-500"}`}
                          >
                            {t.approved ? "Approved" : "Pending"}
                          </button>
                        </td>
                        <td className="px-4 py-3 text-sm text-gray-500 hidden sm:table-cell whitespace-nowrap">{dateStr}</td>
                        <td className="px-4 py-3 text-right">
                          <div className="flex items-center justify-end gap-2">
                            <button
                              onClick={() => navigator.clipboard.writeText(t.quote)}
                              className="text-xs text-gray-400 hover:text-blue-600"
                            >
                              Copy
                            </button>
                            <button
                              onClick={async () => {
                                await api.testimonials.remove(t.id);
                                loadTestimonials();
                              }}
                              className="text-xs text-gray-300 hover:text-red-600"
                            >
                              Delete
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            )
          )}
        </div>
      )}

      {/* Feedback log */}
      <div className="overflow-hidden rounded-xl border border-gray-200 bg-white">
        <button
          onClick={() => setLogOpen((o) => !o)}
          className="w-full flex items-center justify-between px-4 py-3 text-left hover:bg-gray-50 transition-colors"
        >
          <h2 className="text-sm font-semibold text-gray-700">
            Feedback log
            {feedbacks.length > 0 && (
              <span className="ml-2 rounded-full px-2 py-0.5 text-xs font-medium bg-gray-100 text-gray-500">
                {feedbacks.length}
              </span>
            )}
          </h2>
          <svg className={`h-4 w-4 text-gray-400 transition-transform ${logOpen ? "rotate-180" : ""}`} viewBox="0 0 20 20" fill="currentColor">
            <path fillRule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.17l3.71-3.94a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clipRule="evenodd" />
          </svg>
        </button>
        {logOpen && (loading && feedbacks.length === 0 ? (
          <div className="py-12 text-center text-sm text-gray-400 border-t border-gray-100">Loading…</div>
        ) : feedbacks.length === 0 ? (
          <div className="py-12 text-center text-sm text-gray-400 border-t border-gray-100">No feedback entries match the current filters.</div>
        ) : (
          <table className="min-w-full divide-y divide-gray-100">
            <thead className="bg-gray-50">
              <tr>
                {([
                  { key: "clientName",          label: "Client",            cls: "",                      sortable: true  },
                  { key: "featureName",          label: "Feature",           cls: "",                      sortable: true  },
                  { key: "sentiment",            label: "Sentiment",         cls: "",                      sortable: true  },
                  { key: "gating",               label: "Blocking",          cls: "hidden md:table-cell",  sortable: false },
                  { key: "feedbackProviderName", label: "Feedback provider", cls: "hidden sm:table-cell",  sortable: true  },
                  { key: "createdAt",            label: "Date",              cls: "hidden sm:table-cell",  sortable: true  },
                  { key: "notes",                label: "Notes",             cls: "hidden lg:table-cell",  sortable: false },
                  { key: "jira",                 label: "JIRA",              cls: "hidden lg:table-cell",  sortable: false },
                ] as const).map(({ key, label, cls, sortable }) => (
                  <th key={key}
                    onClick={() => sortable ? toggleLog(key) : undefined}
                    className={`px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500 ${sortable ? "cursor-pointer select-none hover:text-gray-700" : ""} ${cls}`}>
                    {label}
                    {sortable && <SortIcon col={key} sortCol={logSort} sortDir={logDir} />}
                  </th>
                ))}
                <th className="px-4 py-3" />
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {sortedLog.map((f: any) => {
                const dateStr = new Date(f.createdAt).toLocaleDateString("en-US", { month: "short", day: "numeric" });
                const isDeleting = deleteId === f.id;
                return (
                  <tr key={f.id} className="hover:bg-gray-50 cursor-pointer" onClick={() => setFeedbackDetail(f)}>
                    <td className="px-4 py-3 text-sm font-medium text-gray-900">{f.clientName}</td>
                    <td className="px-4 py-3">
                      <Link href={`/features/${f.featureSlug ?? f.featureId}`}
                        className="inline-flex items-center rounded-full bg-purple-100 px-2.5 py-0.5 text-xs font-medium text-purple-700 hover:bg-purple-200">
                        {f.featureName}
                      </Link>
                    </td>
                    <td className="px-4 py-3"><SentimentBadge sentiment={f.sentiment} /></td>
                    <td className="px-4 py-3 hidden md:table-cell">
                      {f.isGatingRequest && (
                        <span title={f.gatingDescription ?? undefined}
                          className="inline-flex items-center rounded-full bg-red-100 px-2 py-0.5 text-xs font-medium text-red-700 cursor-default">
                          Blocking
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-500 hidden sm:table-cell">{shortName(f.feedbackProviderName)}</td>
                    <td className="px-4 py-3 text-sm text-gray-500 hidden sm:table-cell">{dateStr}</td>
                    <td className="px-4 py-3 text-sm text-gray-400 hidden lg:table-cell max-w-xs truncate">{f.notes ?? "—"}</td>
                    <td className="px-4 py-3 hidden lg:table-cell">
                      {f.jiraTicketUrl ? (
                        <a href={f.jiraTicketUrl} target="_blank" rel="noopener noreferrer"
                          className="text-xs font-medium text-blue-600 hover:text-blue-800 whitespace-nowrap">
                          View →
                        </a>
                      ) : f.isGatingRequest ? (
                        <button onClick={() => openEdit(f, true)}
                          className="text-xs text-gray-400 hover:text-blue-600 whitespace-nowrap">
                          Add ticket
                        </button>
                      ) : null}
                    </td>
                    <td className="px-4 py-3 text-right" onClick={(e) => e.stopPropagation()}>
                      {isDeleting ? (
                        <div className="flex items-center justify-end gap-2 text-xs">
                          <span className="text-gray-500">Delete this? Cannot be undone.</span>
                          <button onClick={() => setDeleteId(null)} disabled={deleting}
                            className="rounded border border-gray-200 px-2 py-0.5 text-gray-600 hover:bg-gray-50 disabled:opacity-50">
                            Cancel
                          </button>
                          <button disabled={deleting} onClick={async () => {
                            setDeleting(true);
                            try {
                              await api.feedback.remove(f.id);
                              setFeedbacks(prev => prev.filter(x => x.id !== f.id));
                              setDeleteId(null);
                              loadData();
                            } catch { /* ignore */ } finally { setDeleting(false); }
                          }} className="rounded bg-red-600 px-2 py-0.5 font-medium text-white hover:bg-red-700 disabled:opacity-50">
                            {deleting ? "…" : "Delete"}
                          </button>
                        </div>
                      ) : (
                        <div className="flex items-center justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity [tr:hover_&]:opacity-100">
                          <button onClick={() => openEdit(f)} title="Edit"
                            className="rounded p-1 text-gray-300 hover:text-blue-600 hover:bg-blue-50">
                            <PencilIcon />
                          </button>
                          <button onClick={() => setDeleteId(f.id)} title="Delete"
                            className="rounded p-1 text-gray-300 hover:text-red-600 hover:bg-red-50">
                            <TrashIcon />
                          </button>
                        </div>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        ))}
      </div>

      {feedbackDetail && (
        <FeedbackDetailModal entry={feedbackDetail} onClose={() => setFeedbackDetail(null)} />
      )}

      {editEntry && (
        <EditFeedbackModal
          entry={editEntry}
          focusJira={focusJira}
          onClose={() => { setEditEntry(null); setFocusJira(false); }}
          onSaved={loadData}
        />
      )}

      {showImport && (() => {
        const singleFeature = filterFeatures.length === 1
          ? features.find((f: any) => f.id === filterFeatures[0])
          : undefined;
        return (
          <TranscriptImportModal
            defaultFeatureId={singleFeature?.id}
            defaultFeatureName={singleFeature?.name}
            onClose={() => setShowImport(false)}
            onSaved={() => { loadData(); if (testimonialsOpen) loadTestimonials(); }}
          />
        );
      })()}
    </div>
  );
}
