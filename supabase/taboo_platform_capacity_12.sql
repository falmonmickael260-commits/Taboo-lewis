create or replace function public.taboo_platform_bind_member(p_code text,p_token text,p_user_id uuid)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_room public.taboo_rooms%rowtype;v_player public.taboo_players%rowtype;v_count integer;
begin
 if p_token is null or p_token !~ '^[a-f0-9]{64}$' then raise exception 'Session invalide.'; end if;
 if p_user_id is null or not exists(select 1 from public.profiles where id=p_user_id)
 then raise exception 'Profil introuvable.'; end if;
 select * into v_room from public.taboo_rooms where code=upper(trim(p_code));
 if v_room.id is null then raise exception 'Salon introuvable.'; end if;
 select * into v_player from public.taboo_players where room_id=v_room.id
  and token_hash=encode(sha256(decode(p_token,'hex')),'hex') for update;
 if v_player.id is null then raise exception 'Rejoins le salon avant d inviter un ami.'; end if;
 if v_player.platform_user_id is not null and v_player.platform_user_id<>p_user_id
 then raise exception 'Cette session appartient a un autre compte.'; end if;
 if exists(select 1 from public.taboo_players where room_id=v_room.id
   and platform_user_id=p_user_id and id<>v_player.id)
 then raise exception 'Ce compte participe deja.'; end if;
 update public.taboo_players set platform_user_id=p_user_id where id=v_player.id;
 select count(*) into v_count from public.taboo_players where room_id=v_room.id;
 return jsonb_build_object('code',v_room.code,'instance',v_room.id::text,
   'capacity',12,'count',v_count,'status',case when v_room.status='lobby' then 'open'
   when v_room.status='playing' then 'started' else 'closed' end);
end $$;
revoke all on function public.taboo_platform_bind_member(text,text,uuid) from public,anon,authenticated;
grant execute on function public.taboo_platform_bind_member(text,text,uuid) to service_role;