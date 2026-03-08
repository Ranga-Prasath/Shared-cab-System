export interface ApiEnvelope<T> {
  success: boolean;
  data?: T;
  error?: string;
}

export const ok = <T>(data: T): ApiEnvelope<T> => ({
  success: true,
  data
});

export const fail = (message: string): ApiEnvelope<never> => ({
  success: false,
  error: message
});