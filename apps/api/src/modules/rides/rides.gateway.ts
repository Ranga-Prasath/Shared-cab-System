import { WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import type { Server } from 'socket.io';

@WebSocketGateway({ namespace: '/rides', cors: { origin: '*' } })
export class RidesGateway {
  @WebSocketServer()
  server!: Server;

  emitRideCreated(payload: unknown): void {
    this.server.emit('ride.created', payload);
  }

  emitRideUpdated(payload: unknown): void {
    this.server.emit('ride.updated', payload);
  }

  emitRideMatched(payload: unknown): void {
    this.server.emit('ride.matched', payload);
  }
}