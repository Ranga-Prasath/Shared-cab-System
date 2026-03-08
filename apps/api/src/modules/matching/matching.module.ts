import { Module } from '@nestjs/common';
import { DatabaseService } from '../../common/services/database.service.js';
import { RoutingModule } from '../routing/routing.module.js';
import { MatchingController } from './matching.controller.js';
import { MatchingService } from './matching.service.js';

@Module({
  imports: [RoutingModule],
  controllers: [MatchingController],
  providers: [MatchingService, DatabaseService],
  exports: [MatchingService]
})
export class MatchingModule {}
