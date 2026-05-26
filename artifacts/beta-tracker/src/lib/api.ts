const BASE = "/api";

export async function apiFetch(path: string, options?: RequestInit) {
  const res = await fetch(`${BASE}${path}`, {
    credentials: "include",
    cache: "no-store",
    headers: { "Content-Type": "application/json", ...options?.headers },
    ...options,
  });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw Object.assign(new Error(data.error ?? res.statusText), { status: res.status, data });
  }
  if (res.status === 204) return {};
  return res.json();
}

export const api = {
  features: {
    list: (params?: Record<string, string>) => {
      const qs = params ? "?" + new URLSearchParams(params).toString() : "";
      return apiFetch(`/features${qs}`);
    },
    get: (id: string) => apiFetch(`/features/${id}`),
    create: (body: object) => apiFetch("/features", { method: "POST", body: JSON.stringify(body) }),
    update: (id: string, body: object) => apiFetch(`/features/${id}`, { method: "PUT", body: JSON.stringify(body) }),
    close: (id: string, body: object) => apiFetch(`/features/${id}/close`, { method: "POST", body: JSON.stringify(body) }),
    clone: (id: string) => apiFetch(`/features/${id}/clone`, { method: "POST", body: JSON.stringify({}) }),
    remove: (id: string) => apiFetch(`/features/${id}`, { method: "DELETE" }),
  },
  enrollments: {
    list: (params?: Record<string, string>) => {
      const qs = params ? "?" + new URLSearchParams(params).toString() : "";
      return apiFetch(`/enrollments${qs}`);
    },
    create: (body: object) => apiFetch("/enrollments", { method: "POST", body: JSON.stringify(body) }),
    remove: (id: string) => apiFetch(`/enrollments/${id}`, { method: "DELETE" }),
    approve: (id: string) => apiFetch(`/enrollments/${id}/approve`, { method: "POST" }),
    unapprove: (id: string) => apiFetch(`/enrollments/${id}/unapprove`, { method: "POST" }),
    reject: (id: string, body: object) => apiFetch(`/enrollments/${id}/reject`, { method: "POST", body: JSON.stringify(body) }),
    updateStatus: (id: string, body: object) => apiFetch(`/enrollments/${id}/status`, { method: "PUT", body: JSON.stringify(body) }),
  },
  clients: {
    list: (params?: Record<string, string>) => {
      const qs = params ? "?" + new URLSearchParams(params).toString() : "";
      return apiFetch(`/clients${qs}`);
    },
    get: (id: string) => apiFetch(`/clients/${id}`),
    create: (body: object) => apiFetch("/clients", { method: "POST", body: JSON.stringify(body) }),
    update: (id: string, body: object) => apiFetch(`/clients/${id}`, { method: "PUT", body: JSON.stringify(body) }),
    remove: (id: string) => apiFetch(`/clients/${id}`, { method: "DELETE" }),
    bulkImport: (body: object) => apiFetch("/clients/bulk", { method: "POST", body: JSON.stringify(body) }),
    verticals: () => apiFetch("/clients/verticals"),
  },
  batches: {
    list: (params?: Record<string, string>) => {
      const qs = params ? "?" + new URLSearchParams(params).toString() : "";
      return apiFetch(`/batches${qs}`);
    },
    trigger: () => apiFetch("/batches/trigger", { method: "POST" }),
    triggerForFeature: (featureId: string) => apiFetch(`/batches/trigger-for-feature/${featureId}`, { method: "POST" }),
    update: (id: string, body: object) => apiFetch(`/batches/${id}`, { method: "PUT", body: JSON.stringify(body) }),
    send: (id: string, body?: object) => apiFetch(`/batches/${id}/send`, { method: "POST", body: JSON.stringify(body ?? {}) }),
  },
  reports: {
    overview: () => apiFetch("/reports/overview"),
    atRisk: () => apiFetch("/reports/at-risk"),
    features: () => apiFetch("/reports/features"),
    clients: () => apiFetch("/reports/clients"),
    csmResponsiveness: () => apiFetch("/reports/csm-responsiveness"),
    activity: () => apiFetch("/reports/activity"),
    sentimentByBeta: () => apiFetch("/reports/sentiment-by-beta"),
  },
  users: {
    list: () => apiFetch("/users"),
    betas: (id: string) => apiFetch(`/users/${id}/betas`),
    create: (body: object) => apiFetch("/users", { method: "POST", body: JSON.stringify(body) }),
    update: (id: string, body: object) => apiFetch(`/users/${id}`, { method: "PUT", body: JSON.stringify(body) }),
    remove: (id: string) => apiFetch(`/users/${id}`, { method: "DELETE" }),
  },
  me: {
    get: () => apiFetch("/me"),
  },
  feedback: {
    list: (params?: Record<string, string>) => {
      const qs = params ? "?" + new URLSearchParams(params).toString() : "";
      return apiFetch(`/feedback${qs}`);
    },
    summary: (params?: Record<string, string>) => {
      const qs = params ? "?" + new URLSearchParams(params).toString() : "";
      return apiFetch(`/feedback/summary${qs}`);
    },
    create: (body: object) => apiFetch("/feedback", { method: "POST", body: JSON.stringify(body) }),
  },
};
