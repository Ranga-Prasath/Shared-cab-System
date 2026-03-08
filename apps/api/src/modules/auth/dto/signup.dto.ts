import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString, MinLength } from 'class-validator';

export class SignupDto {
  @ApiProperty({
    description: 'Email used for authentication.',
    example: 'rider@example.com',
    type: String,
    required: true
  })
  @IsEmail()
  email!: string;

  @ApiProperty({
    description: 'Password for account creation (minimum 8 characters).',
    example: 'StrongPass123!',
    type: String,
    required: true
  })
  @IsString()
  @MinLength(8)
  password!: string;

  @ApiProperty({
    description: 'Full legal or display name for the user profile.',
    example: 'Aarav Sharma',
    type: String,
    required: true
  })
  @IsString()
  fullName!: string;

  @ApiProperty({
    description: 'Primary phone number in international or national format.',
    example: '+919876543210',
    type: String,
    required: true
  })
  @IsString()
  phone!: string;
}