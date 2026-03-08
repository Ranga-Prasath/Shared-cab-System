import { Module } from '@nestjs/common';
import { DatabaseService } from '../../common/services/database.service.js';
import { UsersController } from './users.controller.js';
import { UsersService } from './users.service.js';

@Module({
  controllers: [UsersController],
  providers: [UsersService, DatabaseService],
  exports: [UsersService]
})
export class UsersModule {}