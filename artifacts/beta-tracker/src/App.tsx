import { useEffect, useRef, useState } from "react";
import { ClerkProvider, SignIn, Show, useClerk, useUser } from "@clerk/react";
import { publishableKeyFromHost } from "@clerk/react/internal";
import { shadcn } from "@clerk/themes";
import { Switch, Route, Redirect, Router as WouterRouter, useLocation } from "wouter";
import { AppLayout } from "@/components/AppLayout";
import { api } from "@/lib/api";
import DashboardPage from "@/pages/Dashboard";
import FeaturesPage from "@/pages/Features";
import FeatureDetailPage from "@/pages/FeatureDetail";
import ClientsPage from "@/pages/Clients";
import BatchesPage from "@/pages/Batches";
import ReportsPage from "@/pages/Reports";
import StakeholdersPage from "@/pages/Stakeholders";
import FeedbackPage from "@/pages/Feedback";

const clerkPubKey = publishableKeyFromHost(
  window.location.hostname,
  import.meta.env.VITE_CLERK_PUBLISHABLE_KEY,
);

const clerkProxyUrl = import.meta.env.VITE_CLERK_PROXY_URL;

const basePath = import.meta.env.BASE_URL.replace(/\/$/, "");

function stripBase(path: string): string {
  return basePath && path.startsWith(basePath)
    ? path.slice(basePath.length) || "/"
    : path;
}

if (!clerkPubKey) {
  throw new Error("Missing VITE_CLERK_PUBLISHABLE_KEY");
}

const clerkAppearance = {
  theme: shadcn,
  cssLayerName: "clerk",
  options: {
    logoPlacement: "inside" as const,
    logoLinkUrl: basePath || "/",
    logoImageUrl: `${window.location.origin}${basePath}/logo.svg`,
  },
  variables: {
    colorPrimary: "#1A73E8",
    colorForeground: "#0f1b2d",
    colorMutedForeground: "#6b7280",
    colorDanger: "#dc2626",
    colorBackground: "#ffffff",
    colorInput: "#f0f4ff",
    colorInputForeground: "#0f1b2d",
    colorNeutral: "#e2e8f0",
    fontFamily: "'Inter', system-ui, -apple-system, sans-serif",
    borderRadius: "0.5rem",
  },
  elements: {
    rootBox: "w-full flex justify-center",
    cardBox: "bg-white rounded-2xl w-[440px] max-w-full overflow-hidden shadow-xl border border-blue-100",
    card: "!shadow-none !border-0 !bg-transparent !rounded-none",
    footer: "!shadow-none !border-0 !bg-transparent !rounded-none",
    headerTitle: "text-gray-900 font-semibold",
    headerSubtitle: "text-gray-500",
    socialButtonsBlockButtonText: "text-gray-700 font-medium",
    formFieldLabel: "text-gray-700",
    footerActionLink: "text-blue-600 font-medium",
    footerActionText: "text-gray-500",
    dividerText: "text-gray-400",
    identityPreviewEditButton: "text-blue-600",
    formFieldSuccessText: "text-green-600",
    alertText: "text-gray-700",
    logoBox: "flex justify-center",
    logoImage: "h-10 w-10 rounded-lg",
    socialButtonsBlockButton: "border border-gray-200 hover:bg-blue-50",
    formButtonPrimary: "bg-blue-600 hover:bg-blue-700 text-white",
    formFieldInput: "border-blue-100 bg-blue-50 text-gray-900",
    footerAction: "bg-blue-50",
    dividerLine: "bg-gray-200",
    alert: "border-red-100 bg-red-50",
    otpCodeFieldInput: "border-blue-200",
    formFieldRow: "",
    main: "",
  },
};

function SignInPage() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-[#F0F4FF] px-4">
      <div className="mb-8 text-center">
        <h1 className="text-2xl font-bold text-gray-900">Beta Tracker</h1>
        <p className="mt-1 text-sm text-gray-500">
          Sign in with your Birdeye Google account
        </p>
      </div>
      <SignIn
        routing="path"
        path={`${basePath}/sign-in`}
        signUpUrl={`${basePath}/sign-in`}
      />
    </div>
  );
}

function DomainError() {
  const { user, isLoaded } = useUser();
  const { signOut } = useClerk();

  if (!isLoaded) return null;

  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-4 bg-gray-50 px-4 text-center">
      <div className="rounded-full bg-red-100 p-4">
        <svg
          className="h-8 w-8 text-red-600"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M12 9v2m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"
          />
        </svg>
      </div>
      <h2 className="text-xl font-semibold text-gray-900">Access Restricted</h2>
      <p className="max-w-sm text-sm text-gray-500">
        This app is only available to <strong>@birdeye.com</strong> accounts.
        You are signed in as{" "}
        <strong>{user?.primaryEmailAddress?.emailAddress}</strong>.
      </p>
      <button
        onClick={() => signOut({ redirectUrl: `${basePath}/sign-in` })}
        className="mt-2 rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800"
      >
        Sign out
      </button>
    </div>
  );
}

const REAUTH_WINDOW_MS = 3 * 24 * 60 * 60 * 1000; // 3 days
const REAUTH_FROM_KEY = "reauth_from";

