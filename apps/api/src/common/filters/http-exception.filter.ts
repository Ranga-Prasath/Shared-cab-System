import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus } from '@nestjs/common';
import { Response } from 'express';
import { fail } from '../api-response.js';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const context = host.switchToHttp();
    const response = context.getResponse<Response>();

    if (exception instanceof HttpException) {
      response.status(exception.getStatus()).json(fail(exception.message));
      return;
    }

    response.status(HttpStatus.INTERNAL_SERVER_ERROR).json(fail('Something went wrong. Please try again.'));
  }
}