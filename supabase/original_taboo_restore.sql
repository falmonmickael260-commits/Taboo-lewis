-- RESTAURATION TABOO LIVE (UI originale) SUR SUPABASE REVANCHE GAMES
-- Pas de changement des tables de profil, monnaie ni d'authentification.
-- Salons 4 a 6 caracteres, 6 joueurs par equipe, 90 s, 12 tours.
alter table public.taboo_rooms drop constraint if exists taboo_rooms_code_check;
alter table public.taboo_rooms add constraint taboo_rooms_code_check check (code ~ '^[A-Z0-9]{4,6}$');
alter table public.taboo_rooms add column if not exists last_action text check (last_action in ('found','pass','buzz'));
alter table public.taboo_rooms add column if not exists last_action_at timestamptz;
alter table public.taboo_rooms add column if not exists match_id uuid not null default gen_random_uuid();
alter table public.taboo_players add column if not exists joined_at timestamptz not null default now();

create or replace function public.taboo_ui_member(p_room_id uuid,p_token text)
returns uuid language plpgsql stable security definer set search_path=''
as $$
declare v_uid uuid;
begin
 if p_token is null or p_token !~ '^[a-f0-9]{64}$' then return null; end if;
 select id into v_uid from public.taboo_players
  where room_id=p_room_id and token_hash=encode(sha256(decode(p_token,'hex')),'hex');
 return v_uid;
end $$;

create or replace function public.taboo_ui_state(p_code text,p_token text)
returns jsonb language plpgsql stable security definer set search_path=''
as $$
declare v_room public.taboo_rooms%rowtype; v_uid uuid; v_players jsonb; v_card jsonb;
begin
 select * into v_room from public.taboo_rooms where code=upper(trim(coalesce(p_code,'')));
 if v_room.id is null then raise exception 'Room introuvable.'; end if;
 v_uid:=public.taboo_ui_member(v_room.id,p_token);
 select coalesce(jsonb_agg(jsonb_build_object(
  'id',p.id,'room_id',p.room_id,'name',p.name,'team',p.team,'role',p.role,
  'connected',p.connected,'joined_at',p.joined_at,'created_at',p.created_at
 ) order by p.joined_at,p.id),'[]'::jsonb) into v_players
 from public.taboo_players p where p.room_id=v_room.id;
 if v_room.status='playing' and v_uid is not null
   and v_uid in (v_room.guesser_id,v_room.referee_id) then
   select to_jsonb(c) into v_card from public.taboo_cards c where c.id=v_room.current_card_id;
 end if;
 return jsonb_build_object('room',to_jsonb(v_room),'players',v_players,'card',v_card);
end $$;

create or replace function public.taboo_ui_next_card(p_room_id uuid)
returns integer language plpgsql security definer set search_path=''
as $$
declare v_used integer[]; v_card integer;
begin
 select used_card_ids into v_used from public.taboo_rooms where id=p_room_id for update;
 select id into v_card from public.taboo_cards where not(id=any(v_used)) order by random() limit 1;
 if v_card is null then
  v_used:='{}';
  select id into v_card from public.taboo_cards order by random() limit 1;
 end if;
 if v_card is null then raise exception 'Aucune carte de jeu disponible.'; end if;
 update public.taboo_rooms set current_card_id=v_card,used_card_ids=array_append(v_used,v_card)
 where id=p_room_id;
 return v_card;
end $$;

