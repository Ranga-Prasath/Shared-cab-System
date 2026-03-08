import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { DatabaseService } from '../../common/services/database.service.js';
import { SupabaseService } from '../../common/services/supabase.service.js';
import { LoginDto } from './dto/login.dto.js';
import { SignupDto } from './dto/signup.dto.js';

@Injectable()
export class AuthService {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly databaseService: DatabaseService
  ) {}

  /**
   * Registers a user in Supabase Auth and creates a profile row.
   */
  async signup(dto: SignupDto): Promise<{ accessToken: string; refreshToken: string }> {
    try {
      const result = await this.supabaseService.signup(dto.email, dto.password);
      await this.databaseService.query(
        `insert into public.profiles (id, full_name, phone, role)
         values ($1, $2, $3, 'passenger')
         on conflict (id) do update set full_name = excluded.full_name, phone = excluded.phone, updated_at = now()`,
        [result.user.id, dto.fullName, dto.phone]
      );
      return { accessToken: result.accessToken, refreshToken: result.refreshToken };
    } catch {
      throw new InternalServerErrorException('Could not sign up. Please try again.');
    }
  }

  /**
   * Authenticates a user and returns access tokens.
   */
  async login(dto: LoginDto): Promise<{ accessToken: string; refreshToken: string }> {
    try {
      return await this.supabaseService.login(dto.email, dto.password);
    } catch {
      throw new InternalServerErrorException('Login failed. Please verify your credentials.');
    }
  }
}