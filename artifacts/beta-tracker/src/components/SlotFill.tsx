export function SlotFill({ enrolled, outreach, filled, target }: {
  enrolled: number;
  outreach: number;
  filled: number;
  target: number;
}) {
  const enrolledPct  = target > 0 ? Math.min(100, (enrolled / target) * 100) : 0;
  const outreachPct  = target > 0 ? Math.min(100 - enrolledPct, (outreach / target) * 100) : 0;

  return (
    <div className="flex items-center gap-2 min-w-0">
      <div
        className="relative h-1.5 w-24 rounded-full bg-gray-200 flex-shrink-0 overflow-hidden"
        title={`${enrolled} confirmed, ${outreach} approved/in outreach`}
      >
        {enrolledPct > 0 && (
          <div
            className="absolute left-0 top-0 h-full bg-blue-600"
            style={{ width: `${enrolledPct}%` }}
          />
        )}
        {outreachPct > 0 && (
          <div
            className="absolute top-0 h-full bg-blue-600"
            style={{ left: `${enrolledPct}%`, width: `${outreachPct}%`, opacity: 0.35 }}
          />
        )}
      </div>
      <span className="text-sm tabular-nums text-gray-700 whitespace-nowrap">
        {filled}/{target}
      </span>
    </div>
  );
}