create or replace function public.taboo_ui_assign_roles(p_room_id uuid,p_turn integer)
returns void language plpgsql security definer set search_path=''
as $$
declare v_a uuid[];v_b uuid[];v_guesser uuid;v_referee uuid;v_current text;
begin
 select array_agg(id order by joined_at,id) into v_a from public.taboo_players
 where room_id=p_room_id and team='A';
 select array_agg(id order by joined_at,id) into v_b from public.taboo_players
 where room_id=p_room_id and team='B';
 if coalesce(cardinality(v_a),0)=0 or coalesce(cardinality(v_b),0)=0 then
  raise exception 'Il faut un joueur minimum dans chaque equipe.';
 end if;
 if p_turn%2=1 then
  v_current:='A';
  v_guesser:=v_a[(((p_turn-1)/2)%cardinality(v_a))+1];
  v_referee:=v_b[(((p_turn-1)/2)%cardinality(v_b))+1];
 else
  v_current:='B';
  v_guesser:=v_b[(((p_turn/2)-1)%cardinality(v_b))+1];
  v_referee:=v_a[((p_turn/2)%cardinality(v_a))+1];
 end if;
 update public.taboo_rooms set current_team=v_current,guesser_id=v_guesser,referee_id=v_referee where id=p_room_id;
 update public.taboo_players set role=case when id=v_guesser then 'guesser'
    when id=v_referee then 'referee' else 'player' end where room_id=p_room_id;
end $$;

create or replace function public.taboo_ui_create_room(p_code text,p_name text,p_token text)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_code text:=upper(trim(coalesce(p_code,'')));v_name text:=left(trim(coalesce(p_name,'')),20);
 v_room public.taboo_rooms%rowtype; v_uid uuid;v_hash text;
begin
 if v_name='' then raise exception 'Choisis un pseudo.'; end if;
 if v_code !~ '^[A-Z0-9]{4,6}$' then raise exception 'Code de room invalide.'; end if;
 if p_token is null or p_token !~ '^[a-f0-9]{64}$' then raise exception 'Session joueur invalide.'; end if;
 v_hash:=encode(sha256(decode(p_token,'hex')),'hex');
 if (select count(*) from public.taboo_rooms r join public.taboo_players p
  on p.room_id=r.id and p.id=r.host_player_id
  where p.token_hash=v_hash and r.created_at>now()-interval '1 hour')>=10 then
  raise exception 'Trop de salons crees. Reessaie plus tard.';
 end if;
 insert into public.taboo_rooms(code,current_team) values(v_code,'A') returning * into v_room;
 insert into public.taboo_players(room_id,token_hash,name,team,joined_at)
  values(v_room.id,v_hash,v_name,'A',now()) returning id into v_uid;
 update public.taboo_rooms set host_player_id=v_uid where id=v_room.id;
 return public.taboo_ui_state(v_code,p_token);
end $$;

create or replace function public.taboo_ui_join_room(p_code text,p_name text,p_team text,p_token text)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_room public.taboo_rooms%rowtype;v_uid uuid;v_name text:=left(trim(coalesce(p_name,'')),20);
v_team text:=upper(trim(coalesce(p_team,'')));v_n integer;
begin
 if v_name='' then raise exception 'Choisis un pseudo.'; end if;
 if v_team not in ('A','B') then raise exception 'Equipe invalide.'; end if;
 if p_token is null or p_token !~ '^[a-f0-9]{64}$' then raise exception 'Session joueur invalide.'; end if;
 select * into v_room from public.taboo_rooms where code=upper(trim(p_code)) for update;
 if v_room.id is null then raise exception 'Room introuvable.'; end if;
 v_uid:=public.taboo_ui_member(v_room.id,p_token);
 if v_room.status<>'lobby' then
  if v_uid is null then raise exception 'La partie a deja commence.'; end if;
  update public.taboo_players set connected=true where id=v_uid;
  return public.taboo_ui_state(v_room.code,p_token);
 end if;
 select count(*) into v_n from public.taboo_players
  where room_id=v_room.id and team=v_team and (v_uid is null or id<>v_uid);
 if v_n>=6 then raise exception 'Cette equipe est complete.'; end if;
 if v_uid is null then
  insert into public.taboo_players(room_id,token_hash,name,team,joined_at)
   values(v_room.id,encode(sha256(decode(p_token,'hex')),'hex'),v_name,v_team,now());
 else
  update public.taboo_players set name=v_name,team=v_team,connected=true where id=v_uid;
 end if;
 return public.taboo_ui_state(v_room.code,p_token);
