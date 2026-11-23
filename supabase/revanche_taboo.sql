-- Taboo Live sur Supabase Revanche Games.
-- Migration ADDITIVE : aucune table/fonction existante de Revanche Games modifiée.
-- Authentification par jeton aleatoire propre au navigateur (aucun compte requis).
-- IMPORTANT : ne pas executer l'ancien supabase/schema.sql sur la base partagee :
-- il contient des DROP TABLE public.rooms/players/cards.
create table if not exists public.taboo_cards (
  id integer primary key,
  word text not null,
  forbidden text[] not null check (cardinality(forbidden) = 5),
  category text not null default 'Général'
);
create table if not exists public.taboo_rooms (
  id uuid primary key default gen_random_uuid(),
  code text unique not null check (code ~ '^[A-Z0-9]{6}$'),
  host_player_id uuid,
  status text not null default 'lobby' check (status in ('lobby','playing','finished')),
  current_team text not null default 'A' check (current_team in ('A','B')),
  current_card_id integer references public.taboo_cards(id),
  used_card_ids integer[] not null default '{}'::integer[],
  score_a integer not null default 0 check (score_a >= 0),
  score_b integer not null default 0 check (score_b >= 0),
  turn_ends_at timestamptz,
  turn_number integer not null default 0,
  guesser_id uuid,
  referee_id uuid,
  created_at timestamptz not null default now()
);
create table if not exists public.taboo_players (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.taboo_rooms(id) on delete cascade,
  token_hash text not null,
  name text not null check (char_length(name) between 1 and 24),
  team text not null check (team in ('A','B')),
  role text not null default 'player' check (role in ('guesser','referee','player')),
  connected boolean not null default true,
  created_at timestamptz not null default now(),
  unique (room_id, token_hash)
);
create index if not exists taboo_players_room_idx on public.taboo_players(room_id);
create index if not exists taboo_rooms_code_idx on public.taboo_rooms(code);
create index if not exists taboo_players_token_idx on public.taboo_players(token_hash);
alter table public.taboo_cards enable row level security;
alter table public.taboo_rooms enable row level security;
alter table public.taboo_players enable row level security;
-- Aucun acces direct aux tables depuis le navigateur. Tout passe par les RPC.
revoke all on public.taboo_cards, public.taboo_rooms, public.taboo_players from public, anon, authenticated;
grant usage on schema public to anon, authenticated;

create or replace function public.taboo_create_room(p_code text, p_name text, p_token text)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_room public.taboo_rooms%rowtype;
  v_player uuid;
  v_token_hash text;
  v_name text := left(trim(coalesce(p_name,'')),24);
  v_code text := upper(trim(coalesce(p_code,'')));
begin
  if v_name = '' then raise exception 'Entre ton prenom.'; end if;
  if v_code !~ '^[A-Z0-9]{6}$' then raise exception 'Code de room invalide.'; end if;
  if p_token is null or p_token !~ '^[a-f0-9]{64}$' then raise exception 'Session de joueur invalide.'; end if;
  v_token_hash := encode(sha256(decode(p_token,'hex')),'hex');
  if (select count(*) from public.taboo_rooms r
      join public.taboo_players p on p.room_id=r.id
      where p.token_hash=v_token_hash and r.host_player_id=p.id
      and r.created_at > now() - interval '1 hour') >= 10 then
    raise exception 'Trop de salons crees. Reessaie plus tard.';
  end if;
  insert into public.taboo_rooms(code) values(v_code) returning * into v_room;
  insert into public.taboo_players(room_id,token_hash,name,team)
    values(v_room.id,v_token_hash,v_name,'A') returning id into v_player;
  update public.taboo_rooms set host_player_id=v_player where id=v_room.id;
  return jsonb_build_object('code',v_code,'id',v_room.id);
end $$;

create or replace function public.taboo_join_room(p_code text, p_name text, p_team text, p_token text)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_room public.taboo_rooms%rowtype;
  v_player public.taboo_players%rowtype;
  v_token_hash text;
  v_name text := left(trim(coalesce(p_name,'')),24);
  v_team text := upper(trim(coalesce(p_team,'')));
  v_count integer;
