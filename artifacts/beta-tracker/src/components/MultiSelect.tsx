import { useEffect, useRef, useState } from "react";

export function MultiSelect({ label, options, groups, selected, onChange, labelMap, className }: {
  label: string;
  options?: string[];
  groups?: Array<{ label: string; options: string[] }>;
  selected: string[];
  onChange: (v: string[]) => void;
  labelMap?: Record<string, string>;
  className?: string;
}) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, []);

  function toggle(val: string) {
    onChange(selected.includes(val) ? selected.filter((v) => v !== val) : [...selected, val]);
  }

  const displayLabel = (v: string) => labelMap?.[v] ?? v;
  const buttonLabel = selected.length === 0 ? label
    : selected.length === 1 ? displayLabel(selected[0])
    : `${label} (${selected.length})`;

  const flatOptions = groups ? groups.flatMap(g => g.options) : (options ?? []);

  return (
    <div ref={ref} className={`relative ${className ?? ""}`}>
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className={`flex w-full items-center justify-between rounded-lg border px-3 py-1.5 text-sm outline-none
          ${selected.length > 0
            ? "border-blue-400 bg-blue-50 font-medium text-blue-700"
            : "border-gray-200 bg-white text-gray-600"}`}
      >
        <span className="truncate">{buttonLabel}</span>
        <svg className="ml-2 h-3 w-3 flex-shrink-0 text-gray-400" viewBox="0 0 20 20" fill="currentColor">
          <path fillRule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.17l3.71-3.94a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clipRule="evenodd" />
        </svg>
      </button>
      {open && (
        <div className="absolute z-20 mt-1 min-w-full rounded-lg border border-gray-200 bg-white py-1 shadow-lg">
          {groups ? groups.map((group, gi) => (
            <div key={group.label}>
              {gi > 0 && <div className="mx-2 my-1 border-t border-gray-100" />}
              <p className="px-3 py-1 text-[10px] font-semibold uppercase tracking-wide text-gray-400">{group.label}</p>
              {group.options.map((opt) => (
                <label key={opt} className="flex cursor-pointer items-center gap-2 px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-50">
                  <input
                    type="checkbox"
                    checked={selected.includes(opt)}
                    onChange={() => toggle(opt)}
                    className="rounded border-gray-300 text-blue-600"
                  />
                  {displayLabel(opt)}
                </label>
              ))}
            </div>
          )) : flatOptions.map((opt) => (
            <label key={opt} className="flex cursor-pointer items-center gap-2 px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-50">
              <input
                type="checkbox"
                checked={selected.includes(opt)}
                onChange={() => toggle(opt)}
                className="rounded border-gray-300 text-blue-600"
              />
              {displayLabel(opt)}
            </label>
          ))}
        </div>
      )}
    </div>
  );
}
