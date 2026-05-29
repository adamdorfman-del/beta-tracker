const STAGES = [
  { key: "nominated" as const, label: "Nominated", bg: "#D3D1C7", color: "#444441" },
  { key: "approved"  as const, label: "Approved",  bg: "#FAC775", color: "#633806" },
  { key: "enrolled"  as const, label: "Enrolled",  bg: "#85B7EB", color: "#0C447C" },
  { key: "using"     as const, label: "Using",     bg: "#AFA9EC", color: "#3C3489" },
  { key: "accepted"  as const, label: "Accepted",  bg: "#5DCAA5", color: "#085041" },
];

export type FunnelData = {
  nominated: number;
  approved: number;
  enrolled: number;
  using: number;
  accepted: number;
  total: number;
};

export function EnrollmentFunnelCard({
  funnel,
}: {
  funnel: FunnelData;
}) {
  const total = funnel.total;
  const activeStages = STAGES.filter((s) => funnel[s.key] > 0);

  return (
    <div>
      <div className="flex items-baseline justify-between mb-3">
        <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">
          Enrollment pipeline{" "}
          <span className="font-normal text-gray-400">· {total} total</span>
        </p>
      </div>

      {total === 0 ? (
        <div className="flex h-10 items-center justify-center rounded-lg bg-gray-100">
          <span className="text-xs text-gray-400">No enrollments yet</span>
        </div>
      ) : (
        <>
          <div className="flex overflow-hidden rounded-lg" style={{ gap: "2px" }}>
            {activeStages.map((s) => (
              <div
                key={s.key}
                title={`${s.label}: ${funnel[s.key]}`}
                style={{
                  background: s.bg,
                  color: s.color,
                  flexGrow: funnel[s.key],
                  flexBasis: 0,
                  minWidth: "32px",
                }}
                className="flex items-center justify-center py-2.5 text-xs font-semibold select-none"
              >
                {funnel[s.key]}
              </div>
            ))}
          </div>

          <div className="mt-2.5 flex flex-wrap gap-x-4 gap-y-1">
            {activeStages.map((s) => (
              <div key={s.key} className="flex items-center gap-1.5 text-xs text-gray-600">
                <span className="h-2 w-2 shrink-0 rounded-full" style={{ background: s.bg }} />
                {s.label}{" "}
                <span className="font-semibold text-gray-800">{funnel[s.key]}</span>
              </div>
            ))}
          </div>
        </>
      )}
    </div>
  );
}

export function MiniFunnelBar({ funnel }: { funnel: FunnelData }) {
  const total = funnel.total;

  if (total === 0) {
    return <span className="text-xs text-gray-300">No enrollments yet</span>;
  }

  const tooltip = STAGES.map((s) => `${s.label}: ${funnel[s.key]}`).join(" · ");

  return (
    <div className="flex items-center gap-2">
      <div
        className="flex overflow-hidden rounded"
        style={{ height: "8px", width: "96px", gap: "2px", flexShrink: 0 }}
        title={tooltip}
      >
        {STAGES.filter((s) => funnel[s.key] > 0).map((s) => (
          <div
            key={s.key}
            style={{
              background: s.bg,
              flexGrow: funnel[s.key],
              flexBasis: 0,
              minWidth: "4px",
            }}
          />
        ))}
      </div>
      <span className="text-xs text-gray-500 tabular-nums whitespace-nowrap">{total} enrolled</span>
    </div>
  );
}
