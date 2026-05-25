"use client";

import { useEffect, useState } from "react";
import { collection, getDocs } from "firebase/firestore";
import { getFirebaseDb } from "@/lib/firebase";

type QueueRequest = {
  id: string;
  shopId: string;
  customerName: string;
  serviceName: string;
  status: string;
  tokenNumber?: number;
};

export default function QueuesPage() {
  const [requests, setRequests] = useState<QueueRequest[]>([]);

  useEffect(() => {
    getDocs(collection(getFirebaseDb(), "queue_requests")).then((snap) => {
      setRequests(
        snap.docs
          .map((d) => ({ id: d.id, ...d.data() } as QueueRequest))
          .slice(0, 100),
      );
    });
  }, []);

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Queue Monitoring</h1>
      <div className="bg-white rounded-xl border border-slate-100 overflow-hidden">
        <table className="w-full text-left">
          <thead className="bg-slate-50 text-sm text-slate-500">
            <tr>
              <th className="p-4">Customer</th>
              <th className="p-4">Service</th>
              <th className="p-4">Token</th>
              <th className="p-4">Status</th>
              <th className="p-4">Shop</th>
            </tr>
          </thead>
          <tbody>
            {requests.map((r) => (
              <tr key={r.id} className="border-t">
                <td className="p-4">{r.customerName}</td>
                <td className="p-4">{r.serviceName}</td>
                <td className="p-4">{r.tokenNumber ?? "-"}</td>
                <td className="p-4 capitalize">{r.status}</td>
                <td className="p-4 text-xs text-slate-500">{r.shopId.slice(0, 8)}...</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
