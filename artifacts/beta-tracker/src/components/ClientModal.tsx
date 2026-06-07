import { useEffect, useState } from "react";
import { api } from "@/lib/api";
import { useCurrentUser } from "@/hooks/useCurrentUser";

const SEGMENTS = ["Strategic", "Enterprise", "Commercial", "Professional", "Channel"] as const;
const HEALTH_OPTIONS = [
  { value: "green",  label: "Green" },
  { value: "yellow", label: "Yellow" },
  { value: "red",    label: "Red" },
];

const EMPTY: Record<string, string> = {
  name: "", crmId: "", csmOwnerId: "", aeOwnerId: "", segment: "",
  primaryContactName: "", primaryContactEmail: "",
  accountHealth: "green", vertical: "",
  contractRenewalDate: "", productSubscriptions: "", lastOutreachDate: "",
};

function fromClient(c: any) {
  return {
    name:                c.name ?? "",
    crmId:               c.crmId ?? "",
    csmOwnerId:          c.csmOwnerId ?? "",
    aeOwnerId:           c.aeOwnerId ?? "",
    segment:             c.segment ?? "",
    primaryContactName:  c.primaryContactName ?? "",
    primaryContactEmail: c.primaryContactEmail ?? "",
    accountHealth:       c.accountHealth ?? "green",
    vertical:            c.vertical ?? "",
    contractRenewalDate: c.contractRenewalDate ?? "",
    productSubscriptions:c.productSubscriptions ?? "",
    lastOutreachDate:    c.lastOutreachDate ?? "",
  };
}

interface Props {
  client?: any;
  onClose: () => void;
  onSaved: () => void;
}

