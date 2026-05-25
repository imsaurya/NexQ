"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/context/AuthContext";

export default function LoginPage() {
  console.log("LOGIN PAGE RENDERED"); // ← debug line

  const { login, user, role, loading } = useAuth();
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  console.log("AUTH STATE:", { user: user?.email, role, loading }); // ← debug line

  useEffect(() => {
    if (!loading && user && role === "admin") {
      router.replace("/dashboard");
    }
  }, [user, role, loading, router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    console.log("BUTTON CLICKED"); // ← debug line
    setError("");
    setIsSubmitting(true);
    try {
      console.log("CALLING LOGIN..."); // ← debug line
      await login(email, password);
      console.log("LOGIN SUCCESS"); // ← debug line
    } catch (err: any) {
      console.log("LOGIN ERROR:", err.message); // ← debug line
      setError(err.message);
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-900">
      <form onSubmit={handleSubmit} className="bg-white p-8 rounded-xl w-full max-w-md shadow-lg">
        <h1 className="text-2xl font-bold mb-2">NexQ Admin</h1>
        <p className="text-slate-500 mb-6">Sign in with your admin account</p>
        {error && <p className="text-red-600 text-sm mb-4">{error}</p>}
        <input
          type="email"
          placeholder="Email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="w-full border rounded-lg px-4 py-3 mb-4"
          required
          disabled={isSubmitting}
        />
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="w-full border rounded-lg px-4 py-3 mb-6"
          required
          disabled={isSubmitting}
        />
        <button
          type="submit"
          disabled={isSubmitting}
          className="w-full bg-indigo-600 text-white py-3 rounded-lg font-medium hover:bg-indigo-700 disabled:opacity-60"
        >
          {isSubmitting ? "Signing in..." : "Sign In"}
        </button>
      </form>
    </div>
  );
}