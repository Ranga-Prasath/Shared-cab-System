import { ApiProperty } from '@nestjs/swagger';
import { ArrayMaxSize, ArrayMinSize, IsArray, IsDateString, IsNumber, IsString } from 'class-validator';

export class CreateRideDto {
  @ApiProperty({
    description: 'Pickup coordinate in GeoJSON order [longitude, latitude].',
    example: [77.5946, 12.9716],
    type: [Number],
    required: true,
    minItems: 2,
    maxItems: 2
  })
  @IsArray()
  @ArrayMinSize(2)
  @ArrayMaxSize(2)
  @IsNumber({}, { each: true })
  pickupLocation!: [number, number];

  @ApiProperty({
    description: 'Dropoff coordinate in GeoJSON order [longitude, latitude].',
    example: [76.6558, 12.3052],
    type: [Number],
    required: true,
    minItems: 2,
    maxItems: 2
  })
  @IsArray()
  @ArrayMinSize(2)
  @ArrayMaxSize(2)
  @IsNumber({}, { each: true })
  dropoffLocation!: [number, number];

  @ApiProperty({
    description: 'Human-readable pickup address.',
    example: 'Majestic Bus Stand, Bengaluru',
    type: String,
    required: true
  })
  @IsString()
  pickupAddress!: string;

  @ApiProperty({
    description: 'Human-readable dropoff address.',
    example: 'Mysore Palace, Mysuru',
    type: String,
    required: true
  })
  @IsString()
  dropoffAddress!: string;

  @ApiProperty({
    description: 'Planned UTC timestamp for ride start.',
    example: '2026-03-07T10:30:00.000Z',
    type: String,
    required: true
  })
  @IsDateString()
  scheduledAt!: string;
}