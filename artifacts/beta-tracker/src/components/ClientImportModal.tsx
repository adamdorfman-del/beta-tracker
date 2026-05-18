import { useRef, useState } from "react";
import { api } from "@/lib/api";

const TEMPLATE_HEADERS = [
  "Client Name", "Client ID", "Primary Contact Name", "Primary Contact Email",
  "Segment", "CSM Email", "Account Health", "Vertical",
  "Contract Renewal Date", "Product Subscriptions", "Last Outreach Date",
];

const SEGMENT_MAP: Record<string, string> = {
  enterprise: "Enterprise", commercial: "Commercial", midmarket: "Midmarket",
  channel: "Channel", smb: "SMB",
};
const HEALTH_MAP: Record<string, string> = {
  green: "green", yellow: "yellow", red: "red",
  healthy: "green", "at risk": "yellow", critical: "red",
};

function parseCSV(text: string): string[][] {
  return text.trim().split(/\r?\n/).map((line) => {
    const row: string[] = [];
    let cur = ""; let inQuote = false;
    for (let i = 0; i < line.length; i++) {
      const ch = line[i];
      if (ch === '"') { inQuote = !inQuote; continue; }
      if (ch === "," && !inQuote) { row.push(cur.trim()); cur = ""; continue; }
      cur += ch;
    }
    row.push(cur.trim());
    return row;
  });
}

function rowToRecord(headers: string[], values: string[]) {
  const r: Record<string, string> = {};
  headers.forEach((h, i) => { r[h.toLowerCase().trim()] = (values[i] ?? "").trim(); });
  return {
    name:                r["client name"] ?? "",
    crmId:               r["client id"] ?? "",
    primaryContactName:  r["primary contact name"] ?? "",
    primaryContactEmail: r["primary contact email"] ?? "",
    segment:             SEGMENT_MAP[(r["segment"] ?? "").toLowerCase()] ?? r["segment"] ?? "",
    csmEmail:            r["csm email"] ?? "",
    accountHealth:       HEALTH_MAP[(r["account health"] ?? "").toLowerCase()] || "green",
    vertical:            r["vertical"] ?? "",
    contractRenewalDate: r["contract renewal date"] ?? "",
    productSubscriptions:r["product subscriptions"] ?? "",
    lastOutreachDate:    r["last outreach date"] ?? "",
  };
}

