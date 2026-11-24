"use client";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import Credit from "@/components/Credit";
import GameControls from "@/components/GameControls";
import GameHeader from "@/components/GameHeader";
import GameOver from "@/components/GameOver";
import Lobby from "@/components/Lobby";
import RulesModal, { RULES_SEEN_KEY } from "@/components/RulesModal";
import ScoreBoard from "@/components/ScoreBoard";
import TabooCard from "@/components/TabooCard";
import Timer from "@/components/Timer";
import { cleanError, endTurn, getRoomState, findPlayer, gameAction, joinRoom, leaveRoom, restartGame, startGame, teamPlayers } from "@/lib/game";
import { sendRoomToPlatform } from "@/components/PlatformBridge";
import { MAX_PER_TEAM, type Card, type GameActionName, type Player, type Role, type Room, type Team } from "@/lib/types";
import type { ViewerState } from "@/lib/game";

export default function RoomClient({code}:{code:string}) {
  const router=useRouter();
  const [myId,setMyId]=useState<string|null>(null);
  const [room,setRoom]=useState<Room|null>(null);
  const [players,setPlayers]=useState<Player[]>([]);
  const [card,setCard]=useState<Card|null>(null);
  const [loading,setLoading]=useState(true);
  const [notFound,setNotFound]=useState(false);
  const [busy,setBusy]=useState(false);
  const [error,setError]=useState<string|null>(null);
  const [onlineIds,setOnlineIds]=useState<Set<string>>(new Set());
  const [live,setLive]=useState(true);
  const [reconnected,setReconnected]=useState(false);
  const [now,setNow]=useState(()=>Date.now());
  const [flash,setFlash]=useState<GameActionName|null>(null);
  const [joinName,setJoinName]=useState("");
  const [joinTeam,setJoinTeam]=useState<Team>("A");
  const [rulesOpen,setRulesOpen]=useState(false);
  const endGuard=useRef(-1);
  const lastActionAt=useRef<string|null>(null);
  const flashInit=useRef(false);
  const everLoaded=useRef(false);
  const applyState=useCallback((state:ViewerState)=>{
    setRoom(state.room);
    setPlayers(state.players||[]);
    setCard(state.card||null);
    setMyId(state.viewer_id);
    setOnlineIds(new Set((state.players||[]).filter(p=>p.connected).map(p=>p.id)));
    setLive(true);
    setNotFound(false);
    if(state.viewer_id) {
      const me=(state.players||[]).find(p=>p.id===state.viewer_id);
      if(me) localStorage.setItem("taboo-player-"+state.room.code,JSON.stringify({playerId:me.id,name:me.name,team:me.team}));
      sendRoomToPlatform(state.room.code);
    }
  },[]);
  const refresh=useCallback(async()=>{
    try{
      const state=await getRoomState(code);
      applyState(state);
      everLoaded.current=true;
    }catch(err){
      setLive(false);
      if(!everLoaded.current){
        const msg=cleanError(err);
        if(msg.toLowerCase().includes("introuvable"))setNotFound(true);
        else setError(msg);
      }
    }finally{setLoading(false);}
  },[applyState,code]);
  useEffect(()=>{
    const saved=localStorage.getItem("taboo-name");
    if(saved)setJoinName(saved);
    const rgName=sessionStorage.getItem("taboo-rg-name");
    if(rgName)setJoinName(rgName);
    try{if(!localStorage.getItem(RULES_SEEN_KEY))setRulesOpen(true);}catch{}
    void refresh();
    const iv=window.setInterval(()=>void refresh(),1500);
    const onVisible=()=>{if(document.visibilityState==="visible")void refresh();};
    const onBootstrap=()=>{
      const n=sessionStorage.getItem("taboo-rg-name");if(n)setJoinName(n);
      void refresh();
    };
    window.addEventListener("focus",onVisible);
    window.addEventListener("taboo-rg-bootstrap",onBootstrap);
    document.addEventListener("visibilitychange",onVisible);
    return()=>{
      window.clearInterval(iv);
      window.removeEventListener("focus",onVisible);
      window.removeEventListener("taboo-rg-bootstrap",onBootstrap);
      document.removeEventListener("visibilitychange",onVisible);
    };
  },[refresh]);
  useEffect(()=>{
    if(room?.status!=="playing")return;
    const iv=window.setInterval(()=>setNow(Date.now()),250);
    return()=>window.clearInterval(iv);
  },[room?.status]);
  const remainingMs=useMemo(()=>{
    if(!room?.turn_ends_at||room.status!=="playing")return 0;
    return Math.max(0,new Date(room.turn_ends_at).getTime()-Math.max(now,Date.now()));
  },[room?.turn_ends_at,room?.status,now]);
  const expired=remainingMs<=0;
  useEffect(()=>{
    if(!room||room.status!=="playing"||!expired)return;
    if(endGuard.current===room.turn_number)return;
    endGuard.current=room.turn_number;
    const index=Math.max(0,players.findIndex(p=>p.id===myId));
    const delay=room.guesser_id===myId?0:800+index*120;
    const timeout=window.setTimeout(()=>{
      void endTurn(code).then(applyState).catch(()=>{endGuard.current=-1;});
    },delay);
    return()=>window.clearTimeout(timeout);
  },[room?.status,room?.turn_number,expired,myId,code,applyState]);
  const canSeeCard=!!room&&room.status==="playing"&&(room.guesser_id===myId||room.referee_id===myId);
  useEffect(()=>{if(!canSeeCard)setCard(null);},[canSeeCard]);
  const lastAction=room?.last_action??null;
  const lastAt=room?.last_action_at??null;
  useEffect(()=>{
    if(!flashInit.current){flashInit.current=true;lastActionAt.current=lastAt;return;}
    if(lastAt===lastActionAt.current)return;
    lastActionAt.current=lastAt;
    if(!lastAt||!lastAction)return;
    setFlash(lastAction);
    const t=window.setTimeout(()=>setFlash(null),1100);
    return()=>window.clearTimeout(t);
  },[lastAt,lastAction]);
  const closeRules=useCallback(()=>{
    setRulesOpen(false);
    try{localStorage.setItem(RULES_SEEN_KEY,"1");}catch{}
  },[]);
  const run=useCallback(async(fn:()=>Promise<ViewerState>)=>{
    setBusy(true);setError(null);
    try{applyState(await fn());}catch(err){setError(cleanError(err));}
    finally{setBusy(false);}
  },[applyState]);
  const me=findPlayer(players,myId);
  const myRole:Role=room?.guesser_id===myId&&myId?"guesser":room?.referee_id===myId&&myId?"referee":"player";
  const isHost=!!room&&room.host_player_id===myId;
  const guesser=findPlayer(players,room?.guesser_id??null);
  const referee=findPlayer(players,room?.referee_id??null);
  async function handleJoin(){
    const pseudo=joinName.trim();
    if(!pseudo)return setError("Choisis un pseudo.");
    localStorage.setItem("taboo-name",pseudo);
    await run(()=>joinRoom(code,pseudo,joinTeam));
  }
  async function handleLeave(){
    try{await leaveRoom(code);}catch{}
    router.push("/");
  }
  function inviteFriends(){
    const origin=sessionStorage.getItem("taboo-rg-origin");
    const launch=sessionStorage.getItem("taboo-rg-launch");
    if(origin&&launch&&window.parent!==window){
      window.parent.postMessage({v:1,game:"tabou",type:"rg:invite-request",launch},origin);
    }else{
      void navigator.clipboard.writeText(window.location.href).catch(()=>undefined);
    }
  }
  /* ------------------------------------------------------------------ */
  /*  8. Rendu                                                           */
  /* ------------------------------------------------------------------ */
  if (loading) {
    return (
      <Shell>
        <div className="panel flex min-h-[16rem] items-center justify-center p-8">
          <p className="animate-pulse text-sm font-black uppercase tracking-[0.2em] text-slate-500">
            Connexion à la room {code}…
          </p>
        </div>
      </Shell>
    );
  }

  // Erreur de connexion / configuration : ne surtout pas afficher
  // "Room introuvable", qui enverrait l'utilisateur sur une fausse piste.
  if (!room && error) {
    return (
      <Shell>
        <div className="panel p-8 text-center animate-pop">
          <p className="text-5xl">🔌</p>
          <h1 className="mt-4 text-2xl font-black uppercase tracking-tight text-white">
            Connexion impossible
          </h1>
          <p className="mt-2 text-sm font-medium text-slate-400">{error}</p>
          <button
            type="button"
            onClick={() => window.location.reload()}
            className="btn-primary mt-6 w-full py-4"
          >
            Réessayer
          </button>
          <button
            type="button"
            onClick={() => router.push("/")}
            className="btn-ghost mt-3 w-full py-3.5"
          >
            Retour à l’accueil
          </button>
        </div>
      </Shell>
    );
  }

  if (notFound || !room) {
    return (
      <Shell>
        <div className="panel p-8 text-center animate-pop">
          <p className="text-5xl">🕵️</p>
          <h1 className="mt-4 text-2xl font-black uppercase tracking-tight text-white">
            Room introuvable
          </h1>
          <p className="mt-2 text-sm font-medium text-slate-400">
            Le code <span className="font-black text-white">{code}</span> ne
            correspond à aucune partie en cours.
          </p>
          <button
            type="button"
            onClick={() => router.push("/")}
            className="btn-primary mt-6 w-full py-4"
          >
            Retour à l’accueil
          </button>
        </div>
      </Shell>
    );
  }

  const teamA = teamPlayers(players, "A");
  const teamB = teamPlayers(players, "B");

  /* --- Je ne suis pas (encore) dans cette room --- */
  if (!me) {
    const full = { A: teamA.length >= MAX_PER_TEAM, B: teamB.length >= MAX_PER_TEAM };
    return (
      <Shell>
        <GameHeader code={room.code} />
        <div className="panel mt-5 p-5 animate-pop">
          {room.status !== "lobby" ? (
            <>
              <h1 className="text-xl font-black uppercase tracking-tight text-white">
                La partie a déjà commencé
              </h1>
              <p className="mt-2 text-sm font-medium text-slate-400">
                Impossible de rejoindre la room {room.code} en cours de manche.
                Attends la fin ou lance ta propre partie.
              </p>
              <button
                type="button"
                onClick={() => router.push("/")}
                className="btn-primary mt-6 w-full py-4"
              >
                Créer une partie
              </button>
            </>
          ) : (
            <>
              <h1 className="text-xl font-black uppercase tracking-tight text-white">
                Rejoindre la room {room.code}
              </h1>
              <label className="label mt-5" htmlFor="join-name">
                Ton pseudo
              </label>
              <input
                id="join-name"
                className="field"
                placeholder="Alex"
                maxLength={20}
                value={joinName}
                onChange={(e) => setJoinName(e.target.value)}
              />
              <p className="label mt-5">Ton équipe</p>
              <div className="grid grid-cols-2 gap-3">
                {(["A", "B"] as const).map((t) => {
                  const count = t === "A" ? teamA.length : teamB.length;
                  const disabled = full[t];
                  const active = joinTeam === t && !disabled;
                  return (
                    <button
                      key={t}
                      type="button"
                      disabled={disabled}
                      onClick={() => setJoinTeam(t)}
                      className={`rounded-2xl border-2 px-4 py-4 text-left transition disabled:opacity-40 ${
                        active
                          ? t === "A"
                            ? "border-teamA bg-teamA/15 shadow-glow"
                            : "border-teamB bg-teamB/15 shadow-glowB"
                          : "border-white/10 bg-white/[0.03]"
                      }`}
                    >
                      <span
                        className={`block text-3xl font-black leading-none ${
                          t === "A" ? "text-teamA" : "text-teamB"
                        }`}
                      >
                        {t}
                      </span>
                      <span className="mt-1 block text-[11px] font-bold uppercase tracking-widest text-slate-400">
                        {disabled ? "Complète" : `${count} / ${MAX_PER_TEAM}`}
                      </span>
                    </button>
                  );
                })}
              </div>
              {error && <ErrorNote>{error}</ErrorNote>}
              <button
                type="button"
                onClick={handleJoin}
                disabled={busy || full[joinTeam]}
                className="btn-primary mt-6 w-full py-4"
              >
                {busy ? "…" : "Rejoindre"}
              </button>
            </>
          )}
        </div>
      </Shell>
    );
  }

  /* --- Lobby --- */
  if (room.status === "lobby") {
    return (
      <Shell>
        <GameHeader
          code={room.code}
          onLeave={handleLeave}
          onRules={() => setRulesOpen(true)}
        />
        <ConnectionNote live={live} reconnected={reconnected} />
        <div className="mt-5">
          <Lobby
            room={room}
            players={players}
            myId={myId}
            onlineIds={onlineIds}
            busy={busy}
            onStart={() => run(() => startGame(code))}
            onSwitchTeam={(t) => run(() => joinRoom(code, me.name, t))}
            onRules={() => setRulesOpen(true)}
            onInvite={inviteFriends}
          />
        </div>
        {error && <ErrorNote>{error}</ErrorNote>}
        <RulesModal open={rulesOpen} onClose={closeRules} />
      </Shell>
    );
  }

  /* --- Fin de partie --- */
  if (room.status === "finished") {
    return (
      <Shell>
        <GameHeader
          code={room.code}
          onLeave={handleLeave}
          onRules={() => setRulesOpen(true)}
        />
        <ConnectionNote live={live} reconnected={reconnected} />
        <RulesModal open={rulesOpen} onClose={closeRules} />
        <div className="mt-5">
          <GameOver
            room={room}
            isHost={isHost}
            busy={busy}
            onReplay={() => run(() => restartGame(code))}
            onNewGame={() => router.push("/")}
          />
        </div>
        {error && <ErrorNote>{error}</ErrorNote>}
      </Shell>
    );
  }

  /* --- Partie en cours --- */
  return (
    <Shell>
      <GameHeader
        code={room.code}
        turnNumber={room.turn_number}
        showTurns
        onLeave={handleLeave}
        onRules={() => setRulesOpen(true)}
      />
      <RulesModal open={rulesOpen} onClose={closeRules} />
      <ConnectionNote live={live} reconnected={reconnected} />

      <div className="mt-4 space-y-4">
        <ScoreBoard
          scoreA={room.score_a}
          scoreB={room.score_b}
          currentTeam={room.current_team}
        />

        <div className="panel px-4 py-3.5">
          <Timer remainingMs={remainingMs} />
          <div className="mt-3 flex flex-wrap items-center gap-x-4 gap-y-1 text-[11px] font-bold uppercase tracking-wider">
            <span className="text-slate-500">
              Fait deviner{" "}
              <span
                className={
                  room.current_team === "A" ? "text-teamA" : "text-teamB"
                }
              >
                {guesser?.name ?? "—"}
              </span>
            </span>
            <span className="text-slate-500">
              Arbitre <span className="text-white">{referee?.name ?? "—"}</span>
            </span>
          </div>
        </div>

        <TabooCard
          card={card}
          canSee={canSeeCard}
          role={myRole}
          myTeam={me.team}
          currentTeam={room.current_team}
          shake={flash === "buzz"}
        />

        <GameControls
          role={myRole}
          myTeam={me.team}
          currentTeam={room.current_team}
          busy={busy}
          onFound={() => run(() => gameAction(code, "found"))}
          onPass={() => run(() => gameAction(code, "pass"))}
          onBuzz={() => run(() => gameAction(code, "buzz"))}
        />

        {error && <ErrorNote>{error}</ErrorNote>}
      </div>

      {flash && <ActionFlash action={flash} />}
    </Shell>
  );
}

