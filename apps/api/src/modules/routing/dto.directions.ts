import { ApiProperty } from '@nestjs/swagger';
import { ArrayMaxSize, ArrayMinSize, IsArray, IsNumber } from 'class-validator';

export class DirectionsDto {
  @ApiProperty({
    description: 'Route origin in GeoJSON coordinate order [longitude, latitude].',
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
  start!: [number, number];

  @ApiProperty({
    description: 'Route destination in GeoJSON coordinate order [longitude, latitude].',
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
  end!: [number, number];
}