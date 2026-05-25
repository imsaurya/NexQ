'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import {
  collection,
  query,
  where,
  onSnapshot,
  Timestamp,
} from 'firebase/firestore';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  CartesianGrid,
} from 'recharts';
import { getFirebaseDb } from '@/lib/firebase';
import { StatsCard } from '@/components/Sidebar';

export default function DashboardPage() {
  const [stats, setStats] = useState({
    users: 0,
    shops: 0,
    pendingShops: 0,
    activeQueues: 0,
  });
  // ✅ Fix 1: useState was missing the opening `<` for its generic type
  const [chartData, setChartData] = useState<
    { hour: string; count: number }[]
  >([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const db = getFirebaseDb();

    const unsubUsers = onSnapshot(collection(db, 'users'), (snap) => {
      setStats((prev) => ({ ...prev, users: snap.size }));
      setLoading(false);
    });

    const unsubShops = onSnapshot(collection(db, 'shops'), (snap) => {
      setStats((prev) => ({ ...prev, shops: snap.size }));
    });

    const unsubPending = onSnapshot(
      query(collection(db, 'shops'), where('approvalStatus', '==', 'pending')),
      (snap) => {
        setStats((prev) => ({ ...prev, pendingShops: snap.size }));
      }
    );

    const unsubQueues = onSnapshot(
      query(collection(db, 'queue_requests'), where('status', '==', 'pending')),
      (snap) => {
        setStats((prev) => ({ ...prev, activeQueues: snap.size }));
      }
    );

    const unsubChart = onSnapshot(
      collection(db, 'queue_requests'),
      (snap) => {
        const hourlyCounts: Record<string, number> = {};
        snap.docs.forEach((doc) => {
          const ts = doc.data().createdAt as Timestamp;
          if (ts) {
            const hour = ts.toDate().getHours();
            const key = `${hour}:00`;
            hourlyCounts[key] = (hourlyCounts[key] || 0) + 1;
          }
        });

        const sorted = Object.keys(hourlyCounts)
          .sort((a, b) => parseInt(a) - parseInt(b))
          .map((hour) => ({ hour, count: hourlyCounts[hour] }));

        setChartData(sorted);
      }
    );

    return () => {
      unsubUsers();
      unsubShops();
      unsubPending();
      unsubQueues();
      unsubChart();
    };
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600" />
      </div>
    );
  }

  return (
    <div>
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-slate-800">Dashboard</h1>
        <p className="text-slate-500 text-sm mt-1">
          Welcome back! Here's what's happening with NexQ.
        </p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4 mb-8">
        <StatsCard title="Total Users" value={stats.users} />
        <StatsCard title="Total Shops" value={stats.shops} />
        <StatsCard title="Pending Approvals" value={stats.pendingShops} />
        <StatsCard title="Active Queues" value={stats.activeQueues} />
      </div>

      {/* Chart */}
      <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h2 className="font-semibold text-slate-800">
              Queue Requests by Hour
            </h2>
            <p className="text-sm text-slate-400 mt-0.5">
              All time queue activity
            </p>
          </div>
          <div className="w-3 h-3 bg-green-400 rounded-full animate-pulse" />
        </div>

        {chartData.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-64 text-slate-400">
            <span className="text-4xl mb-3">📊</span>
            <p className="text-sm">No queue data yet</p>
          </div>
        ) : (
          <ResponsiveContainer width="100%" height={280}>
            <BarChart
              data={chartData}
              margin={{ top: 0, right: 0, left: -20, bottom: 0 }}
            >
              <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
              <XAxis
                dataKey="hour"
                tick={{ fontSize: 12, fill: '#94a3b8' }}
                axisLine={false}
                tickLine={false}
              />
              <YAxis
                tick={{ fontSize: 12, fill: '#94a3b8' }}
                axisLine={false}
                tickLine={false}
              />
              <Tooltip
                contentStyle={{
                  borderRadius: '12px',
                  border: 'none',
                  boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
                }}
              />
              <Bar
                dataKey="count"
                fill="#6366f1"
                radius={[6, 6, 0, 0]}
                name="Requests"
              />
            </BarChart>
          </ResponsiveContainer>
        )}
      </div>

      {/* Quick actions */}
      {/* ✅ Fix 2: All three cards were missing their opening <Link> tag */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mt-6">
        <Link
          href="/shops"
          className="bg-white rounded-2xl p-5 border border-slate-100 shadow-sm hover:shadow-md transition-shadow flex items-center gap-4"
        >
          <div className="w-12 h-12 bg-orange-100 rounded-xl flex items-center justify-center text-2xl">
            ⏳
          </div>
          <div>
            <p className="font-semibold text-slate-800">
              {stats.pendingShops} Pending
            </p>
            <p className="text-sm text-slate-400">Shops need review</p>
          </div>
        </Link>

        <Link
          href="/users"
          className="bg-white rounded-2xl p-5 border border-slate-100 shadow-sm hover:shadow-md transition-shadow flex items-center gap-4"
        >
          <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center text-2xl">
            👥
          </div>
          <div>
            <p className="font-semibold text-slate-800">
              {stats.users} Users
            </p>
            <p className="text-sm text-slate-400">Total registered</p>
          </div>
        </Link>

        <Link
          href="/queues"
          className="bg-white rounded-2xl p-5 border border-slate-100 shadow-sm hover:shadow-md transition-shadow flex items-center gap-4"
        >
          <div className="w-12 h-12 bg-green-100 rounded-xl flex items-center justify-center text-2xl">
            📋
          </div>
          <div>
            <p className="font-semibold text-slate-800">
              {stats.activeQueues} Active
            </p>
            <p className="text-sm text-slate-400">Queue requests</p>
          </div>
        </Link>
      </div>
    </div>
  );
}