end $$;

create or replace function public.taboo_ui_start_game(p_code text,p_token text)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_room public.taboo_rooms%rowtype;v_uid uuid;
begin
 select * into v_room from public.taboo_rooms where code=upper(trim(p_code)) for update;
 if v_room.id is null then raise exception 'Room introuvable.'; end if;
 v_uid:=public.taboo_ui_member(v_room.id,p_token);
 if v_uid is null or v_uid is distinct from v_room.host_player_id then raise exception 'Seul l hote peut demarrer.'; end if;
 if v_room.status='playing' then return public.taboo_ui_state(v_room.code,p_token); end if;
 if v_room.status<>'lobby' then raise exception 'Pour rejouer, reviens au salon.'; end if;
 update public.taboo_rooms set status='playing',score_a=0,score_b=0,turn_number=1,
  current_card_id=null,used_card_ids='{}',last_action=null,last_action_at=null,
  turn_ends_at=now()+interval '90 seconds',match_id=gen_random_uuid()
 where id=v_room.id;
 perform public.taboo_ui_assign_roles(v_room.id,1);
 perform public.taboo_ui_next_card(v_room.id);
 return public.taboo_ui_state(v_room.code,p_token);
end $$;

create or replace function public.taboo_ui_game_action(p_code text,p_action text,p_token text)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_room public.taboo_rooms%rowtype;v_uid uuid;v_action text:=lower(trim(coalesce(p_action,'')));
begin
 if v_action not in ('found','pass','buzz') then raise exception 'Action inconnue.'; end if;
 select * into v_room from public.taboo_rooms where code=upper(trim(p_code)) for update;
 if v_room.id is null or v_room.status<>'playing' then raise exception 'Partie indisponible.'; end if;
 v_uid:=public.taboo_ui_member(v_room.id,p_token);
 if v_uid is null then raise exception 'Tu n es pas dans la room.'; end if;
 if now()>v_room.turn_ends_at+interval '2 seconds' then raise exception 'Le temps est ecoule.'; end if;
 if v_action='buzz' and v_uid is distinct from v_room.referee_id then raise exception 'Seul l arbitre peut buzzer.'; end if;
 if v_action in ('found','pass') and v_uid is distinct from v_room.guesser_id
 then raise exception 'Seul le joueur qui fait deviner peut agir.'; end if;
 update public.taboo_rooms set
  score_a=score_a+case when v_action='found' and current_team='A' then 1 else 0 end,
  score_b=score_b+case when v_action='found' and current_team='B' then 1 else 0 end,
  last_action=v_action,last_action_at=clock_timestamp()
 where id=v_room.id;
 perform public.taboo_ui_next_card(v_room.id);
 return public.taboo_ui_state(v_room.code,p_token);
end $$;

create or replace function public.taboo_ui_end_turn(p_code text,p_token text)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_room public.taboo_rooms%rowtype;v_uid uuid;v_next integer;
begin
 select * into v_room from public.taboo_rooms where code=upper(trim(p_code)) for update;
 if v_room.id is null then raise exception 'Room introuvable.'; end if;
 if v_room.status<>'playing' then return public.taboo_ui_state(v_room.code,p_token); end if;
 v_uid:=public.taboo_ui_member(v_room.id,p_token);
 if v_uid is null then raise exception 'Tu n es pas dans la room.'; end if;
 if now()<v_room.turn_ends_at-interval '1 second' then return public.taboo_ui_state(v_room.code,p_token); end if;
 if v_room.turn_number>=12 then
  update public.taboo_rooms set status='finished',turn_ends_at=null where id=v_room.id;
  return public.taboo_ui_state(v_room.code,p_token);
 end if;
 v_next:=v_room.turn_number+1;
 update public.taboo_rooms set turn_number=v_next,last_action=null,last_action_at=null,
  turn_ends_at=now()+interval '90 seconds' where id=v_room.id;
 perform public.taboo_ui_assign_roles(v_room.id,v_next);
 perform public.taboo_ui_next_card(v_room.id);
 return public.taboo_ui_state(v_room.code,p_token);
