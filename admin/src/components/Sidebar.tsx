"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "@/context/AuthContext";

const nav = [
  { href: "/dashboard", label: "Dashboard", icon: "🏠" },
  { href: "/shops", label: "Shops", icon: "🏪" },
  { href: "/queues", label: "Queues", icon: "📋" },
  { href: "/users", label: "Users", icon: "👥" },
  { href: "/reports", label: "Reports", icon: "📊" },
];

const statColors: Record<string, { bg: string; text: string; icon: string }> = {
  "Total Users":      { bg: "bg-blue-100",   text: "text-blue-600",   icon: "👥" },
  "Total Shops":      { bg: "bg-purple-100", text: "text-purple-600", icon: "🏪" },
  "Pending Approvals":{ bg: "bg-orange-100", text: "text-orange-600", icon: "⏳" },
  "Active Queues":    { bg: "bg-green-100",  text: "text-green-600",  icon: "✅" },
};

export function Sidebar() {
  const pathname = usePathname();
  const { logout, user } = useAuth();

  return (
    <aside className="w-64 min-h-screen bg-slate-900 text-white flex flex-col">
      {/* Logo */}
      <div className="p-6 border-b border-slate-700">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 bg-indigo-600 rounded-xl flex items-center justify-center text-lg">
            🎯
          </div>
          <div>
            <h1 className="text-lg font-bold leading-none">NexQ</h1>
            <p className="text-xs text-slate-400 mt-0.5">Admin Panel</p>
          </div>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex flex-col gap-1 flex-1 p-4">
        {nav.map((item) => {
          const isActive = pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors ${
                isActive
                  ? "bg-indigo-600 text-white"
                  : "text-slate-300 hover:bg-slate-800 hover:text-white"
              }`}
            >
              <span className="text-base">{item.icon}</span>
              {item.label}
            </Link>
          );
        })}
      </nav>

      {/* User + Sign out */}
      <div className="p-4 border-t border-slate-700">
        <div className="flex items-center gap-3 mb-3">
          <div className="w-8 h-8 bg-indigo-500 rounded-full flex items-center justify-center text-sm font-bold">
            {user?.email?.[0]?.toUpperCase() ?? "A"}
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-xs text-slate-400 truncate">{user?.email}</p>
            <p className="text-xs text-indigo-400 font-medium">Admin</p>
          </div>
        </div>
        <button
          onClick={logout}
          className="w-full flex items-center gap-2 text-sm text-slate-300 hover:text-white hover:bg-slate-800 rounded-lg px-3 py-2 transition-colors"
        >
          <span>🚪</span> Sign out
        </button>
      </div>
    </aside>
  );
}

export function StatsCard({
  title,
  value,
}: {
  title: string;
  value: string | number;
}) {
  const colors = statColors[title] ?? {
    bg: "bg-slate-100",
    text: "text-slate-600",
    icon: "📈",
  };

  return (
    <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm hover:shadow-md transition-shadow">
      <div className="flex items-center justify-between mb-4">
        <span className="text-slate-500 text-sm font-medium">{title}</span>
        <div className={`w-10 h-10 ${colors.bg} rounded-xl flex items-center justify-center text-lg`}>
          {colors.icon}
        </div>
      </div>
      <div className="text-3xl font-bold text-slate-800">{value}</div>
      <div className="text-xs text-slate-400 mt-1">
        {title === "Total Users" && "Registered accounts"}
        {title === "Total Shops" && "All registered shops"}
        {title === "Pending Approvals" && "Waiting for review"}
        {title === "Active Queues" && "Currently in queue"}
      </div>
    </div>
  );
}