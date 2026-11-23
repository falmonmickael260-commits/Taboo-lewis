"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { playerToken, supabase } from "@/lib/supabase";

// Only the official platform may initialize a game session.
// The proof never goes into the room URL or a message to an unrelated site.
const PLATFORM_ORIGINS = new Set([
  "https://kilomax.fr", "https://www.kilomax.fr",
  "https://revanchegames-production.up.railway.app",
  "http://localhost:3000",
]);
type Session = { code: string; token?: string; playerId?: string };

export function sendRoomToPlatform(code: string) {
  if (typeof window === "undefined" || window.parent === window) return;
  const origin = sessionStorage.getItem("taboo-rg-origin");
  const launch = sessionStorage.getItem("taboo-rg-launch");
  if (!origin || !launch || !PLATFORM_ORIGINS.has(origin)) return;
  const saved = localStorage.getItem(`taboo-player-${code}`);
  if (!saved) return;
  window.parent.postMessage({
    v: 1, type: "rg:room", game: "tabou", launch,
    session: { code, token: playerToken() }
  }, origin);
}

export default function PlatformBridge() {
  const router = useRouter();
  useEffect(() => {
    if (window.parent === window) return;
    const receive = async (event: MessageEvent) => {
      if (event.source !== window.parent || !PLATFORM_ORIGINS.has(event.origin)) return;
      const data = event.data;
      if (data?.type !== "rg:bootstrap" || data.v !== 1 || data.game !== "tabou"
        || typeof data.launch !== "string" || data.launch.length > 200) return;
      sessionStorage.setItem("taboo-rg-origin", event.origin);
      sessionStorage.setItem("taboo-rg-launch", data.launch);
      if (typeof data.identity?.username === "string") {
        sessionStorage.setItem("taboo-rg-name", data.identity.username.slice(0,24));
      }
      const admission = data.admission?.session as Session | undefined;
      if (admission?.code && /^[A-Z0-9]{6}$/.test(admission.code) &&
          /^[a-f0-9]{64}$/.test(admission.token || "") &&
          typeof admission.playerId === "string") {
        localStorage.setItem("taboo-lewis-player-token", admission.token!);
        const { data: snapshot, error } = await supabase.rpc("taboo_get_room_snapshot", { p_code: admission.code });
        const player = snapshot?.players?.find((p: {id:string}) => p.id === admission.playerId);
        if (error || !player) {
          window.parent.postMessage({v:1,game:"tabou",type:"rg:join-error",launch:data.launch},event.origin);
          return;
        }
        localStorage.setItem(`taboo-player-${admission.code}`,
          JSON.stringify({playerId:player.id,name:player.name,team:player.team}));
        router.replace(`/room/${admission.code}`);
        return;
      }
      const requested = new URLSearchParams(window.location.search).get("rg_room");
      if (requested && /^[A-Z0-9]{6}$/.test(requested.toUpperCase())) {
        router.replace(`/room/${requested.toUpperCase()}`);
      } else {
        const current = window.location.pathname.match(/^\/room\/([A-Z0-9]{6})$/i);
        if (current) sendRoomToPlatform(current[1].toUpperCase());
      }
      window.dispatchEvent(new Event("taboo-rg-bootstrap"));
    };
    window.addEventListener("message", receive);
    // No secrets in this ready event.
    window.parent.postMessage({type:"rg:ready",v:1,game:"tabou"},"*");
    return () => window.removeEventListener("message", receive);
  }, [router]);
  return null;
}
