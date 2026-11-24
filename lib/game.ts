"use client";

import { supabase, playerToken } from "@/lib/supabase";
import type {
  Card,
  GameActionName,
  GameState,
  Player,
  Room,
  Team,
} from "@/lib/types";

/*
 * Aucune carte n'est importee ici : data/cards.json ne sert qu'au seed SQL et
 * au validateur (scripts/), il n'entre PAS dans le bundle du navigateur.
 * Le mot et les mots interdits sont demandes au serveur, tour par tour, via
 * get_current_card() qui verifie le role de l'appelant.
 */

/** Alphabet sans caracteres ambigus (pas de O/0, I/1) : un code se dicte au telephone. */
const CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

export function generateRoomCode(length = 4): string {
  const bytes = new Uint8Array(length);
  crypto.getRandomValues(bytes);
  let out = "";
  for (let i = 0; i < length; i++) {
    out += CODE_ALPHABET[bytes[i] % CODE_ALPHABET.length];
  }
  return out;
}

/* ------------------------------------------------------------------ */
/*  Erreurs                                                            */
/* ------------------------------------------------------------------ */

/**
 * Traduit une erreur Supabase/Postgres en message lisible.
 * Les erreurs techniques (players_pkey, UPDATE requires a WHERE clause,
 * fonction introuvable...) ne doivent jamais arriver telles quelles a l'ecran.
 */
export function cleanError(error: unknown): string {
  const raw =
    typeof error === "string"
      ? error
      : ((error as { message?: string } | null)?.message ?? "");

  if (!raw) return "Une erreur est survenue. Reessaie.";

  if (raw.includes("duplicate key value") || raw.includes("players_pkey")) {
    return "Ta session de joueur etait deja utilisee. Recharge la page puis reessaie.";
  }
  if (raw.includes("UPDATE requires a WHERE clause")) {
    return "Erreur serveur sur la partie. Recharge la page.";
  }
  if (raw.includes("Could not find the function") || raw.includes("PGRST202")) {
    return "Le jeu est momentanément indisponible. Contacte le support.";
  }
  if (raw.includes("Anonymous sign-ins are disabled")) {
    return "Active Anonymous Sign-In dans Supabase (Authentication > Providers > Anonymous).";
  }
  if (raw.includes("JWT") || raw.includes("not authenticated") || raw.includes("28000")) {
    return "Veuillez vous reconnecter.";
  }
  if (raw.includes("Failed to fetch") || raw.includes("NetworkError")) {
    return "Connexion au serveur impossible. Verifie ta connexion internet.";
  }
  // Messages metier remontes volontairement par les fonctions SQL.
  return raw.replace(/^.*?:\s*/, "").slice(0, 200) || "Une erreur est survenue.";
}

/* ------------------------------------------------------------------ */
/*  Authentification anonyme                                           */
/* ------------------------------------------------------------------ */

export async function ensureAuth(): Promise<string> { return playerToken(); }

/* ------------------------------------------------------------------ */
/*  Appels RPC                                                         */
/* ------------------------------------------------------------------ */


export type ViewerState = GameState & {viewer_id: string | null};
async function rpc(fn:string,args:Record<string,unknown>):Promise<ViewerState>{
 const {data,error}=await supabase.rpc(fn,{...args,p_token:playerToken()});
 if(error)throw new Error(cleanError(error));
 if(!data||!(data as ViewerState).room)throw new Error("Réponse inattendue du serveur.");
 return data as ViewerState;
}
export const getRoomState=(code:string)=>rpc("taboo_ui_state",{p_code:code.toUpperCase()});
export async function createRoom(name:string):Promise<ViewerState>{
 let lastError:unknown;
 for(let i=0;i<5;i++){
  try{return await rpc("taboo_ui_create_room",{p_code:generateRoomCode(),p_name:name});}
  catch(err){lastError=err;if(!String((err as Error).message).toLowerCase().includes("duplicate key"))throw err;}
 }
 throw new Error(cleanError(lastError));
}
export const joinRoom=(code:string,name:string,team:Team)=>rpc("taboo_ui_join_room",{p_code:code.toUpperCase(),p_name:name,p_team:team});
export const startGame=(code:string)=>rpc("taboo_ui_start_game",{p_code:code.toUpperCase()});
export const gameAction=(code:string,action:GameActionName)=>rpc("taboo_ui_game_action",{p_code:code.toUpperCase(),p_action:action});
export const endTurn=(code:string)=>rpc("taboo_ui_end_turn",{p_code:code.toUpperCase()});
export const restartGame=(code:string)=>rpc("taboo_ui_restart_game",{p_code:code.toUpperCase()});
export const leaveRoom=(code:string)=>rpc("taboo_ui_leave_room",{p_code:code.toUpperCase()});
export async function fetchRoomByCode(code:string):Promise<Room|null>{
 try{return (await getRoomState(code)).room;}catch(e){if(String((e as Error).message).includes("introuvable"))return null;throw e;}
}
export async function fetchPlayers(roomId:string):Promise<Player[]>{void roomId;return [];}
export async function fetchCurrentCard(code:string):Promise<Card|null>{return(await getRoomState(code)).card;}

/* ------------------------------------------------------------------ */
/*  Helpers d'affichage                                                */
/* ------------------------------------------------------------------ */

export const teamPlayers = (players: Player[], team: Team) =>
  players.filter((p) => p.team === team);

export const findPlayer = (players: Player[], id: string | null) =>
  id ? (players.find((p) => p.id === id) ?? null) : null;

export function formatClock(ms: number): string {
  const total = Math.max(0, Math.ceil(ms / 1000));
  const m = Math.floor(total / 60);
  const s = total % 60;
  return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}
