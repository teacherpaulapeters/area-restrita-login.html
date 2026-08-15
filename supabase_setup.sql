-- Tabela de perfis (vinculada ao auth do Supabase)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  nome text,
  email text,
  role text default 'teacher',
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- Habilita Row Level Security
alter table public.profiles enable row level security;

-- Política: usuário só vê o próprio perfil
create policy "Usuário vê próprio perfil"
  on public.profiles for select
  using (auth.uid() = id);

-- Função que cria perfil automaticamente ao cadastrar
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, nome)
  values (new.id, new.email, new.raw_user_meta_data->>'nome');
  return new;
end;
$$ language plpgsql security definer;

-- Trigger que dispara a função acima
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
