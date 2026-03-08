import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString, MinLength } from 'class-validator';

export class LoginDto {
  @ApiProperty({
    description: 'Registered account email.',
    example: 'rider@example.com',
    type: String,
    required: true
  })
  @IsEmail()
  email!: string;

  @ApiProperty({
    description: 'Account password.',
    example: 'StrongPass123!',
    type: String,
    required: true
  })
  @IsString()
  @MinLength(8)
  password!: string;
}