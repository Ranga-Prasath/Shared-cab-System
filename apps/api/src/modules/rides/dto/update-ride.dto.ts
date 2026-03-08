import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsString } from 'class-validator';

const rideStatuses = ['REQUESTED', 'MATCHED', 'EN_ROUTE', 'COMPLETED', 'CANCELLED'] as const;

export class UpdateRideDto {
  @ApiProperty({
    description: 'Target ride status in the finite state workflow.',
    example: 'EN_ROUTE',
    enum: rideStatuses,
    required: true
  })
  @IsString()
  @IsIn(rideStatuses)
  status!: (typeof rideStatuses)[number];
}