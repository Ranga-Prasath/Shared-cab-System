export type UserRole = 'passenger' | 'driver' | 'admin';

export interface Profile {
  id: string;
  fullName: string;
  phone: string;
  avatarUrl: string | null;
  role: UserRole;
  createdAt: string;
  updatedAt: string;
}