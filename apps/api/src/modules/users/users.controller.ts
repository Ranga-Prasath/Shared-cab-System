import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { ok } from '../../common/api-response.js';
import { CurrentUser, type AuthUser } from '../../common/decorators/current-user.decorator.js';
import { AuthGuard } from '../../common/guards/auth.guard.js';
import { UpdateProfileDto } from './dto/update-profile.dto.js';
import { UsersService } from './users.service.js';

@ApiTags('Users')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller('/api/v1/users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('/me')
  async me(@CurrentUser() user: AuthUser) {
    const data = await this.usersService.getProfile(user.id);
    return ok(data);
  }

  @Patch('/me')
  async update(@CurrentUser() user: AuthUser, @Body() dto: UpdateProfileDto) {
    const data = await this.usersService.updateProfile(user.id, dto);
    return ok(data);
  }
}