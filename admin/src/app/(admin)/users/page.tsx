
'use client';
import { useEffect, useState } from 'react';
import { collection, onSnapshot, doc, updateDoc } from 'firebase/firestore';
import { getFirebaseDb } from '../../lib/firebase';

type User = {
  id: string;
  displayName: string;
  email: string;
  role: string;
  isActive: boolean;
};

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);

  useEffect(() => {
    const unsub = onSnapshot(collection(getFirebaseDb(), 'users'), (snap) => {
      setUsers(snap.docs.map((d) => ({ id: d.id, ...d.data() } as User)));
    });
    return unsub;
  }, []);

  const updateUserRole = async (id: string, currentRole: string) => {
    const newRole = currentRole === 'customer' ? 'shop_owner' : 'customer';
    await updateDoc(doc(getFirebaseDb(), 'users', id), {
      role: newRole,
    });
  };

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">User Management</h1>
      <div className="bg-white rounded-xl border border-slate-100 overflow-hidden">
        <table className="w-full text-left">
          <thead className="bg-slate-50 text-sm text-slate-500">
            <tr>
              <th className="p-4">Name</th>
              <th className="p-4">Email</th>
              <th className="p-4">Role</th>
              <th className="p-4">Status</th>
              <th className="p-4">Actions</th>
            </tr>
          </thead>
          <tbody>
            {users.map((user) => (
              <tr key={user.id} className="border-t hover:bg-slate-50">
                <td className="p-4 font-medium">{user.displayName}</td>
                <td className="p-4 text-slate-500">{user.email}</td>
                <td className="p-4 capitalize">{user.role?.replace('_', ' ')}</td>
                <td className="p-4">{user.isActive !== false ? 'Active' : 'Disabled'}</td>
                <td className="p-4">
                  <button
                    onClick={() => updateUserRole(user.id, user.role)}
                    className="px-3 py-1 bg-indigo-100 text-indigo-700 rounded-lg text-sm hover:bg-indigo-200"
                  >
                    Change to {user.role === 'customer' ? 'Shop Owner' : 'Customer'}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {users.length === 0 && (
          <div className="p-8 text-center text-slate-400">No users found</div>
        )}
      </div>
    </div>
  );
}
