type StylePair = { background: string; color: string };

const ROLE_STYLES: Record<string, StylePair> = {
  pm:          { background: "#dbeafe", color: "#1d4ed8" },
  pmm:         { background: "#ede9fe", color: "#6d28d9" },
  csm:         { background: "#dcfce7", color: "#15803d" },
  admin:       { background: "#fee2e2", color: "#b91c1c" },
  ae:          { background: "#ffedd5", color: "#c2410c" },
};

const ROLE_LABELS: Record<string, string> = {
  pm:          "PM",
  pmm:         "PMM",
  csm:         "CSM",
  admin:       "Admin",
  ae:          "AE",
};

export function RoleBadge({ role }: { role: string }) {
  const style = ROLE_STYLES[role] ?? { background: "#f3f4f6", color: "#374151" };
  const label = ROLE_LABELS[role] ?? role;
  return (
    <span
      style={{ background: style.background, color: style.color }}
      className="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium"
    >
      {label}
    </span>
  );
}
