import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { ok } from '../../common/api-response.js';
import { CurrentUser, type AuthUser } from '../../common/decorators/current-user.decorator.js';
import { AuthGuard } from '../../common/guards/auth.guard.js';
import { CreateRideDto } from './dto/create-ride.dto.js';
import { UpdateRideDto } from './dto/update-ride.dto.js';
import { RidesService } from './rides.service.js';

@ApiTags('Rides')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller('/api/v1/rides')
export class RidesController {
  constructor(private readonly ridesService: RidesService) { }

  @Post()
  async create(@CurrentUser() user: AuthUser, @Body() dto: CreateRideDto) {
    const data = await this.ridesService.createRide(user.id, dto);
    return ok(data);
  }

  @Get()
  async list(@CurrentUser() user: AuthUser) {
    const data = await this.ridesService.listRides(user.id);
    return ok(data);
  }

  @Get('/:id')
  async getById(@Param('id') id: string) {
    const data = await this.ridesService.getRideById(id);
    return ok(data);
  }

  @Patch('/:id/status')
  async updateStatus(@Param('id') id: string, @Body() dto: UpdateRideDto) {
    const data = await this.ridesService.updateStatus(id, dto);
    return ok(data);
  }

  @Post('/:id/accept')
  async accept(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    const data = await this.ridesService.acceptRide(user.id, id);
    return ok(data);
  }

  @Post('/:id/match')
  async match(@Param('id') id: string, @Query('minOverlapPercentage') minOverlapPercentage?: string) {
    const parsed = minOverlapPercentage ? Number(minOverlapPercentage) : 0.4;
    const data = await this.ridesService.triggerMatch(id, parsed);
    return ok(data);
  }

  @Get('/:id/route')
  async route(@Param('id') id: string) {
    const data = await this.ridesService.getRideRoute(id);
    return ok(data);
  }
}