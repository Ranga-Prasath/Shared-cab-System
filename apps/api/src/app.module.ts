import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { HealthController } from './health.controller.js';
import { AuthModule } from './modules/auth/auth.module.js';
import { MatchingModule } from './modules/matching/matching.module.js';
import { RidesModule } from './modules/rides/rides.module.js';
import { RoutingModule } from './modules/routing/routing.module.js';
import { UsersModule } from './modules/users/users.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    AuthModule,
    UsersModule,
    RidesModule,
    MatchingModule,
    RoutingModule
  ],
  controllers: [HealthController]
})
export class AppModule { }
