import { createClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL || "https://placeholder.supabase.co";
const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY || "placeholder-key";
export const supabase = createClient(url, key, {
  auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false }
});

// Jeton propre au navigateur, conservé entre les parties et jamais partagé dans l'URL.
export function playerToken(): string {
  const keyName = "taboo-lewis-player-token";
  let token = localStorage.getItem(keyName);
  if (!token || !/^[a-f0-9]{64}$/.test(token)) {
    const bytes = crypto.getRandomValues(new Uint8Array(32));
    token = Array.from(bytes, b => b.toString(16).padStart(2, "0")).join("");
    localStorage.setItem(keyName, token);
  }
  return token;
}