begin
  if v_name = '' then raise exception 'Entre ton prenom.'; end if;
  if v_team not in ('A','B') then raise exception 'Equipe invalide.'; end if;
  if p_token is null or p_token !~ '^[a-f0-9]{64}$' then raise exception 'Session de joueur invalide.'; end if;
  v_token_hash := encode(sha256(decode(p_token,'hex')),'hex');
  select * into v_room from public.taboo_rooms where code=upper(trim(p_code)) for update;
  if v_room.id is null then raise exception 'Room introuvable.'; end if;
  select * into v_player from public.taboo_players
    where room_id=v_room.id and token_hash=v_token_hash;
  if v_room.status <> 'lobby' then
    if v_player.id is null then raise exception 'La partie a deja commence.'; end if;
    update public.taboo_players set connected=true where id=v_player.id returning * into v_player;
    return jsonb_build_object('id',v_player.id,'name',v_player.name,'team',v_player.team);
  end if;
  select count(*) into v_count from public.taboo_players
    where room_id=v_room.id and team=v_team and (v_player.id is null or id <> v_player.id);
  if v_count >= 4 then raise exception 'Cette equipe est complete.'; end if;
  if v_player.id is null then
    insert into public.taboo_players(room_id,token_hash,name,team)
      values(v_room.id,v_token_hash,v_name,v_team) returning * into v_player;
  else
    update public.taboo_players set name=v_name,team=v_team,connected=true
      where id=v_player.id returning * into v_player;
  end if;
  return jsonb_build_object('id',v_player.id,'name',v_player.name,'team',v_player.team);
end $$;

create or replace function public.taboo_get_room_snapshot(p_code text)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare v_room public.taboo_rooms%rowtype; v_players jsonb;
begin
  select * into v_room from public.taboo_rooms where code=upper(trim(p_code));
  if v_room.id is null then raise exception 'Room introuvable.'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',p.id,'name',p.name,'team',p.team,'role',p.role,'connected',p.connected
  ) order by p.created_at), '[]'::jsonb)
  into v_players from public.taboo_players p where p.room_id=v_room.id;
  return jsonb_build_object('room',to_jsonb(v_room),'players',v_players);
end $$;

create or replace function public.taboo_start_game(p_code text, p_token text)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_room public.taboo_rooms%rowtype;
  v_uid uuid; v_a uuid; v_b uuid; v_card_id integer;
begin
  if p_token is null or p_token !~ '^[a-f0-9]{64}$' then raise exception 'Session invalide.'; end if;
  select * into v_room from public.taboo_rooms where code=upper(trim(p_code)) for update;
  if v_room.id is null then raise exception 'Room introuvable.'; end if;
  select id into v_uid from public.taboo_players
    where room_id=v_room.id and token_hash=encode(sha256(decode(p_token,'hex')),'hex');
  if v_uid is distinct from v_room.host_player_id then raise exception 'Seul le createur peut lancer la partie.'; end if;
  if v_room.status <> 'lobby' then raise exception 'Cette partie a deja commence.'; end if;
  select id into v_a from public.taboo_players where room_id=v_room.id and team='A' order by created_at limit 1;
  select id into v_b from public.taboo_players where room_id=v_room.id and team='B' order by created_at limit 1;
  if v_a is null or v_b is null then raise exception 'Une personne minimum par equipe.'; end if;
  select id into v_card_id from public.taboo_cards order by random() limit 1;
  if v_card_id is null then raise exception 'Aucune carte disponible.'; end if;
  update public.taboo_rooms set status='playing',current_team='A',
    current_card_id=v_card_id,used_card_ids=array[v_card_id],
    score_a=0,score_b=0,turn_ends_at=now()+interval '75 seconds',
    turn_number=1,guesser_id=v_a,referee_id=v_b
    where id=v_room.id returning * into v_room;
  update public.taboo_players set role=case
    when id=v_a then 'guesser' when id=v_b then 'referee' else 'player' end
    where room_id=v_room.id;
  return to_jsonb(v_room);
end $$;

create or replace function public.taboo_game_action(p_code text,p_action text,p_token text)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_room public.taboo_rooms%rowtype;
  v_uid uuid; v_card_id integer;