export function ClientModal({ client, onClose, onSaved }: Props) {
  const [users, setUsers] = useState<any[]>([]);
  const [form, setForm] = useState<Record<string, string>>(client ? fromClient(client) : EMPTY);
  const [betaEligibleOverride, setBetaEligibleOverride] = useState<boolean>(client?.betaEligibleOverride ?? false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const currentUser = useCurrentUser();

  useEffect(() => {
    api.users.list().then((d) => setUsers(d.users ?? [])).catch(() => {});
  }, []);

  const csms = users.filter((u) => u.role === "csm" || u.role === "admin");
  const aes  = users.filter((u) => u.role === "ae");

  function set(field: string, value: string) {
    setForm((f) => ({ ...f, [field]: value }));
  }

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true); setError(null);
    try {
      if (client) {
        const payload: Record<string, unknown> = { ...form };
        if (currentUser?.role === "admin") payload.betaEligibleOverride = betaEligibleOverride;
        await api.clients.update(client.id, payload);
      } else {
        await api.clients.create(form);
      }
      onSaved(); onClose();
    } catch (e: any) {
      setError(e?.data?.error ?? e?.message ?? "Something went wrong.");
    } finally {
      setSaving(false);
    }
  }

  const inputCls = "w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-blue-400";
  const labelCls = "block text-xs font-medium text-gray-700 mb-1";

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-xl rounded-xl bg-white shadow-xl">
        <div className="flex items-center justify-between border-b border-gray-200 px-6 py-4">
          <h2 className="text-base font-semibold text-gray-900">{client ? "Edit Client" : "Add Client"}</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 text-lg leading-none">&times;</button>
        </div>
        <form onSubmit={submit} className="space-y-4 px-6 py-5 max-h-[80vh] overflow-y-auto">
          {error && <div className="rounded-md bg-red-50 border border-red-200 px-3 py-2 text-sm text-red-700">{error}</div>}

          <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide">Required fields</p>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className={labelCls}>Client Name <span className="text-red-500">*</span></label>
              <input autoFocus value={form.name} onChange={(e) => set("name", e.target.value)} required className={inputCls} />
            </div>
            <div>
              <label className={labelCls}>Client ID <span className="text-red-500">*</span></label>
              <input value={form.crmId} onChange={(e) => set("crmId", e.target.value)} required className={inputCls} placeholder="e.g. ACC-00123" />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className={labelCls}>Primary Contact Name</label>
              <input value={form.primaryContactName} onChange={(e) => set("primaryContactName", e.target.value)} className={inputCls} />
            </div>
            <div>
              <label className={labelCls}>Primary Contact Email</label>
              <input type="email" value={form.primaryContactEmail} onChange={(e) => set("primaryContactEmail", e.target.value)} className={inputCls} />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className={labelCls}>Segment <span className="text-red-500">*</span></label>
              <select value={form.segment} onChange={(e) => set("segment", e.target.value)} required className={inputCls}>
                <option value="">Select…</option>
                {SEGMENTS.map((s) => <option key={s} value={s}>{s}</option>)}
              </select>
            </div>
            <div>
              <label className={labelCls}>CSM Owner <span className="text-red-500">*</span></label>
              <select value={form.csmOwnerId} onChange={(e) => set("csmOwnerId", e.target.value)} required className={inputCls}>
                <option value="">Select…</option>
                {csms.map((u) => <option key={u.id} value={u.id}>{u.name}</option>)}
              </select>
            </div>
          </div>

          <div>
            <label className={labelCls}>AE Owner <span className="text-gray-400 font-normal">(optional)</span></label>
            <select value={form.aeOwnerId} onChange={(e) => set("aeOwnerId", e.target.value)} className={inputCls}>
              <option value="">None</option>
              {aes.map((u) => <option key={u.id} value={u.id}>{u.name}</option>)}
            </select>
          </div>

          <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide pt-1">Optional fields</p>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className={labelCls}>Account Health</label>
              <select value={form.accountHealth} onChange={(e) => {
                set("accountHealth", e.target.value);
                if (e.target.value !== "red") setBetaEligibleOverride(false);
              }} className={inputCls}>
                {HEALTH_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select>
            </div>
            <div>
              <label className={labelCls}>Vertical</label>
              <input value={form.vertical} onChange={(e) => set("vertical", e.target.value)} className={inputCls} placeholder="e.g. Real Estate" />
            </div>
          </div>

          {client && form.accountHealth === "red" && currentUser?.role === "admin" && (
            <div className="flex items-center justify-between rounded-lg border border-amber-200 bg-amber-50 px-3 py-2.5">
              <div>
                <p className="text-sm font-medium text-amber-900">Allow beta participation despite red health</p>
                <p className="text-xs text-amber-700 mt-0.5">Admin override — enables this client in the Add Beta Testers panel</p>
              </div>
              <button
                type="button"
                role="switch"
                aria-checked={betaEligibleOverride}
                onClick={() => setBetaEligibleOverride(v => !v)}
                className={`relative inline-flex h-5 w-9 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 focus:outline-none ${betaEligibleOverride ? "bg-amber-500" : "bg-gray-300"}`}
              >
                <span className={`pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow transition duration-200 ${betaEligibleOverride ? "translate-x-4" : "translate-x-0"}`} />
              </button>
            </div>
          )}

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className={labelCls}>Contract Renewal Date</label>
              <input type="date" value={form.contractRenewalDate} onChange={(e) => set("contractRenewalDate", e.target.value)} className={inputCls} />
            </div>
            <div>
              <label className={labelCls}>Last Outreach Date</label>
              <input type="date" value={form.lastOutreachDate} onChange={(e) => set("lastOutreachDate", e.target.value)} className={inputCls} />
            </div>
          </div>

          <div>
            <label className={labelCls}>Product Subscriptions</label>
            <input value={form.productSubscriptions} onChange={(e) => set("productSubscriptions", e.target.value)} className={inputCls} placeholder="e.g. Listings, Reviews, Social" />
          </div>

          <div className="flex justify-end gap-2 pt-1">
            <button type="button" onClick={onClose} className="rounded-lg border px-4 py-2 text-sm text-gray-600 hover:bg-gray-50">Cancel</button>
            <button type="submit" disabled={saving} className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50">
              {saving ? "Saving…" : client ? "Save changes" : "Add client"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
