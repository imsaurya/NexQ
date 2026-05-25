
'use client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { collection, onSnapshot, doc, updateDoc, Timestamp } from 'firebase/firestore';
import { getFirebaseDb } from '@/lib/firebase';

type Shop = {
  id: string; name: string; city: string; area: string;
  approvalStatus: string; ownerId: string; isActive: boolean;
};

const statusColors: Record<string, string> = {
  approved: 'bg-green-100 text-green-700',
  pending: 'bg-yellow-100 text-yellow-700',
  rejected: 'bg-red-100 text-red-700',
  banned: 'bg-gray-100 text-gray-700',
};

export default function ShopsPage() {
  const [shops, setShops] = useState<Shop[]>([]);
  const [filter, setFilter] = useState('all');

  const { role, hasFullAccess } = useAuth();

  useEffect(() => {
    if (role !== 'admin' || !hasFullAccess) return;
    // Real-time listener
    const unsub = onSnapshot(
      collection(getFirebaseDb(), 'shops'),
      (snap) => setShops(snap.docs.map(d => ({ id: d.id, ...d.data() } as Shop))),
      (err) => {
        // Firestore rules may block reads in dev — log and continue
        // eslint-disable-next-line no-console
        console.error('shops listener error', err);
      }
    );
    return unsub;
  }, [role, hasFullAccess]);

  const updateStatus = async (id: string, approvalStatus: string) => {
    try {
      await updateDoc(doc(getFirebaseDb(), 'shops', id), {
        approvalStatus,
        isActive: approvalStatus === 'approved',
        updatedAt: Timestamp.now(),
      });
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error('Failed to update shop status', err);
    }
  };

  const filtered = filter === 'all' ? shops : shops.filter(s => s.approvalStatus === filter);

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Shop Management</h1>
        <div className="flex gap-2">
          {['all','pending','approved','rejected','banned'].map(f => (
            <button key={f} onClick={() => setFilter(f)}
              className={`px-3 py-1 rounded-lg text-sm capitalize ${
                filter === f ? 'bg-indigo-600 text-white' : 'bg-slate-100 text-slate-600'
              }`}>
              {f}
            </button>
          ))}
        </div>
      </div>
      <div className="bg-white rounded-xl border border-slate-100 overflow-hidden">
        <table className="w-full text-left">
          <thead className="bg-slate-50 text-sm text-slate-500">
            <tr>
              <th className="p-4">Shop</th>
              <th className="p-4">Location</th>
              <th className="p-4">Status</th>
              <th className="p-4">Actions</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(shop => (
              <tr key={shop.id} className="border-t hover:bg-slate-50">
                <td className="p-4 font-medium">{shop.name}</td>
                <td className="p-4 text-slate-500">{shop.area}, {shop.city}</td>
                <td className="p-4">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium capitalize ${statusColors[shop.approvalStatus] ?? ''}`}>
                    {shop.approvalStatus}
                  </span>
                </td>
                <td className="p-4">
                  <div className="flex gap-2">
                    {shop.approvalStatus === 'pending' && (<>
                      <button onClick={() => updateStatus(shop.id, 'approved')}
                        className="px-3 py-1 bg-green-100 text-green-700 rounded-lg text-sm hover:bg-green-200">
                        Approve
                      </button>
                      <button onClick={() => updateStatus(shop.id, 'rejected')}
                        className="px-3 py-1 bg-red-100 text-red-700 rounded-lg text-sm hover:bg-red-200">
                        Reject
                      </button>
                    </>)}
                    {shop.approvalStatus !== 'banned' && (
                      <button onClick={() => updateStatus(shop.id, 'banned')}
                        className="px-3 py-1 bg-slate-100 text-slate-700 rounded-lg text-sm hover:bg-slate-200">
                        Ban
                      </button>
                    )}
                    {shop.approvalStatus === 'banned' && (
                      <button onClick={() => updateStatus(shop.id, 'approved')}
                        className="px-3 py-1 bg-green-100 text-green-700 rounded-lg text-sm">
                        Unban
                      </button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {filtered.length === 0 && (
          <div className="p-8 text-center text-slate-400">No shops found</div>
        )}
      </div>
    </div>
  );
}
