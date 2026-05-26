import { useEffect, useRef, useState } from "react";
import { Link } from "wouter";
import { api } from "@/lib/api";

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
  const [filterFeatures,   setFilterFeatures]   = useState<string[]>([]);
  const [filterSegments,   setFilterSegments]   = useState<string[]>([]);
  const [filterSentiments, setFilterSentiments] = useState<string[]>([]);
  const [filterDays,       setFilterDays]       = useState("");

  const [summary,   setSummary]   = useState<any>(null);
  const [feedbacks, setFeedbacks] = useState<any[]>([]);
  const [features,  setFeatures]  = useState<any[]>([]);
  const [loading,   setLoading]   = useState(true);

  const [rollupSort, setRollupSort] = useState("total");
  const [rollupDir,  setRollupDir]  = useState<"asc" | "desc">("desc");

  const [logSort, setLogSort] = useState("createdAt");
  const [logDir,  setLogDir]  = useState<"asc" | "desc">("desc");

  function filterParams() {
    const p: Record<string, string> = {};
    if (filterFeatures.length)   p.feature_id = filterFeatures.join(",");
    if (filterSegments.length)   p.segment    = filterSegments.join(",");
    if (filterSentiments.length) p.sentiment  = filterSentiments.join(",");
    if (filterDays)              p.days       = filterDays;
    return p;
  }

  function loadData() {
    setLoading(true);
    const p = filterParams();
    Promise.all([
      api.feedback.summary(p),
      api.feedback.list({ ...p, limit: "500" }),
    ])
      .then(([s, f]) => { setSummary(s); setFeedbacks(f.feedback ?? []); })
      .catch(console.error)
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    api.features.list({ limit: "200" }).then((d: any) => setFeatures(d.features ?? [])).catch(() => {});
  }, []);

  useEffect(() => { loadData(); }, [filterFeatures, filterSegments, filterSentiments, filterDays]);

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
      case "loggedByName": return dir * (a.loggedByName ?? "").localeCompare(b.loggedByName ?? "");
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
      <h1 className="text-2xl font-semibold text-gray-900">Feedback</h1>

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
      </div>

      {/* Summary stats */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
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
                          <div className={`h-1.5 rounded-full ${rate >= 50 ? "bg-green-500" : "bg-red-400"}`}
                            style={{ width: `${rate}%` }} />
                        </div>
                        <span className={`text-xs font-medium tabular-nums ${rate >= 50 ? "text-green-700" : "text-red-600"}`}>
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

      {/* Feedback log */}
      <div className="overflow-hidden rounded-xl border border-gray-200 bg-white">
        <div className="border-b border-gray-100 px-4 py-3">
          <h2 className="text-sm font-semibold text-gray-700">Feedback log</h2>
        </div>
        {loading ? (
          <div className="py-12 text-center text-sm text-gray-400">Loading…</div>
        ) : feedbacks.length === 0 ? (
          <div className="py-12 text-center text-sm text-gray-400">No feedback entries match the current filters.</div>
        ) : (
          <table className="min-w-full divide-y divide-gray-100">
            <thead className="bg-gray-50">
              <tr>
                {([
                  { key: "clientName",   label: "Client",     cls: "" },
                  { key: "featureName",  label: "Feature",    cls: "" },
                  { key: "sentiment",    label: "Sentiment",  cls: "" },
                  { key: "loggedByName", label: "Logged by",  cls: "hidden sm:table-cell" },
                  { key: "createdAt",    label: "Date",       cls: "hidden sm:table-cell" },
                  { key: "notes",        label: "Notes",      cls: "hidden lg:table-cell" },
                ] as const).map(({ key, label, cls }) => (
                  <th key={key}
                    onClick={() => key !== "notes" ? toggleLog(key) : undefined}
                    className={`px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500 ${key !== "notes" ? "cursor-pointer select-none hover:text-gray-700" : ""} ${cls}`}>
                    {label}
                    {key !== "notes" && <SortIcon col={key} sortCol={logSort} sortDir={logDir} />}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {sortedLog.map((f: any) => {
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
                    <td className="px-4 py-3"><SentimentBadge sentiment={f.sentiment} /></td>
                    <td className="px-4 py-3 text-sm text-gray-500 hidden sm:table-cell">{shortName(f.loggedByName)}</td>
                    <td className="px-4 py-3 text-sm text-gray-500 hidden sm:table-cell">{dateStr}</td>
                    <td className="px-4 py-3 text-sm text-gray-400 hidden lg:table-cell max-w-xs truncate">{f.notes ?? "—"}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
