import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { ok } from '../../common/api-response.js';
import { AuthGuard } from '../../common/guards/auth.guard.js';
import { MatchingService } from './matching.service.js';

@ApiTags('Matching')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller('/api/v1/matching')
export class MatchingController {
  constructor(private readonly matchingService: MatchingService) {}

  @Get('/available')
  async available(
    @Query('pickupLon') pickupLon: string,
    @Query('pickupLat') pickupLat: string,
    @Query('dropoffLon') dropoffLon: string,
    @Query('dropoffLat') dropoffLat: string
  ) {
    const data = await this.matchingService.findAvailableForRoute(
      [Number(pickupLon), Number(pickupLat)],
      [Number(dropoffLon), Number(dropoffLat)]
    );
    return ok(data);
  }
}