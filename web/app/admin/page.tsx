'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import { getSupabaseBrowserClient } from '@/lib/supabase-browser';

type AdminMetrics = {
  generated_at: string;
  profile_count: number;
  connection_counts: {
    connected: number;
    pending: number;
    error: number;
    disconnected: number;
  };
  stale_sync_count_24h: number;
  seven_day_averages: {
    steps: number | null;
    sleep_minutes: number | null;
    active_minutes: number | null;
  };
  open_issues: Array<{
    user_id: string;
    name: string;
    trial_cohort: string;
    status: string;
    last_sync_at: string | null;
    updated_at: string;
  }>;
};

type TrialUserRow = {
  user_id: string;
  name: string;
  trial_cohort: string;
  connection_status: string;
  last_sync_at: string | null;
};

function statusBadgeClass(status: string): string {
  switch (status) {
    case 'connected':
      return 'badge badge-connected';
    case 'pending':
      return 'badge badge-pending';
    case 'error':
      return 'badge badge-error';
    default:
      return 'badge badge-disconnected';
  }
}

export default function AdminPage() {
  const router = useRouter();
  const supabase = getSupabaseBrowserClient();
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState<string | null>(null);
  const [accessToken, setAccessToken] = useState<string | null>(null);
  const [metrics, setMetrics] = useState<AdminMetrics | null>(null);
  const [users, setUsers] = useState<TrialUserRow[]>([]);

  const authHeaders = useMemo(
    () => accessToken ? { Authorization: `Bearer ${accessToken}` } : {},
    [accessToken],
  );

  const loadDashboard = useCallback(async () => {
    if (!accessToken) {
      return;
    }

    setLoading(true);
    setMessage(null);
    try {
      const [metricsResponse, usersResponse] = await Promise.all([
        fetch('/api/admin/metrics', { headers: authHeaders }),
        fetch('/api/admin/users', { headers: authHeaders }),
      ]);

      if (!metricsResponse.ok) {
        throw new Error(await metricsResponse.text());
      }
      if (!usersResponse.ok) {
        throw new Error(await usersResponse.text());
      }

      const metricsBody = (await metricsResponse.json()) as AdminMetrics;
      const usersBody = (await usersResponse.json()) as { rows: TrialUserRow[] };
      setMetrics(metricsBody);
      setUsers(usersBody.rows);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed loading admin data';
      setMessage(message);
    } finally {
      setLoading(false);
    }
  }, [accessToken, authHeaders]);

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      if (!data.session) {
        router.replace('/');
        return;
      }
      setAccessToken(data.session.access_token);
    });
  }, [router, supabase]);

  useEffect(() => {
    loadDashboard();
  }, [loadDashboard]);

  async function signOut() {
    await supabase.auth.signOut();
    router.replace('/');
  }

  async function exportCSV() {
    if (!accessToken) return;
    setMessage(null);
    const response = await fetch('/api/admin/export', {
      headers: authHeaders,
    });
    if (!response.ok) {
      setMessage(await response.text());
      return;
    }
    const blob = await response.blob();
    const href = URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = href;
    anchor.download = `biometrics_daily_${new Date().toISOString().slice(0, 10)}.csv`;
    anchor.click();
    URL.revokeObjectURL(href);
  }

  async function flagIssue(userId: string) {
    if (!accessToken) return;
    const note = window.prompt('Issue note (required):');
    if (!note || !note.trim()) return;

    const response = await fetch('/api/admin/flag-issue', {
      method: 'POST',
      headers: {
        ...authHeaders,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ user_id: userId, note: note.trim() }),
    });

    if (!response.ok) {
      setMessage(await response.text());
      return;
    }
    setMessage(`Issue flagged for user ${userId}`);
  }

  if (loading && !metrics) {
    return (
      <main className="container">
        <p>Loading admin portal...</p>
      </main>
    );
  }

  return (
    <main className="container">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12 }}>
        <div>
          <h1 style={{ marginBottom: 8 }}>Trial Admin Portal</h1>
          <p className="muted" style={{ marginTop: 0 }}>
            Monitor Terra sync health and manage cohort operations.
          </p>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="btn" onClick={loadDashboard}>Refresh</button>
          <button className="btn btn-primary" onClick={exportCSV}>Export CSV</button>
          <button className="btn btn-danger" onClick={signOut}>Sign out</button>
        </div>
      </div>

      {message ? (
        <div className="card" style={{ borderColor: '#fecaca', color: '#991b1b' }}>
          {message}
        </div>
      ) : null}

      {metrics ? (
        <section className="grid grid-2" style={{ marginTop: 20 }}>
          <div className="card">
            <h3 style={{ marginTop: 0 }}>Profiles</h3>
            <p style={{ fontSize: 28, margin: 0 }}>{metrics.profile_count}</p>
          </div>
          <div className="card">
            <h3 style={{ marginTop: 0 }}>Connected</h3>
            <p style={{ fontSize: 28, margin: 0 }}>{metrics.connection_counts.connected}</p>
          </div>
          <div className="card">
            <h3 style={{ marginTop: 0 }}>Pending + Error</h3>
            <p style={{ fontSize: 28, margin: 0 }}>
              {metrics.connection_counts.pending + metrics.connection_counts.error}
            </p>
          </div>
          <div className="card">
            <h3 style={{ marginTop: 0 }}>Stale sync &gt;24h</h3>
            <p style={{ fontSize: 28, margin: 0 }}>{metrics.stale_sync_count_24h}</p>
          </div>
        </section>
      ) : null}

      <section className="card" style={{ marginTop: 20, overflowX: 'auto' }}>
        <h2 style={{ marginTop: 0 }}>Trial users</h2>
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Cohort</th>
              <th>Status</th>
              <th>Last sync</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {users.map((user) => (
              <tr key={user.user_id}>
                <td>{user.name}</td>
                <td>{user.trial_cohort}</td>
                <td>
                  <span className={statusBadgeClass(user.connection_status)}>
                    {user.connection_status}
                  </span>
                </td>
                <td>{user.last_sync_at ? new Date(user.last_sync_at).toLocaleString() : 'Never'}</td>
                <td>
                  <button className="btn" onClick={() => flagIssue(user.user_id)}>Flag issue</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>
    </main>
  );
}