begin
  if p_token is null or p_token !~ '^[a-f0-9]{64}$' then raise exception 'Session invalide.'; end if;
  if p_action not in ('found','pass','buzz') then raise exception 'Action invalide.'; end if;
  select * into v_room from public.taboo_rooms where code=upper(trim(p_code)) for update;
  if v_room.id is null or v_room.status <> 'playing' then raise exception 'Partie indisponible.'; end if;
  if now() >= v_room.turn_ends_at then raise exception 'Le tour est termine.'; end if;
  select id into v_uid from public.taboo_players
    where room_id=v_room.id and token_hash=encode(sha256(decode(p_token,'hex')),'hex');
  if v_uid is null then raise exception 'Joueur inconnu.'; end if;
  if p_action='buzz' and v_room.referee_id is distinct from v_uid then
    raise exception 'Seul l arbitre peut buzzer.';
  end if;
  if p_action in ('found','pass') and v_room.guesser_id is distinct from v_uid then
    raise exception 'Seul le joueur qui fait deviner peut agir.';
  end if;
  select id into v_card_id from public.taboo_cards
    where not (id=any(v_room.used_card_ids)) order by random() limit 1;
  if v_card_id is null then
    select id into v_card_id from public.taboo_cards order by random() limit 1;
    v_room.used_card_ids := array[v_card_id];
  else
    v_room.used_card_ids := array_append(v_room.used_card_ids,v_card_id);
  end if;
  update public.taboo_rooms set
    current_card_id=v_card_id, used_card_ids=v_room.used_card_ids,
    score_a=score_a+case when p_action='found' and current_team='A' then 1 else 0 end,
    score_b=score_b+case when p_action='found' and current_team='B' then 1 else 0 end
    where id=v_room.id returning * into v_room;
  return to_jsonb(v_room);
end $$;

create or replace function public.taboo_end_turn(p_code text,p_token text)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_room public.taboo_rooms%rowtype;
  v_uid uuid; v_next text; v_ids uuid[]; v_others uuid[];
  v_guesser uuid; v_referee uuid; v_position integer;
begin
  if p_token is null or p_token !~ '^[a-f0-9]{64}$' then raise exception 'Session invalide.'; end if;
  select * into v_room from public.taboo_rooms where code=upper(trim(p_code)) for update;
  if v_room.id is null or v_room.status <> 'playing' then raise exception 'Partie indisponible.'; end if;
  select id into v_uid from public.taboo_players
    where room_id=v_room.id and token_hash=encode(sha256(decode(p_token,'hex')),'hex');
  if v_uid is null then raise exception 'Joueur inconnu.'; end if;
  if now() < v_room.turn_ends_at then raise exception 'Le chrono n est pas termine.'; end if;
  if v_room.turn_number >= 12 then
    update public.taboo_rooms set status='finished',turn_ends_at=null
      where id=v_room.id returning * into v_room;
    return to_jsonb(v_room);
  end if;
  v_next := case when v_room.current_team='A' then 'B' else 'A' end;
  select array_agg(id order by created_at) into v_ids
    from public.taboo_players where room_id=v_room.id and team=v_next;
  select array_agg(id order by created_at) into v_others
    from public.taboo_players where room_id=v_room.id and team<>v_next;
  if v_ids is null or v_others is null then raise exception 'Equipe vide.'; end if;
  v_position := ((v_room.turn_number-1) / 2) % cardinality(v_ids) + 1;
  v_guesser := v_ids[v_position];
  v_referee := v_others[v_position % cardinality(v_others)+1];
  update public.taboo_rooms set current_team=v_next,
    guesser_id=v_guesser,referee_id=v_referee,
    turn_number=turn_number+1,turn_ends_at=now()+interval '75 seconds'
    where id=v_room.id returning * into v_room;
  update public.taboo_players set role=case
    when id=v_guesser then 'guesser' when id=v_referee then 'referee' else 'player' end
    where room_id=v_room.id;
  return to_jsonb(v_room);
end $$;

-- Par defaut, PostgreSQL donne EXECUTE sur les fonctions a PUBLIC : restriction explicite.
revoke all on function public.taboo_create_room(text,text,text) from public;
revoke all on function public.taboo_join_room(text,text,text,text) from public;
revoke all on function public.taboo_get_room_snapshot(text) from public;
revoke all on function public.taboo_start_game(text,text) from public;
revoke all on function public.taboo_game_action(text,text,text) from public;
revoke all on function public.taboo_end_turn(text,text) from public;
grant execute on function public.taboo_create_room(text,text,text) to anon,authenticated;
grant execute on function public.taboo_join_room(text,text,text,text) to anon,authenticated;
grant execute on function public.taboo_get_room_snapshot(text) to anon,authenticated;
grant execute on function public.taboo_start_game(text,text) to anon,authenticated;
grant execute on function public.taboo_game_action(text,text,text) to anon,authenticated;
grant execute on function public.taboo_end_turn(text,text) to anon,authenticated;
