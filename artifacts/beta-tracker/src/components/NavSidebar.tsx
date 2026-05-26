import { Link, useLocation } from "wouter";

const NAV = [
  { href: "/dashboard",    label: "Dashboard" },
  { href: "/features",     label: "Beta Features" },
  { href: "/batches",      label: "Outreach" },
  { href: "/feedback",     label: "Feedback" },
  { href: "/clients",      label: "Clients" },
  { href: "/stakeholders", label: "Stakeholders" },
  { href: "/reports",      label: "Reports" },
];

export function NavSidebar() {
  const [location] = useLocation();

  return (
    <nav className="flex flex-col gap-0.5 px-3 py-4">
      {NAV.map(({ href, label }) => {
        const active = location === href || (href !== "/dashboard" && location.startsWith(href));
        return (
          <Link
            key={href}
            href={href}
            className={`flex items-center rounded-lg px-3 py-2 text-sm font-medium transition-colors ${
              active
                ? "bg-blue-600 text-white"
                : "text-gray-600 hover:bg-blue-50 hover:text-blue-700"
            }`}
          >
            {label}
          </Link>
        );
      })}
    </nav>
  );
}