function ReauthPage() {
  const { signOut } = useClerk();

  function handleSignInAgain() {
    signOut({ redirectUrl: `${basePath}/sign-in` });
  }

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-[#F0F4FF] px-4 text-center">
      <div className="mb-6 flex h-14 w-14 items-center justify-center rounded-full bg-blue-100">
        <svg className="h-7 w-7 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
            d="M12 15v2m0-6v.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" />
        </svg>
      </div>
      <h1 className="text-xl font-semibold text-gray-900">Session expired</h1>
      <p className="mt-2 max-w-sm text-sm text-gray-500">
        Your session has expired. Please sign in again with your Birdeye Google account to continue.
      </p>
      <button
        onClick={handleSignInAgain}
        className="mt-6 rounded-lg bg-blue-600 px-5 py-2.5 text-sm font-medium text-white hover:bg-blue-700"
      >
        Sign in again
      </button>
    </div>
  );
}

function Spinner() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="h-6 w-6 animate-spin rounded-full border-2 border-gray-900 border-t-transparent" />
    </div>
  );
}

function AppRoutes() {
  const { user, isLoaded } = useUser();
  const [location, navigate] = useLocation();
  const [reauthState, setReauthState] = useState<"loading" | "ready" | "completing">("loading");

  const isBirdeyeUser = !!user?.emailAddresses.some((e) =>
    e.emailAddress.endsWith("@birdeye.com"),
  );

  useEffect(() => {
    if (!isLoaded || !user) return;

    // Non-birdeye users skip the check; domain error renders instead
    if (!isBirdeyeUser) {
      setReauthState("ready");
      return;
    }

    api.me.get().then((d: any) => {
      const lastAuth: string | null = d.user?.lastAuthAt ?? null;
      const stale = !lastAuth || Date.now() - new Date(lastAuth).getTime() > REAUTH_WINDOW_MS;

      if (!stale) {
        setReauthState("ready");
        return;
      }

      const pendingFrom = sessionStorage.getItem(REAUTH_FROM_KEY);

      if (pendingFrom !== null) {
        // Returning after sign-in during the reauth flow — stamp lastAuthAt then continue
        setReauthState("completing");
        api.auth.reauth()
          .then(() => {
            sessionStorage.removeItem(REAUTH_FROM_KEY);
            setReauthState("ready");
            navigate(pendingFrom || "/dashboard");
          })
          .catch(() => {
            // On error don't block access
            sessionStorage.removeItem(REAUTH_FROM_KEY);
            setReauthState("ready");
          });
      } else {
        // First time hitting the wall — save destination and send to /reauth
        const from = location === "/reauth" ? "/dashboard" : location;
        sessionStorage.setItem(REAUTH_FROM_KEY, from);
        setReauthState("ready");
        navigate("/reauth");
      }
    }).catch(() => {
      // API error — don't block
      setReauthState("ready");
    });
  }, [isLoaded, user?.id]);

  if (!isLoaded || reauthState === "loading" || reauthState === "completing") {
    return <Spinner />;
  }

  if (!isBirdeyeUser) return <DomainError />;

  return (
    <Switch>
      <Route path="/reauth" component={ReauthPage} />
      <Route component={() => (
        <AppLayout>
          <Switch>
            <Route path="/" component={() => <Redirect to="/dashboard" />} />
            <Route path="/dashboard" component={DashboardPage} />
            <Route path="/features" component={FeaturesPage} />
            <Route path="/features/:id" component={FeatureDetailPage} />
            <Route path="/clients" component={ClientsPage} />
            <Route path="/approvals" component={() => <Redirect to="/features" />} />
            <Route path="/batches" component={BatchesPage} />
            <Route path="/feedback" component={FeedbackPage} />
            <Route path="/reports" component={ReportsPage} />
            <Route path="/stakeholders" component={StakeholdersPage} />
            <Route
              component={() => (
                <div className="py-16 text-center">
                  <h1 className="text-2xl font-semibold text-gray-900">Page not found</h1>
                </div>
              )}
            />
          </Switch>
        </AppLayout>
      )} />
    </Switch>
  );
}

function ClerkQueryCacheInvalidator() {
  const { addListener } = useClerk();
  const prevUserIdRef = useRef<string | null | undefined>(undefined);

  useEffect(() => {
    const unsubscribe = addListener(({ user }) => {
      const userId = user?.id ?? null;
      if (
        prevUserIdRef.current !== undefined &&
        prevUserIdRef.current !== userId
      ) {
        window.location.reload();
      }
      prevUserIdRef.current = userId;
    });
    return unsubscribe;
  }, [addListener]);

  return null;
}

function ClerkProviderWithRoutes() {
  const [, setLocation] = useLocation();

  return (
    <ClerkProvider
      publishableKey={clerkPubKey}
      proxyUrl={clerkProxyUrl}
      appearance={clerkAppearance}
      signInUrl={`${basePath}/sign-in`}
      signUpUrl={`${basePath}/sign-in`}
      routerPush={(to) => setLocation(stripBase(to))}
      routerReplace={(to) => setLocation(stripBase(to), { replace: true })}
    >
      <ClerkQueryCacheInvalidator />
      <Switch>
        <Route path="/sign-in/*?" component={SignInPage} />
        <Route
          component={() => (
            <>
              <Show when="signed-out">
                <Redirect to="/sign-in" />
              </Show>
              <Show when="signed-in">
                <AppRoutes />
              </Show>
            </>
          )}
        />
      </Switch>
    </ClerkProvider>
  );
}

function App() {
  return (
    <WouterRouter base={basePath}>
      <ClerkProviderWithRoutes />
    </WouterRouter>
  );
}

export default App;
