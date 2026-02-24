'use client';

import { FormEvent, useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import { getSupabaseBrowserClient } from '@/lib/supabase-browser';

export default function LandingPage() {
  const router = useRouter();
  const supabase = useMemo(
    () => (typeof window === 'undefined' ? null : getSupabaseBrowserClient()),
    [],
  );
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    if (!supabase) return;
    supabase.auth.getSession().then(({ data }) => {
      if (data.session) {
        router.replace('/admin');
      }
    });
  }, [router, supabase]);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!supabase) {
      setMessage('Supabase client is not ready yet.');
      return;
    }
    setLoading(true);
    setMessage(null);

    const { error } = await supabase.auth.signInWithPassword({
      email: email.trim(),
      password,
    });

    setLoading(false);
    if (error) {
      setMessage(error.message);
      return;
    }

    router.push('/admin');
  }

  return (
    <main className="container">
      <div className="card" style={{ maxWidth: 520, margin: '40px auto' }}>
        <h1 style={{ marginTop: 0 }}>Flex Force X Trial Ops</h1>
        <p className="muted">
          Login for cohort operations, Terra connection monitoring, and biometrics export.
        </p>

        <form onSubmit={handleSubmit} className="grid" style={{ marginTop: 16 }}>
          <label>
            <div style={{ marginBottom: 6, fontWeight: 600 }}>Email</div>
            <input
              className="input"
              type="email"
              autoComplete="email"
              required
              value={email}
              onChange={(event) => setEmail(event.target.value)}
            />
          </label>
          <label>
            <div style={{ marginBottom: 6, fontWeight: 600 }}>Password</div>
            <input
              className="input"
              type="password"
              autoComplete="current-password"
              required
              value={password}
              onChange={(event) => setPassword(event.target.value)}
            />
          </label>

          <button className="btn btn-primary" type="submit" disabled={loading}>
            {loading ? 'Signing in...' : 'Sign in'}
          </button>

          {message ? <p style={{ color: '#b91c1c', margin: 0 }}>{message}</p> : null}
        </form>
      </div>
    </main>
  );
}
