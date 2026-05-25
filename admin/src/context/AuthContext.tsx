"use client";

import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import { onAuthStateChanged, signInWithEmailAndPassword, signOut, User } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { getFirebaseAuth, getFirebaseDb } from "@/lib/firebase";

type AuthContextType = {
  user: User | null;
  role: string | null;
  loading: boolean;
  hasFullAccess: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
};

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [role, setRole] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [hasFullAccess, setHasFullAccess] = useState(false);

  useEffect(() => {
    const unsub = onAuthStateChanged(getFirebaseAuth(), async (u) => {
      setLoading(true);
      setUser(u);
      if (u) {
        try {
          const db = getFirebaseDb();
          const snap = await getDoc(doc(db, "users", u.uid));
          if (snap.exists()) {
            const data = snap.data();
            setRole(data?.role ?? null);
            setHasFullAccess(true);
          } else {
            // No user document — try env-based fallback for admin emails
            const fallback = process.env.NEXT_PUBLIC_FALLBACK_ADMIN_EMAILS ?? "";
            const list = fallback.split(",").map((s) => s.trim()).filter(Boolean);
            const email = u.email ?? "";
            if (list.includes(email)) {
              // Firestore write may be blocked by rules in dev; grant role locally so admin can access dashboard
              setRole("admin");
              setHasFullAccess(false);
              // eslint-disable-next-line no-console
              console.log("Applied fallback admin role for", email);
            } else {
              setRole(null);
              setHasFullAccess(false);
            }
          }
        } catch (err) {
          // log and fall back to null role
          // eslint-disable-next-line no-console
          console.error("Error loading user role:", err);
          setRole(null);
          setHasFullAccess(false);
        }
      } else {
        setRole(null);
        setHasFullAccess(false);
      }
      setLoading(false);
    });

    return () => unsub();
  }, []);

  const login = async (email: string, password: string) => {
    await signInWithEmailAndPassword(getFirebaseAuth(), email, password);
  };

  const logout = async () => {
    await signOut(getFirebaseAuth());
  };

  return (
    <AuthContext.Provider value={{ user, role, loading, hasFullAccess, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
