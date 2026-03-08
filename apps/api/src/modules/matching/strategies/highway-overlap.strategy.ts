export interface MatchingStrategy {
  name: string;
  minOverlap: number;
}

export class HighwayOverlapStrategy implements MatchingStrategy {
  name = 'highway-overlap';
  minOverlap = 0.4;
}