export default function ReportsPage() {
  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Reports</h1>
      <div className="grid gap-4 md:grid-cols-2">
        <div className="bg-white rounded-xl p-6 border border-slate-100">
          <h2 className="font-semibold mb-2">Daily Summary</h2>
          <p className="text-slate-500 text-sm">
            Export queue and shop analytics from Firestore. Connect BigQuery later for advanced reports on the free tier.
          </p>
        </div>
        <div className="bg-white rounded-xl p-6 border border-slate-100">
          <h2 className="font-semibold mb-2">Flagged Shops</h2>
          <p className="text-slate-500 text-sm">
            Review banned or rejected shops from the Shops page. Use reports for compliance audits.
          </p>
        </div>
      </div>
    </div>
  );
}
