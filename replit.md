# Beta Tracker

Internal tool for managing software beta programs — features, client nominations, CSM approvals, outreach batches, and reporting.

## Run & Operate

- `pnpm --filter @workspace/api-server run dev` — run the API server (port 5000 / $PORT)
- `pnpm --filter @workspace/beta-tracker run dev` — run the Vite frontend
- `pnpm run typecheck` — full typecheck across all packages
- `pnpm run build` — typecheck + build all packages
- `pnpm --filter @workspace/db run push` — push DB schema changes (dev only)
- `pnpm --filter @workspace/db run seed` — seed the database with demo data
- Required env: `DATABASE_URL` — Postgres connection string

## Stack

- pnpm workspaces, Node.js 24, TypeScript 5.9
- Frontend: React + Vite + Tailwind CSS + wouter (routing) + recharts (charts)
- API: Express 5 at `/api`
- DB: PostgreSQL + Drizzle ORM
- Validation: Zod (`zod/v4`), `drizzle-zod`
- Build: esbuild (CJS bundle)

## Where things live

- `lib/db/src/schema/` — Drizzle schema (users, betaFeatures, clients, enrollments, batches, auditLogs)
- `lib/db/src/index.ts` — DB connection & re-exports
- `lib/db/src/seed.ts` — demo seed script
- `artifacts/api-server/src/routes/` — Express route files (features, enrollments, clients, batches, reports, users)
- `artifacts/beta-tracker/src/pages/` — React page components
- `artifacts/beta-tracker/src/components/` — shared UI components (NavSidebar, StatusBadge, HealthDot, SlotFill, etc.)
- `artifacts/beta-tracker/src/lib/api.ts` — typed API client for the frontend
- `artifacts/beta-tracker/src/lib/types.ts` — shared TypeScript types

## Architecture decisions

- No auth: all write operations use the first `admin` role user as actor; designed for internal use only
- DB schema imports must use `.ts` extensions due to Node 24's ESM strip-types mode
- Frontend uses Tailwind utility classes directly (no shadcn/ui components) for simplicity
- Enrollments list endpoint enriches data server-side (client + feature + CSM info) to avoid N+1 in the UI
- Outreach batches are created by a "trigger" mechanism (group approved enrollments by client)

## Product

- **Dashboard**: KPI cards, at-risk features, stale approval alerts
- **Features**: List/filter/create/view beta features with slot fill bars; nominate testers inline; close/clone betas
- **Clients**: List with health dots, tier, CSM owner; expandable beta history
- **Approvals**: Pending CSM approvals queue with approve/reject actions
- **Batches**: Outreach batch management; trigger grouping; send with cooldown enforcement
- **Reports**: Beta duration chart, outreach funnel, client completion rates, CSM responsiveness table

## User preferences

_Populate as you build — explicit user instructions worth remembering across sessions._

## Gotchas

- Schema files must use `.ts` extensions in imports for Node 24's `--experimental-strip-types` mode
- Run `pnpm --filter @workspace/db run push` after schema changes, then restart the API server
- The seed script is idempotent — re-running it skips already-seeded tables
- API enriches enrollment data server-side; the frontend expects `client`, `feature`, `csmOwner` nested objects

## Pointers

- See the `pnpm-workspace` skill for workspace structure, TypeScript setup, and package details
