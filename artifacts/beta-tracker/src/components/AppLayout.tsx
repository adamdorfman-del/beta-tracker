import { useClerk, useUser } from "@clerk/react";
import { NavSidebar } from "./NavSidebar";

const basePath = import.meta.env.BASE_URL.replace(/\/$/, "");

export function AppLayout({ children }: { children: React.ReactNode }) {
  const { signOut } = useClerk();
  const { user } = useUser();

  const displayName =
    user?.firstName
      ? `${user.firstName}${user.lastName ? ` ${user.lastName}` : ""}`
      : user?.primaryEmailAddress?.emailAddress ?? "";

  return (
    <div className="flex min-h-screen bg-[#F0F4FF]">
      {/* Sidebar */}
      <aside className="hidden md:flex md:w-56 md:flex-col md:border-r md:border-gray-200 md:bg-white md:fixed md:inset-y-0 md:shadow-sm">
        {/* Logo / brand */}
        <div className="flex h-14 items-center gap-2.5 border-b border-gray-100 px-4">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-600 flex-shrink-0">
            <svg viewBox="0 0 20 20" fill="none" className="h-5 w-5">
              <path d="M10 3C6.134 3 3 6.134 3 10s3.134 7 7 7 7-3.134 7-7-3.134-7-7-7z" fill="white" opacity="0.3"/>
              <path d="M13.5 7.5C13.5 5.567 11.933 4 10 4V7.5h3.5z" fill="white"/>
              <path d="M10 4C8.067 4 6.5 5.567 6.5 7.5H10V4z" fill="white" opacity="0.7"/>
              <path d="M6.5 7.5C6.5 9.433 8.067 11 10 11V7.5H6.5z" fill="white" opacity="0.5"/>
              <path d="M10 11c1.933 0 3.5-1.567 3.5-3.5H10V11z" fill="white" opacity="0.85"/>
            </svg>
          </div>
          <div>
            <span className="text-sm font-semibold text-gray-900 leading-tight block">Beta Tracker</span>
            <span className="text-[10px] text-blue-500 font-medium leading-tight block">by Birdeye</span>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto">
          <NavSidebar />
        </div>

        {/* User footer */}
        <div className="border-t border-gray-100 p-3">
          <div className="flex items-center gap-2">
            {user?.imageUrl ? (
              <img
                src={user.imageUrl}
                alt={displayName}
                className="h-7 w-7 rounded-full object-cover flex-shrink-0"
              />
            ) : (
              <div className="h-7 w-7 rounded-full bg-blue-100 flex-shrink-0 flex items-center justify-center">
                <span className="text-xs font-semibold text-blue-600">
                  {displayName.charAt(0).toUpperCase()}
                </span>
              </div>
            )}
            <div className="min-w-0 flex-1">
              <p className="truncate text-xs font-medium text-gray-900">{displayName}</p>
            </div>
            <button
              onClick={() => signOut({ redirectUrl: `${basePath}/sign-in` })}
              title="Sign out"
              className="flex-shrink-0 rounded p-1 text-gray-400 hover:bg-gray-100 hover:text-gray-600"
            >
              <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
              </svg>
            </button>
          </div>
        </div>
      </aside>

      {/* Main content */}
      <div className="flex flex-1 flex-col md:ml-56">
        <header className="flex h-14 items-center justify-between border-b border-gray-200 bg-white px-4 md:hidden">
          <div className="flex items-center gap-2">
            <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-blue-600">
              <span className="text-xs font-bold text-white">BT</span>
            </div>
            <span className="text-sm font-semibold text-gray-900">Beta Tracker</span>
          </div>
          <button
            onClick={() => signOut({ redirectUrl: `${basePath}/sign-in` })}
            className="text-xs text-gray-500 hover:text-gray-700"
          >
            Sign out
          </button>
        </header>
        <main className="flex-1 p-4 md:p-8">{children}</main>
      </div>
    </div>
  );
}
