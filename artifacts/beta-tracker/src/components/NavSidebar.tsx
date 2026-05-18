import { Link, useLocation } from "wouter";

const NAV = [
  { href: "/dashboard",    label: "Dashboard" },
  { href: "/features",     label: "Features" },
  { href: "/approvals",    label: "Approvals" },
  { href: "/batches",      label: "Outreach" },
  { href: "/reports",      label: "Reports" },
  { href: "/clients",      label: "Clients" },
  { href: "/stakeholders", label: "Stakeholders" },
];

export function NavSidebar({ pendingApprovals }: { pendingApprovals: number }) {
  const [location] = useLocation();

  return (
    <nav className="flex flex-col gap-0.5 px-3 py-4">
      {NAV.map(({ href, label }) => {
        const active = location === href || (href !== "/dashboard" && location.startsWith(href));
        const badge = label === "Approvals" && pendingApprovals > 0 ? pendingApprovals : null;
        return (
          <Link
            key={href}
            href={href}
            className={`flex items-center justify-between rounded-lg px-3 py-2 text-sm font-medium transition-colors ${
              active
                ? "bg-blue-600 text-white"
                : "text-gray-600 hover:bg-blue-50 hover:text-blue-700"
            }`}
          >
            {label}
            {badge && (
              <span className="ml-auto flex h-5 min-w-[20px] items-center justify-center rounded-full bg-red-500 px-1.5 text-[10px] font-bold text-white">
                {badge}
              </span>
            )}
          </Link>
        );
      })}
    </nav>
  );
}
