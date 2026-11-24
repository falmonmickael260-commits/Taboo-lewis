"use client";
import {createClient} from "@supabase/supabase-js";
const url=process.env.NEXT_PUBLIC_SUPABASE_URL||"";
const key=process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY||"";
export const isSupabaseConfigured=url.startsWith("https://")&&key.length>10;
export const supabase=createClient(isSupabaseConfigured?url:"https://placeholder.supabase.co",isSupabaseConfigured?key:"placeholder-key",{auth:{persistSession:false,autoRefreshToken:false,detectSessionInUrl:false}});
export function playerToken():string{
 let t=localStorage.getItem("taboo-lewis-player-token");
 if(!t||!/^[a-f0-9]{64}$/.test(t)){
  t=Array.from(crypto.getRandomValues(new Uint8Array(32)),v=>v.toString(16).padStart(2,"0")).join("");
  localStorage.setItem("taboo-lewis-player-token",t);
 }
 return t;
}
