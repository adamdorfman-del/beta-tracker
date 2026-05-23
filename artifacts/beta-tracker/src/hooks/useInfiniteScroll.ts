import { useEffect, useRef } from "react";

export function useInfiniteScroll(onLoadMore: () => void, enabled: boolean) {
  const ref = useRef<HTMLDivElement>(null);
  const callbackRef = useRef(onLoadMore);
  callbackRef.current = onLoadMore;

  useEffect(() => {
    const el = ref.current;
    if (!el || !enabled) return;
    const obs = new IntersectionObserver(
      ([entry]) => { if (entry.isIntersecting) callbackRef.current(); },
      { rootMargin: "300px" }
    );
    obs.observe(el);
    return () => obs.disconnect();
  }, [enabled]);

  return ref;
}