function downloadTemplate() {
  const csv = TEMPLATE_HEADERS.join(",") + "\n" +
    "Acme Corp,ACC-001,Jane Smith,jane@acme.com,Enterprise,csm@yourcompany.com,green,Real Estate,2026-12-31,Listings,2026-01-15\n";
  const blob = new Blob([csv], { type: "text/csv" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a"); a.href = url; a.download = "clients_template.csv"; a.click();
  URL.revokeObjectURL(url);
}

interface Props { onClose: () => void; onImported: () => void; }

export function ClientImportModal({ onClose, onImported }: Props) {
  const fileRef = useRef<HTMLInputElement>(null);
  const [preview, setPreview] = useState<any[]>([]);
  const [importing, setImporting] = useState(false);
  const [results, setResults] = useState<any[] | null>(null);
  const [parseError, setParseError] = useState<string | null>(null);

  function handleFile(e: React.ChangeEvent<HTMLInputElement>) {
    setParseError(null); setResults(null); setPreview([]);
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (ev) => {
      try {
        const text = ev.target?.result as string;
        const rows = parseCSV(text);
        if (rows.length < 2) { setParseError("File appears empty."); return; }
        const headers = rows[0];
        const records = rows.slice(1).filter(r => r.some(c => c)).map(r => rowToRecord(headers, r));
        setPreview(records);
      } catch { setParseError("Could not parse file. Make sure it's a valid CSV."); }
    };
    reader.readAsText(file);
  }

  async function runImport() {
    if (preview.length === 0) return;
    setImporting(true);
    try {
      const data = await api.clients.bulkImport({ rows: preview });
      setResults(data.results ?? []);
      if (data.succeeded > 0) onImported();
    } catch (e: any) {
      setParseError(e?.data?.error ?? "Import failed.");
    } finally {
      setImporting(false);
    }
  }

  const succeeded = results?.filter(r => r.success).length ?? 0;
  const failed    = results?.filter(r => !r.success).length ?? 0;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-2xl rounded-xl bg-white shadow-xl">
        <div className="flex items-center justify-between border-b border-gray-200 px-6 py-4">
          <h2 className="text-base font-semibold text-gray-900">Import Clients from CSV</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 text-lg leading-none">&times;</button>
        </div>

        <div className="px-6 py-5 space-y-4 max-h-[80vh] overflow-y-auto">
          {!results && (
            <>
              <div className="rounded-lg bg-blue-50 border border-blue-100 px-4 py-3 text-sm text-blue-800 space-y-1">
                <p className="font-medium">Expected columns (in any order):</p>
                <p className="text-xs text-blue-700">
                  <strong>Required:</strong> Client Name, Client ID, Primary Contact Name, Primary Contact Email, Segment, CSM Email
                </p>
                <p className="text-xs text-blue-700">
                  <strong>Optional:</strong> Account Health, Vertical, Contract Renewal Date, Product Subscriptions, Last Outreach Date
                </p>
                <p className="text-xs text-blue-600 mt-1">CSM Email must match an existing stakeholder. Dates: YYYY-MM-DD. Segment: Enterprise / Commercial / Midmarket / Channel / SMB.</p>
              </div>

              <div className="flex items-center gap-3">
                <button onClick={downloadTemplate}
                  className="rounded-lg border border-gray-300 px-3 py-1.5 text-xs font-medium text-gray-600 hover:bg-gray-50">
                  ↓ Download template
                </button>
                <label className="cursor-pointer rounded-lg bg-blue-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-blue-700">
                  Choose CSV file
                  <input ref={fileRef} type="file" accept=".csv,text/csv" onChange={handleFile} className="sr-only" />
                </label>
              </div>

              {parseError && <p className="text-sm text-red-600">{parseError}</p>}

              {preview.length > 0 && (
                <div className="space-y-2">
                  <p className="text-sm font-medium text-gray-700">{preview.length} row{preview.length !== 1 ? "s" : ""} ready to import</p>
                  <div className="overflow-x-auto rounded-lg border border-gray-200 max-h-48">
                    <table className="min-w-full text-xs divide-y divide-gray-100">
                      <thead className="bg-gray-50">
                        <tr>
                          {["Client Name","Client ID","Segment","CSM Email","Contact Name","Health"].map(h => (
                            <th key={h} className="px-3 py-2 text-left font-medium text-gray-500 whitespace-nowrap">{h}</th>
                          ))}
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-100">
                        {preview.slice(0, 10).map((r, i) => (
                          <tr key={i} className="hover:bg-gray-50">
                            <td className="px-3 py-1.5 text-gray-900">{r.name || <span className="text-red-500">missing</span>}</td>
                            <td className="px-3 py-1.5 text-gray-600">{r.crmId || "—"}</td>
                            <td className="px-3 py-1.5 text-gray-600">{r.segment || <span className="text-red-500">missing</span>}</td>
                            <td className="px-3 py-1.5 text-gray-600">{r.csmEmail || <span className="text-red-500">missing</span>}</td>
                            <td className="px-3 py-1.5 text-gray-600">{r.primaryContactName || <span className="text-red-500">missing</span>}</td>
                            <td className="px-3 py-1.5 text-gray-600">{r.accountHealth}</td>
                          </tr>
                        ))}
                        {preview.length > 10 && (
                          <tr><td colSpan={6} className="px-3 py-1.5 text-gray-400 text-center">…and {preview.length - 10} more</td></tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}
            </>
          )}

          {results && (
            <div className="space-y-3">
              <div className="flex gap-4">
                <div className="rounded-lg bg-green-50 border border-green-200 px-4 py-3 text-center flex-1">
                  <p className="text-2xl font-bold text-green-700">{succeeded}</p>
                  <p className="text-xs text-green-600">Imported</p>
                </div>
                <div className={`rounded-lg border px-4 py-3 text-center flex-1 ${failed > 0 ? "bg-red-50 border-red-200" : "bg-gray-50 border-gray-200"}`}>
                  <p className={`text-2xl font-bold ${failed > 0 ? "text-red-700" : "text-gray-400"}`}>{failed}</p>
                  <p className={`text-xs ${failed > 0 ? "text-red-600" : "text-gray-400"}`}>Failed</p>
                </div>
              </div>
              {failed > 0 && (
                <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 space-y-1 max-h-40 overflow-y-auto">
                  {results.filter(r => !r.success).map(r => (
                    <p key={r.row} className="text-xs text-red-700">Row {r.row}: {r.error}</p>
                  ))}
                </div>
              )}
            </div>
          )}

          <div className="flex justify-end gap-2 pt-1">
            <button onClick={onClose} className="rounded-lg border px-4 py-2 text-sm text-gray-600 hover:bg-gray-50">
              {results ? "Close" : "Cancel"}
            </button>
            {!results && preview.length > 0 && (
              <button onClick={runImport} disabled={importing}
                className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50">
                {importing ? "Importing…" : `Import ${preview.length} client${preview.length !== 1 ? "s" : ""}`}
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
