import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module.js';
import { HttpExceptionFilter } from './common/filters/http-exception.filter.js';
import { getEnv } from './config/env.validation.js';

const bootstrap = async (): Promise<void> => {
  const app = await NestFactory.create(AppModule, { cors: true });
  const env = getEnv();

  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  app.useGlobalFilters(new HttpExceptionFilter());

  const swaggerConfig = new DocumentBuilder()
    .setTitle('Shared Cab Platform API')
    .setDescription('NestJS API for shared cab workflows')
    .setVersion('1.0.0')
    .addServer('http://localhost:4000', 'Local Development')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig, { deepScanRoutes: true });
  SwaggerModule.setup('/api/docs', app, document, {
    swaggerOptions: {
      persistAuthorization: true,
      docExpansion: 'none'
    },
    customSiteTitle: 'Shared Cab Platform Docs'
  });

  await app.listen(env.PORT);
};

bootstrap();
