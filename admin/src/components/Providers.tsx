"use client";

import { AuthProvider } from "@/context/AuthContext";
import { useEffect } from "react";

export function Providers({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    const onUnhandled = (e: PromiseRejectionEvent) => {
      // swallow noisy Firestore permission errors during dev, but log them
      // eslint-disable-next-line no-console
      console.error('unhandledRejection:', e.reason);
    };
    window.addEventListener('unhandledrejection', onUnhandled as EventListener);
    return () => window.removeEventListener('unhandledrejection', onUnhandled as EventListener);
  }, []);

  return <AuthProvider>{children}</AuthProvider>;
}
