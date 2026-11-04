-- Optional ongoing partner sync. Apply after 001_initial_schema.sql.
-- Only participant metadata and owner-selected snapshot fields are exposed.
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.cc_partner_links (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 partner_id uuid references auth.users(id) on delete set null,
 consent jsonb not null default '{"fields":[],"home":false,"calendar":false,"automatic_updates":false}',
 revoked boolean not null default false,
 revision bigint not null default 0,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 expires_at timestamptz not null default (now()+interval '90 days'),
 check(partner_id is null or partner_id<>owner_id)
);
create table if not exists public.cc_partner_invites (
 link_id uuid primary key references public.cc_partner_links(id) on delete cascade,
 token_hash text not null unique,
 expires_at timestamptz not null default(now()+interval '24 hours'),
 claimed_at timestamptz
);
create table if not exists public.cc_partner_snapshots (
 link_id uuid primary key references public.cc_partner_links(id) on delete cascade,
 payload jsonb not null,
 expires_at timestamptz not null
);
alter table public.cc_partner_links enable row level security;
alter table public.cc_partner_invites enable row level security;
alter table public.cc_partner_snapshots enable row level security;
revoke all on public.cc_partner_links,public.cc_partner_invites,public.cc_partner_snapshots from anon,authenticated;
grant select on public.cc_partner_links,public.cc_partner_snapshots to authenticated;
create policy cc_partner_participants on public.cc_partner_links for select to authenticated
 using (auth.uid()=owner_id or auth.uid()=partner_id);
create policy cc_partner_selected_snapshot on public.cc_partner_snapshots for select to authenticated
 using (expires_at>now() and exists(select 1 from public.cc_partner_links l
   where l.id=link_id and not l.revoked and l.expires_at>now()
   and (auth.uid()=l.owner_id or auth.uid()=l.partner_id)
   and ((l.consent->>'home')::boolean or (l.consent->>'calendar')::boolean)));

-- Internal allow-list strips unknown/private fields even from a modified app.
create or replace function public.cc_partner_filter(p_snapshot jsonb,p_consent jsonb)
 returns jsonb language plpgsql immutable set search_path='' as $$
declare output jsonb; f text; k text; keys text[];
begin
 output=jsonb_build_object('c',p_snapshot->'c','x',p_snapshot->'x');
 if coalesce((p_consent->>'automatic_updates')::boolean,false)=false then return output;end if;
 for f in select jsonb_array_elements_text(coalesce(p_consent->'fields','[]')) loop
  -- A Calendar-only grant never includes Home-only mood, notes or other
  -- observations, even when a modified client attempts to submit them.
  if not coalesce((p_consent->>'home')::boolean,false) and
     (not coalesce((p_consent->>'calendar')::boolean,false) or
      not(f=any(array['next_period','fertile','ovulation','pms']))) then
   continue;
  end if;
  keys=case f when 'name' then array['n'] when 'phase' then array['ph','cd']
   when 'next_period' then array['np','dl'] when 'mood' then array['m']
   when 'symptoms' then array['s'] when 'pain' then array['p']
   when 'fertile' then array['fs','fe'] when 'ovulation' then array['ov']
   when 'pms' then array['ps','pe'] when 'support_tip' then array['t']
   when 'note' then array['no'] else array[]::text[] end;
  foreach k in array keys loop
   if p_snapshot ? k then output=output||jsonb_build_object(k,p_snapshot->k);end if;
  end loop;
 end loop;
 return output;
end $$;
create or replace function public.cc_partner_validate_consent(p jsonb)
 returns jsonb language plpgsql immutable set search_path='' as $$
declare f text;
begin
 if jsonb_typeof(p) is distinct from 'object' or jsonb_typeof(p->'fields') is distinct from 'array'
   or jsonb_typeof(p->'home') is distinct from 'boolean' or jsonb_typeof(p->'calendar') is distinct from 'boolean'
   or jsonb_typeof(p->'automatic_updates') is distinct from 'boolean' then raise exception 'Invalid sharing permissions';end if;
 for f in select jsonb_array_elements_text(p->'fields') loop
  if not(f=any(array['name','phase','next_period','mood','symptoms','pain','fertile','ovulation','pms','support_tip','note']))then raise exception 'Unknown sharing field';end if;
 end loop;
 return jsonb_build_object('fields',p->'fields','home',p->'home','calendar',p->'calendar','automatic_updates',p->'automatic_updates');
end $$;

create or replace function public.cc_partner_connection_json(p_id uuid)
 returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('id',l.id,'owner_id',l.owner_id,'partner_id',l.partner_id,
  'consent',l.consent,'revoked',l.revoked,'revision',l.revision,
  'created_at',l.created_at,'updated_at',l.updated_at,'expires_at',l.expires_at,
  'snapshot',case when not l.revoked and l.expires_at>now() and s.expires_at>now()
    and ((l.consent->>'home')::boolean or(l.consent->>'calendar')::boolean)
    then public.cc_partner_filter(s.payload,l.consent) else null end)
 from public.cc_partner_links l left join public.cc_partner_snapshots s on s.link_id=l.id
 where l.id=p_id and (auth.uid()=l.owner_id or auth.uid()=l.partner_id)
$$;
create or replace function public.cc_partner_create_invite(p_consent jsonb)
 returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid=auth.uid();link uuid;token text;consent jsonb;
