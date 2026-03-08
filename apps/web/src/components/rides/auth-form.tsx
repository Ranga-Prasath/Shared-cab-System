'use client';

import { useState } from 'react';
import { createSupabaseBrowserClient } from '../../lib/supabase';

export function AuthForm({ mode }: { mode: 'login' | 'signup' }) {
  const supabase = createSupabaseBrowserClient();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [message, setMessage] = useState('');

  const submit = async (): Promise<void> => {
    if (!supabase) {
      setMessage('Supabase is not configured. Set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY.');
      return;
    }

    if (mode === 'signup') {
      const { error } = await supabase.auth.signUp({ email, password, options: { data: { fullName, phone } } });
      setMessage(error ? error.message : 'Signup successful. Check your email.');
      return;
    }

    const { error } = await supabase.auth.signInWithPassword({ email, password });
    setMessage(error ? error.message : 'Login successful.');
  };

  return (
    <section className="mx-auto max-w-md rounded-2xl border border-border p-6 glass">
      <h2 className="text-2xl font-semibold capitalize">{mode}</h2>
      <div className="mt-4 space-y-3">
        {mode === 'signup' ? (
          <>
            <input
              placeholder="Full name"
              value={fullName}
              onChange={(event) => setFullName(event.target.value)}
              className="w-full rounded-lg border border-border bg-slate-900 px-3 py-2"
            />
            <input
              placeholder="Phone"
              value={phone}
              onChange={(event) => setPhone(event.target.value)}
              className="w-full rounded-lg border border-border bg-slate-900 px-3 py-2"
            />
          </>
        ) : null}
        <input
          placeholder="Email"
          value={email}
          onChange={(event) => setEmail(event.target.value)}
          className="w-full rounded-lg border border-border bg-slate-900 px-3 py-2"
        />
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(event) => setPassword(event.target.value)}
          className="w-full rounded-lg border border-border bg-slate-900 px-3 py-2"
        />
        <button onClick={() => void submit()} className="w-full rounded-lg bg-cyan-400 px-4 py-2 font-medium text-slate-950">
          {mode === 'signup' ? 'Create account' : 'Sign in'}
        </button>
        <p className="text-sm text-slate-300">{message}</p>
      </div>
    </section>
  );
}
