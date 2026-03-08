import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { createClient } from '@supabase/supabase-js';
import { getEnv } from '../../config/env.validation.js';
import type { AuthUser } from '../decorators/current-user.decorator.js';

@Injectable()
export class AuthGuard implements CanActivate {
  private readonly supabase = createClient(getEnv().SUPABASE_URL, getEnv().SUPABASE_ANON_KEY);

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<{ headers: { authorization?: string }; user?: AuthUser }>();
    const authHeader = request.headers.authorization;

    if (!authHeader?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing or invalid authorization token.');
    }

    const token = authHeader.replace('Bearer ', '');
    const { data, error } = await this.supabase.auth.getUser(token);

    if (error || !data.user) {
      throw new UnauthorizedException('Session expired. Please login again.');
    }

    request.user = {
      id: data.user.id,
      email: data.user.email ?? ''
    };

    return true;
  }
}