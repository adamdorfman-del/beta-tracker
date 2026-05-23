import { useEffect, useState } from "react";
import { api } from "@/lib/api";

export type AppUser = { id: string; name: string; email: string; role: string };

let cached: AppUser | null | undefined = undefined;
const listeners: Array<() => void> = [];

function notify() { listeners.forEach(fn => fn()); }

export function useCurrentUser() {
  const [user, setUser] = useState<AppUser | null | undefined>(cached);

  useEffect(() => {
    const handler = () => setUser(cached);
    listeners.push(handler);
    return () => { listeners.splice(listeners.indexOf(handler), 1); };
  }, []);

  useEffect(() => {
    if (cached !== undefined) return;
    api.me.get()
      .then((d: any) => { cached = d.user ?? null; notify(); })
      .catch(() => { cached = null; notify(); });
  }, []);

  return user;
}

export function canWrite(user: AppUser | null | undefined) {
  return user?.role === "pm" || user?.role === "admin";
}
