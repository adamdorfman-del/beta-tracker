import { useEffect, useRef } from "react";

export function useInfiniteScroll(
  onLoadMore: () => void,
  enabled: boolean,
  rootRef?: React.RefObject<Element | null>,
) {
  const ref = useRef<HTMLDivElement>(null);
  const callbackRef = useRef(onLoadMore);
  callbackRef.current = onLoadMore;

  useEffect(() => {
    const el = ref.current;
    if (!el || !enabled) return;
    const obs = new IntersectionObserver(
      ([entry]) => { if (entry.isIntersecting) callbackRef.current(); },
      { root: rootRef?.current ?? null, rootMargin: "120px" },
    );
    obs.observe(el);
    return () => obs.disconnect();
  }, [enabled, rootRef?.current]); // eslint-disable-line react-hooks/exhaustive-deps

  return ref;
}
