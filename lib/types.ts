export type Team = "A" | "B";
export type Role = "guesser" | "referee" | "player";
export type RoomStatus = "lobby" | "playing" | "finished";
export type Player = { id: string; name: string; team: Team; role: Role; connected: boolean; };
export type Card = { id: number; word: string; forbidden: string[]; category: string; };
export type RoomState = {
  code: string; status: RoomStatus; currentTeam: Team; currentCardId: number | null; usedCardIds: number[];
  scoreA: number; scoreB: number; turnEndsAt: number | null; turnNumber: number;
  guesserId: string | null; refereeId: string | null; hostId: string | null; players: Player[];
};
