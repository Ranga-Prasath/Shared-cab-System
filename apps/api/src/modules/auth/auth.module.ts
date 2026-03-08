import { Module } from '@nestjs/common';
import { DatabaseService } from '../../common/services/database.service.js';
import { SupabaseService } from '../../common/services/supabase.service.js';
import { AuthController } from './auth.controller.js';
import { AuthService } from './auth.service.js';

@Module({
  controllers: [AuthController],
  providers: [AuthService, SupabaseService, DatabaseService],
  exports: [AuthService]
})
export class AuthModule {}