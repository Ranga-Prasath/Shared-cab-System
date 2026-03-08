import { Controller, Get } from '@nestjs/common';
import { ok } from './common/api-response.js';

@Controller('/api')
export class HealthController {
  @Get('/health')
  health() {
    return ok({ status: 'ok' });
  }
}