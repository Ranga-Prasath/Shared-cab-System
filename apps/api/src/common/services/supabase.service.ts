import { Injectable } from '@nestjs/common';
import { createClient, type User } from '@supabase/supabase-js';
import { getEnv } from '../../config/env.validation.js';

@Injectable()
export class SupabaseService {
  private readonly client = createClient(getEnv().SUPABASE_URL, getEnv().SUPABASE_SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false }
  });

  async signup(email: string, password: string): Promise<{ accessToken: string; refreshToken: string; user: User }> {
    const { data, error } = await this.client.auth.signUp({ email, password });
    if (error || !data.session || !data.user) {
      throw new Error('Unable to create account right now.');
    }

    return {
      accessToken: data.session.access_token,
      refreshToken: data.session.refresh_token,
      user: data.user
    };
  }

  async login(email: string, password: string): Promise<{ accessToken: string; refreshToken: string }> {
    const { data, error } = await this.client.auth.signInWithPassword({ email, password });
    if (error || !data.session) {
      throw new Error('Invalid credentials.');
    }

    return {
      accessToken: data.session.access_token,
      refreshToken: data.session.refresh_token
    };
  }
}