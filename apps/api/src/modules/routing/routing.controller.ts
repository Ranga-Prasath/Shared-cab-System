import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { ok } from '../../common/api-response.js';
import { AuthGuard } from '../../common/guards/auth.guard.js';
import { DirectionsDto } from './dto.directions.js';
import { RoutingService } from './routing.service.js';

@ApiTags('Routing')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller('/api/v1/routing')
export class RoutingController {
  constructor(private readonly routingService: RoutingService) {}

  @Post('/directions')
  async directions(@Body() dto: DirectionsDto) {
    const data = await this.routingService.directions(dto.start, dto.end);
    return ok(data);
  }
}