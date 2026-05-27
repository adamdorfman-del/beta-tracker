import { useEffect, useState } from "react";
import { Link, useLocation } from "wouter";

const MAIN_NAV = [
  { href: "/dashboard",    label: "Dashboard" },
  { href: "/features",     label: "Beta Features" },
  { href: "/batches",      label: "Outreach" },
  { href: "/feedback",     label: "Feedback" },
  { href: "/reports",      label: "Reports" },
];

const ADMIN_NAV = [
  { href: "/clients",      label: "Clients" },
  { href: "/stakeholders", label: "Stakeholders" },
];

const STORAGE_KEY = "nav-admin-open";

function ChevronIcon({ open }: { open: boolean }) {
  return (
    <svg
      className={`h-3.5 w-3.5 transition-transform duration-150 ${open ? "rotate-90" : ""}`}
      viewBox="0 0 16 16"
      fill="currentColor"
    >
      <path d="M6 4l4 4-4 4V4z" />
    </svg>
  );
}

export function NavSidebar() {
  const [location] = useLocation();
  const adminActive = ADMIN_NAV.some(({ href }) => location === href || location.startsWith(href));

  const [open, setOpen] = useState<boolean>(() => {
    if (adminActive) return true;
    try {
      return localStorage.getItem(STORAGE_KEY) === "true";
    } catch {
      return false;
    }
  });

  useEffect(() => {
    if (adminActive) setOpen(true);
  }, [adminActive]);

  function toggle() {
    const next = !open;
    setOpen(next);
    try { localStorage.setItem(STORAGE_KEY, String(next)); } catch {}
  }

  return (
    <nav className="flex flex-col gap-0.5 px-3 py-4">
      {MAIN_NAV.map(({ href, label }) => {
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

      <div className="mx-1 my-2 border-t border-gray-200/70" />

      <button
        onClick={toggle}
        className="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm font-medium text-gray-500 hover:bg-blue-50 hover:text-blue-700 transition-colors"
      >
        <ChevronIcon open={open} />
        Admin
      </button>

      {open && (
        <div className="flex flex-col gap-0.5">
          {ADMIN_NAV.map(({ href, label }) => {
            const active = location === href || location.startsWith(href);
            return (
              <Link
                key={href}
                href={href}
                className={`flex items-center rounded-lg py-2 pr-3 pl-8 text-sm font-medium transition-colors ${
                  active
                    ? "bg-blue-600 text-white"
                    : "text-gray-600 hover:bg-blue-50 hover:text-blue-700"
                }`}
              >
                {label}
              </Link>
            );
          })}
        </div>
      )}
    </nav>
  );
}
