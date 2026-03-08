import { Module } from '@nestjs/common';
import { DatabaseService } from '../../common/services/database.service.js';
import { MatchingModule } from '../matching/matching.module.js';
import { RoutingModule } from '../routing/routing.module.js';
import { RidesController } from './rides.controller.js';
import { RidesGateway } from './rides.gateway.js';
import { RidesService } from './rides.service.js';

@Module({
  imports: [RoutingModule, MatchingModule],
  controllers: [RidesController],
  providers: [RidesService, RidesGateway, DatabaseService],
  exports: [RidesService]
})
export class RidesModule {}