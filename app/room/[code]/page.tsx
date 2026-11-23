"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useParams } from "next/navigation";
import { supabase, playerToken } from "@/lib/supabase";
import { sendRoomToPlatform } from "@/components/PlatformBridge";
import cards from "@/data/cards.json";
import type { Card, Player, RoomState, Team } from "@/lib/types";

const TURN_MS = 75_000;
const MAX_TEAM = 4;
type SavedPlayer = { playerId: string; name: string; team: Team };
type Action = "found" | "buzz" | "pass";

export default function RoomPage() {
  const { code: rawCode } = useParams<{ code: string }>();
  const code = rawCode.toUpperCase();
  const [state, setState] = useState<RoomState | null>(null);
  const [me, setMe] = useState<SavedPlayer | null>(null);
  const [joinName, setJoinName] = useState("");
  const [joinTeam, setJoinTeam] = useState<Team>("A");
  const [seconds, setSeconds] = useState(75);
  const [toast, setToast] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const endingTurn = useRef(false);

  const snapshotToState = (snapshot: any): RoomState => {
    const r = snapshot.room;
    return {
      code, status:r.status, currentTeam:r.current_team, currentCardId:r.current_card_id,
      usedCardIds:r.used_card_ids ?? [], scoreA:r.score_a, scoreB:r.score_b,
      turnEndsAt:r.turn_ends_at ? new Date(r.turn_ends_at).getTime() : null,
      turnNumber:r.turn_number, guesserId:r.guesser_id, refereeId:r.referee_id,
      hostId:r.host_player_id, players:(snapshot.players ?? []) as Player[]
    };
  };

  const loadSnapshot = useCallback(async () => {
    const { data, error: rpcError } = await supabase.rpc("taboo_get_room_snapshot", { p_code: code });
    if (rpcError || !data) { setError(rpcError?.message || "Room introuvable."); setLoading(false); return; }
    setState(snapshotToState(data)); setLoading(false);
  }, [code]);

  useEffect(() => {
    (async () => {
      const saved = localStorage.getItem(`taboo-player-${code}`);
      if (saved) setMe(JSON.parse(saved) as SavedPlayer);
      await loadSnapshot();
    })();

  }, [code, loadSnapshot]);

  useEffect(() => {
    const interval = window.setInterval(() => loadSnapshot(), 1500);
    return () => window.clearInterval(interval);
  }, [loadSnapshot]);

  useEffect(() => {
    if (!state?.turnEndsAt || state.status !== "playing") return;
    const tick = () => setSeconds(Math.max(0, Math.ceil((state.turnEndsAt! - Date.now()) / 1000)));
    tick(); const timer = window.setInterval(tick, 200); return () => window.clearInterval(timer);
  }, [state?.turnEndsAt, state?.status]);

  const players = state?.players ?? [];
  const mePlayer = players.find(p => p.id === me?.playerId);
  const isHost = !!mePlayer && mePlayer.id === state?.hostId;
  useEffect(() => {
    if (!mePlayer) return;
    const send=()=>sendRoomToPlatform(code);
    send();
    window.addEventListener("taboo-rg-bootstrap",send);
    const timer=window.setInterval(send,45000);
    return ()=>{window.removeEventListener("taboo-rg-bootstrap",send);window.clearInterval(timer);};
  },[code,mePlayer?.id]);
  const isGuesser = !!mePlayer && mePlayer.id === state?.guesserId;
  const isReferee = !!mePlayer && mePlayer.id === state?.refereeId;
  const card = useMemo<Card>(() => (cards.find(c => c.id === state?.currentCardId) ?? cards[0]) as Card, [state?.currentCardId]);

  async function joinRoom() {
    if (!joinName.trim()) return setToast("Entre ton prénom.");
    try {

      const { data, error:e } = await supabase.rpc("taboo_join_room", { p_code:code, p_name:joinName.trim(), p_team:joinTeam, p_token:playerToken() });
      if (e) throw e;
      const saved = { playerId:data.id, name:data.name, team:data.team } as SavedPlayer;
      localStorage.setItem(`taboo-player-${code}`, JSON.stringify(saved)); setMe(saved); await loadSnapshot();
    } catch(e:any) { setToast(e.message || "Impossible de rejoindre."); }
  }

  async function changeTeam(team: Team) {
    if (!me || state?.status !== "lobby") return;
    try {
      const { error:e } = await supabase.rpc("taboo_join_room", { p_code:code, p_name:me.name, p_team:team, p_token:playerToken() });
      if(e) throw e;
      const saved={...me,team}; setMe(saved); localStorage.setItem(`taboo-player-${code}`,JSON.stringify(saved)); await loadSnapshot();
    } catch(e:any) { setToast(e.message || "Impossible de changer d'équipe."); }
  }

  async function notify(text: string) {
    setToast(text);
    window.setTimeout(() => setToast(""), 2200);
    await loadSnapshot();
  }

  async function startGame() {
    if (!isHost) return;
    try { const {error:e}=await supabase.rpc("taboo_start_game",{p_code:code,p_token:playerToken()}); if(e) throw e; await notify("La partie commence !"); }
    catch(e:any){setToast(e.message||"Impossible de lancer.");}
  }

  async function gameAction(action: Action) {
    if ((action === "buzz" && !isReferee) || ((action === "found" || action === "pass") && !isGuesser)) return;
    try { const {error:e}=await supabase.rpc("taboo_game_action",{p_code:code,p_action:action,p_token:playerToken()}); if(e) throw e; await notify(action==="found"?"🟢 Mot trouvé · +1":action==="buzz"?"🔴 BUZZ · 0 point":"🟡 Passé · 0 point"); }
    catch(e:any){setToast(e.message||"Action refusée.");}
  }

  const endTurn = useCallback(async () => {
    if (endingTurn.current || !state || state.status !== "playing" || seconds > 0) return;
    endingTurn.current = true;
    try { const {error:e}=await supabase.rpc("taboo_end_turn",{p_code:code,p_token:playerToken()}); if(e) throw e; await notify("⏱️ Nouveau tour !"); }
    catch(e:any){setToast(e.message||"Impossible de changer de tour.");}
    finally { window.setTimeout(()=>endingTurn.current=false,1200); }
  }, [state, seconds, code]);

  useEffect(() => { if(seconds===0) endTurn(); }, [seconds, endTurn]);

  if (loading) return <main className="center"><div className="loader">Connexion à la partie…</div></main>;
  if (error && !state) return <main className="center"><div><h1>Room introuvable</h1><p>{error}</p></div></main>;
  if (!state) return null;

  if (!me) return <main className="landing"><section className="heroCard joinCard"><div className="eyebrow">ROOM {code}</div><h1>Rejoins la<br/><span>partie.</span></h1><div className="panel"><label>Ton prénom</label><input value={joinName} onChange={e=>setJoinName(e.target.value)} maxLength={24} placeholder="Ex. Sarah"/><label>Ton équipe</label><div className="teamPick"><button className={joinTeam==="A"?"team activeA":"team"} onClick={()=>setJoinTeam("A")}>🟦 A · {players.filter(p=>p.team==="A").length}/{MAX_TEAM}</button><button className={joinTeam==="B"?"team activeB":"team"} onClick={()=>setJoinTeam("B")}>🟥 B · {players.filter(p=>p.team==="B").length}/{MAX_TEAM}</button></div><button className="primary" onClick={joinRoom}>Rejoindre →</button></div></section></main>;

  return <main className="game">
    <header className="topbar"><div><b>TABOO</b><span className="room">ROOM {code}</span></div><div className={`timer ${seconds<=10?"danger":""}`}>{state.status==="playing"?`${String(Math.floor(seconds/60)).padStart(2,"0")}:${String(seconds%60).padStart(2,"0")}`:"01:15"}</div><div className="scores"><span>🟦 {state.scoreA}</span><span>🟥 {state.scoreB}</span></div></header>
    <section className="roomLayout"><aside className="sidebar"><div className="sideTitle"><h3>Joueurs</h3><small>{players.length}/8</small></div>
      <div className="teamList"><strong>🟦 ÉQUIPE A</strong>{players.filter(p=>p.team==="A").map(p=><div className="player" key={p.id}><i/> {p.name}{p.id===me.playerId&&" · toi"}{p.id===state.guesserId&&state.status==="playing"&&<em>DEVINE</em>}</div>)}</div>
      <div className="teamList"><strong>🟥 ÉQUIPE B</strong>{players.filter(p=>p.team==="B").map(p=><div className="player" key={p.id}><i/> {p.name}{p.id===me.playerId&&" · toi"}{p.id===state.refereeId&&state.status==="playing"&&<em>ARBITRE</em>}</div>)}</div>
      {state.status==="lobby"&&<><div className="joinActions"><button className="small" onClick={()=>changeTeam("A")}>Équipe A</button><button className="small" onClick={()=>changeTeam("B")}>Équipe B</button></div>{isHost&&<button className="small" onClick={() => {
        const origin = sessionStorage.getItem("taboo-rg-origin");
        const launch = sessionStorage.getItem("taboo-rg-launch");
        if (origin && launch && window.parent !== window)
          window.parent.postMessage({v:1,game:"tabou",type:"rg:invite-request",launch},origin);
        else navigator.clipboard.writeText(window.location.href).then(()=>setToast("Lien copié !"));
      }}>Inviter mes amis</button><button className="primary" onClick={startGame} disabled={!players.some(p=>p.team==="A")||!players.some(p=>p.team==="B")}>Lancer la partie</button>}</>}
      {state.status==="playing"&&<div className="roleBox">{isGuesser?"🎤 Tu fais deviner":isReferee?"👁️ Tu es l’arbitre":"👥 Tu regardes"}</div>}
    </aside>
    <section className="board"><div className="turn">{state.status==="lobby"?"EN ATTENTE DES JOUEURS":`TOUR ${state.turnNumber} · ÉQUIPE ${state.currentTeam}`}</div>
      {state.status==="lobby"?<div className="lobby"><div className="pulse">🎮</div><h1>Invite tes amis</h1><p>Partage ce lien pour rejoindre cette room.</p><div className="invite"><span>{typeof window!=="undefined"?window.location.href:""}</span><button onClick={()=>navigator.clipboard.writeText(window.location.href)}>Copier</button></div><p className="muted">Jusqu'à 4 joueurs par équipe · 8 au total.</p></div>:
      <div className="card"><div className="cardLabel">FAIS DEVINER</div><h1>{card.word}</h1><div className="forbidden"><div>🚫 MOTS INTERDITS</div>{card.forbidden.map((w,i)=><span key={i}>{w}</span>)}</div><div className="controls">{isReferee&&<button className="red" onClick={()=>gameAction("buzz")}>🔴 BUZZ</button>}{isGuesser&&<button className="green" onClick={()=>gameAction("found")}>✓ MOT TROUVÉ</button>}{isGuesser&&<button className="yellow" onClick={()=>gameAction("pass")}>PASSER →</button>}</div><div className="hint">{isReferee?"👁️ Surveille les 5 mots interdits. Si l'un est prononcé, BUZZ.":isGuesser?"🎤 Fais deviner sans prononcer les mots interdits.":"👥 Observe la partie en direct."}</div></div>}
    </section></section>{toast&&<div className="toast">{toast}</div>}
  </main>;
}
