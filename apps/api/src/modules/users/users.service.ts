import { Injectable, NotFoundException } from '@nestjs/common';
import { DatabaseService } from '../../common/services/database.service.js';
import { UpdateProfileDto } from './dto/update-profile.dto.js';

interface ProfileRow {
  id: string;
  full_name: string;
  phone: string;
  avatar_url: string | null;
  role: 'passenger' | 'driver' | 'admin';
  created_at: string;
  updated_at: string;
}

@Injectable()
export class UsersService {
  constructor(private readonly db: DatabaseService) {}

  /**
   * Returns one profile by id.
   */
  async getProfile(userId: string): Promise<Record<string, string | null>> {
    const result = await this.db.query<ProfileRow>('select * from public.profiles where id = $1 limit 1', [userId]);
    const row = result.rows[0];
    if (!row) {
      throw new NotFoundException('User profile was not found.');
    }

    return {
      id: row.id,
      fullName: row.full_name,
      phone: row.phone,
      avatarUrl: row.avatar_url,
      role: row.role,
      createdAt: row.created_at,
      updatedAt: row.updated_at
    };
  }

  /**
   * Updates a profile with provided fields.
   */
  async updateProfile(userId: string, dto: UpdateProfileDto): Promise<Record<string, string | null>> {
    await this.db.query(
      `update public.profiles
       set full_name = coalesce($2, full_name),
           phone = coalesce($3, phone),
           avatar_url = coalesce($4, avatar_url),
           updated_at = now()
       where id = $1`,
      [userId, dto.fullName ?? null, dto.phone ?? null, dto.avatarUrl ?? null]
    );

    return this.getProfile(userId);
  }
}