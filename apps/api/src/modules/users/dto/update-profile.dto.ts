import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class UpdateProfileDto {
  @ApiPropertyOptional({
    description: 'Updated full name for the profile.',
    example: 'Priya Narayanan',
    type: String,
    required: false
  })
  @IsString()
  @IsOptional()
  fullName?: string;

  @ApiPropertyOptional({
    description: 'Updated phone number.',
    example: '+919998887776',
    type: String,
    required: false
  })
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiPropertyOptional({
    description: 'Public avatar URL for the profile image.',
    example: 'https://images.example.com/avatar.png',
    type: String,
    required: false
  })
  @IsString()
  @IsOptional()
  avatarUrl?: string;
}