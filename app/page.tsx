"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";

function makeCode() {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  return Array.from({ length: 6 }, () => chars[Math.floor(Math.random() * chars.length)]).join("");
}

export default function Home() {
  const router = useRouter();
  const [name, setName] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  async function createRoom() {
    if (!name.trim()) return setError("Entre ton prénom.");
    setBusy(true); setError("");
    try {
      const { data: sessionData } = await supabase.auth.getSession();
      if (!sessionData.session) {
        const { error: authError } = await supabase.auth.signInAnonymously();
        if (authError) throw authError;
      }
      const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
      let room = null; let lastError:any = null;
      for (let attempt=0; attempt<10 && !room; attempt++) {
        const code = Array.from({length:6},()=>chars[Math.floor(Math.random()*chars.length)]).join("");
        const { data, error:e } = await supabase.rpc("create_room", { p_code:code, p_name:name.trim() });
        if (!e) room=data; else lastError=e;
      }
      if (!room) throw lastError || new Error("Impossible de créer la room.");
      const { data:userData } = await supabase.auth.getUser();
      const saved={playerId:userData.user!.id,name:name.trim(),team:"A" as const};
      localStorage.setItem(`taboo-player-${room.code}`,JSON.stringify(saved));
      router.push(`/room/${room.code}`);
    } catch(e:any) { setError(e.message || "Impossible de créer la partie."); }
    finally { setBusy(false); }
  }

  return <main className="landing">
    <div className="glow" />
    <section className="heroCard">
      <div className="eyebrow">⚡ TABOO · LIVE</div>
      <h1>Fais deviner.<br /><span>Ne dis pas le mot.</span></h1>
      <p className="lead">Le Taboo multijoueur en direct. Crée une room, partage le lien et joue chacun sur son téléphone.</p>
      <div className="panel">
        <label>Ton prénom</label>
        <input value={name} onChange={e => setName(e.target.value)} placeholder="Ex. Lucas" maxLength={24} />
        <button className="primary" disabled={busy} onClick={createRoom}>{busy ? "Création…" : "Créer une partie →"}</button>
        {error && <div className="error">{error}</div>}
      </div>
      <div className="features"><span>👥 8 joueurs</span><span>⏱️ 1:15</span><span>🎴 500 cartes</span><span>🔴 Buzzer</span></div>
    </section>
  </main>;
}