/* -------------------------------------------------------------------- */
/*  Petits composants locaux                                            */
/* -------------------------------------------------------------------- */

function Shell({ children }: { children: React.ReactNode }) {
  return (
    <main className="mx-auto w-full max-w-2xl px-4 py-5 sm:py-8">
      {children}
      <Credit />
    </main>
  );
}

function ErrorNote({ children }: { children: React.ReactNode }) {
  return (
    <p
      role="alert"
      className="mt-4 rounded-2xl border border-teamB/35 bg-teamB/10 px-4 py-3 text-sm font-semibold text-teamB-glow animate-slide-up"
    >
      {children}
    </p>
  );
}

function ConnectionNote({
  live,
  reconnected,
}: {
  live: boolean;
  reconnected: boolean;
}) {
  if (reconnected) {
    return (
      <p className="mt-3 rounded-xl border border-emerald-400/30 bg-emerald-400/10 px-3 py-2 text-center text-[11px] font-black uppercase tracking-widest text-emerald-300 animate-slide-up">
        Connexion rétablie
      </p>
    );
  }
  if (!live) {
    return (
      <p className="mt-3 rounded-xl border border-gold/30 bg-gold/10 px-3 py-2 text-center text-[11px] font-black uppercase tracking-widest text-gold animate-pulse">
        Reconnexion…
      </p>
    );
  }
  return null;
}

/** Plein écran très court, visible par TOUS les joueurs (colonne last_action). */
function ActionFlash({ action }: { action: GameActionName }) {
  const config = {
    found: { label: "Mot trouvé !", className: "text-emerald-300", emoji: "✅" },
    pass: { label: "Passé", className: "text-slate-200", emoji: "⏭️" },
    buzz: { label: "Mot interdit !", className: "text-teamB", emoji: "🚨" },
  }[action];

  return (
    <div
      aria-hidden
      className="pointer-events-none fixed inset-0 z-50 flex items-center justify-center bg-ink-900/55 backdrop-blur-sm animate-flash-in"
    >
      <div className="text-center">
        <p className="text-7xl">{config.emoji}</p>
        <p
          className={`mt-3 text-3xl font-black uppercase tracking-tighter ${config.className}`}
        >
          {config.label}
        </p>
      </div>
    </div>
  );
}