end $$;

create or replace function public.taboo_ui_restart_game(p_code text,p_token text)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_room public.taboo_rooms%rowtype;v_uid uuid;
begin
 select * into v_room from public.taboo_rooms where code=upper(trim(p_code)) for update;
 if v_room.id is null then raise exception 'Room introuvable.'; end if;
 v_uid:=public.taboo_ui_member(v_room.id,p_token);
 if v_uid is null or v_uid is distinct from v_room.host_player_id then raise exception 'Seul l hote peut relancer.'; end if;
 if v_room.status='playing' then raise exception 'La partie est en cours.'; end if;
 update public.taboo_rooms set status='lobby',score_a=0,score_b=0,turn_number=0,
  turn_ends_at=null,current_team='A',current_card_id=null,used_card_ids='{}',
  guesser_id=null,referee_id=null,last_action=null,last_action_at=null where id=v_room.id;
 update public.taboo_players set role='player' where room_id=v_room.id;
 return public.taboo_ui_state(v_room.code,p_token);
end $$;

create or replace function public.taboo_ui_leave_room(p_code text,p_token text)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_room public.taboo_rooms%rowtype;v_uid uuid;v_newhost uuid;
begin
 select * into v_room from public.taboo_rooms where code=upper(trim(p_code)) for update;
 if v_room.id is null then raise exception 'Room introuvable.'; end if;
 v_uid:=public.taboo_ui_member(v_room.id,p_token);
 if v_uid is null then return public.taboo_ui_state(v_room.code,p_token); end if;
 if v_room.status='lobby' then
   delete from public.taboo_players where id=v_uid;
   if v_uid=v_room.host_player_id then
    select id into v_newhost from public.taboo_players where room_id=v_room.id
      order by joined_at,id limit 1;
    update public.taboo_rooms set host_player_id=v_newhost where id=v_room.id;
   end if;
 else
   update public.taboo_players set connected=false where id=v_uid;
 end if;
 return public.taboo_ui_state(v_room.code,p_token);
end $$;

-- Sous fonctions internes et RPC publiques : privileges explicites.
revoke all on function public.taboo_ui_member(uuid,text) from public,anon,authenticated;
revoke all on function public.taboo_ui_next_card(uuid) from public,anon,authenticated;
revoke all on function public.taboo_ui_assign_roles(uuid,integer) from public,anon,authenticated;
revoke all on function public.taboo_ui_state(text,text) from public;
revoke all on function public.taboo_ui_create_room(text,text,text) from public;
revoke all on function public.taboo_ui_join_room(text,text,text,text) from public;
revoke all on function public.taboo_ui_start_game(text,text) from public;
revoke all on function public.taboo_ui_game_action(text,text,text) from public;
revoke all on function public.taboo_ui_end_turn(text,text) from public;
revoke all on function public.taboo_ui_restart_game(text,text) from public;
revoke all on function public.taboo_ui_leave_room(text,text) from public;
grant execute on function public.taboo_ui_state(text,text) to anon,authenticated;
grant execute on function public.taboo_ui_create_room(text,text,text) to anon,authenticated;
grant execute on function public.taboo_ui_join_room(text,text,text,text) to anon,authenticated;
grant execute on function public.taboo_ui_start_game(text,text) to anon,authenticated;
grant execute on function public.taboo_ui_game_action(text,text,text) to anon,authenticated;
grant execute on function public.taboo_ui_end_turn(text,text) to anon,authenticated;
grant execute on function public.taboo_ui_restart_game(text,text) to anon,authenticated;
grant execute on function public.taboo_ui_leave_room(text,text) to anon,authenticated;