begin
 if uid is null then raise exception 'Sign in before creating an invite';end if;
 consent=public.cc_partner_validate_consent(p_consent);
 if (select count(*) from public.cc_partner_links where owner_id=uid and not revoked)>20 then raise exception 'Remove an unused connection before inviting again';end if;
 token=encode(extensions.gen_random_bytes(24),'hex');
 insert into public.cc_partner_links(owner_id,consent)values(uid,consent)returning id into link;
 insert into public.cc_partner_invites(link_id,token_hash)values(link,encode(extensions.digest(token,'sha256'),'hex'));
 return jsonb_build_object('code','CCLINK-'||token,'connection',public.cc_partner_connection_json(link));
end $$;
create or replace function public.cc_partner_accept_invite(p_code text)
 returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid=auth.uid();token text;invite public.cc_partner_invites%rowtype;link public.cc_partner_links%rowtype;
begin
 if uid is null then raise exception 'Sign in before connecting';end if;
 token=regexp_replace(trim(p_code),'^CCLINK-','');
 if token !~ '^[0-9a-f]{48}$' then raise exception 'Invalid partner invitation';end if;
 select * into invite from public.cc_partner_invites where token_hash=encode(extensions.digest(token,'sha256'),'hex') for update;
 if not found or invite.claimed_at is not null or invite.expires_at<=now()then raise exception 'Invitation is invalid, expired or already used';end if;
 select * into link from public.cc_partner_links where id=invite.link_id for update;
 if link.revoked or link.expires_at<=now() or link.owner_id=uid or link.partner_id is not null then raise exception 'Invitation cannot be accepted';end if;
 update public.cc_partner_links set partner_id=uid,updated_at=now()where id=link.id;
 update public.cc_partner_invites set claimed_at=now()where link_id=link.id;
 return public.cc_partner_connection_json(link.id);
end $$;
create or replace function public.cc_partner_connections()
 returns jsonb language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(public.cc_partner_connection_json(l.id)order by l.updated_at desc),'[]'::jsonb)
 from public.cc_partner_links l where auth.uid() is not null and(auth.uid()=l.owner_id or auth.uid()=l.partner_id)
$$;
create or replace function public.cc_partner_publish(p_link_id uuid,p_snapshot jsonb,p_consent jsonb)
 returns void language plpgsql security definer set search_path='' as $$
declare link public.cc_partner_links%rowtype;v_consent jsonb;selected jsonb;expires timestamptz;
begin
 select * into link from public.cc_partner_links where id=p_link_id for update;
 if not found or auth.uid() is null or link.owner_id<>auth.uid() or link.revoked or link.expires_at<=now()then raise exception 'This connection is not available to publish';end if;
 v_consent=public.cc_partner_validate_consent(p_consent);
 if jsonb_typeof(p_snapshot)<>'object' or pg_column_size(p_snapshot)>32768 then raise exception 'Invalid partner update';end if;
 expires=to_timestamp((p_snapshot->>'x')::numeric/1000);
 if expires<=now()or expires>now()+interval '8 days' then raise exception 'Partner update expiry is invalid';end if;
 -- Client times may describe observations; server time is the update authority.
 selected=public.cc_partner_filter(p_snapshot,v_consent);
 update public.cc_partner_links set consent=v_consent,revision=revision+1,updated_at=now()where id=p_link_id;
 if (v_consent->>'automatic_updates')::boolean then
  insert into public.cc_partner_snapshots(link_id,payload,expires_at)values(p_link_id,selected,expires)
   on conflict(link_id)do update set payload=excluded.payload,expires_at=excluded.expires_at;
 else delete from public.cc_partner_snapshots where link_id=p_link_id;end if;
end $$;
create or replace function public.cc_partner_revoke(p_link_id uuid)
 returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid()is null or not exists(select 1 from public.cc_partner_links where id=p_link_id and owner_id=auth.uid())then raise exception 'Only the owner can revoke access';end if;
 update public.cc_partner_links set revoked=true,updated_at=now(),revision=revision+1 where id=p_link_id;
 delete from public.cc_partner_snapshots where link_id=p_link_id;
 delete from public.cc_partner_invites where link_id=p_link_id;
end $$;
create or replace function public.cc_partner_disconnect(p_link_id uuid)
 returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid()is null or not exists(select 1 from public.cc_partner_links where id=p_link_id and partner_id=auth.uid())then raise exception 'Only the connected partner can disconnect';end if;
 update public.cc_partner_links set revoked=true,updated_at=now(),revision=revision+1 where id=p_link_id;
 delete from public.cc_partner_snapshots where link_id=p_link_id;
 delete from public.cc_partner_invites where link_id=p_link_id;
end $$;
-- All helper functions are inaccessible to client roles.
revoke execute on function public.cc_partner_filter(jsonb,jsonb),public.cc_partner_validate_consent(jsonb),public.cc_partner_connection_json(uuid) from public,anon,authenticated;
revoke execute on function public.cc_partner_create_invite(jsonb),public.cc_partner_accept_invite(text),public.cc_partner_connections(),public.cc_partner_publish(uuid,jsonb,jsonb),public.cc_partner_revoke(uuid),public.cc_partner_disconnect(uuid) from public,anon;
grant execute on function public.cc_partner_create_invite(jsonb),public.cc_partner_accept_invite(text),public.cc_partner_connections(),public.cc_partner_publish(uuid,jsonb,jsonb),public.cc_partner_revoke(uuid),public.cc_partner_disconnect(uuid) to authenticated;
