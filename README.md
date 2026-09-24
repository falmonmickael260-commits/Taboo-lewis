# TABOO LIVE

Jeu de type Taboo multijoueur en temps réel : 2 équipes, 4 joueurs maximum par équipe (8 au total), sans compte classique, Room par lien, cartes aléatoires, arbitre, buzzer et manche de 1 min 15.

## Stack
- Next.js + TypeScript
- Supabase Auth (Anonymous Sign-Ins)
- Supabase PostgreSQL + RPC sécurisées
- Supabase Realtime Broadcast
- Vercel

## Mise en route

### 1. Supabase
1. Ouvre ton projet Supabase.
2. **Authentication → Providers → Anonymous Sign-Ins → ON**.
3. **SQL Editor → New query**.
4. Copie-colle tout le contenu de `supabase/schema.sql` et exécute-le.

Le SQL crée les 500 cartes, les rooms, les joueurs, les fonctions sécurisées de création/join/start/action/fin de tour et la configuration Realtime.

### 2. Variables d'environnement
Copie `.env.example` en `.env.local` :

```env
NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=xxxxx
```

Utilise la clé publique/publishable. **Ne mets jamais une service-role key dans GitHub.**

### 3. Local

```bash
npm install
npm run dev
```

### 4. GitHub

Dépose le contenu du dossier dans ton repository GitHub.

### 5. Vercel

Importe le repository dans Vercel et ajoute les mêmes deux variables d'environnement dans les settings du projet.

## Règles du jeu
- 8 joueurs maximum : 4 A + 4 B.
- 1 joueur de l'équipe active fait deviner.
- 1 joueur adverse est arbitre.
- 75 secondes par manche.
- Mot trouvé : +1 et carte suivante.
- Buzz : 0 et carte suivante.
- Passer : 0 et carte suivante.
- Une carte utilisée ne revient pas dans la même partie jusqu'à épuisement du paquet.
- Les rôles tournent automatiquement au changement de manche.

## Test multiplayer
Ouvre le site dans plusieurs fenêtres/appareils, crée une Room, partage le lien et rejoins avec plusieurs noms. Les actions de jeu passent par des fonctions SQL atomiques et les écrans sont rafraîchis par Supabase Realtime Broadcast.

## Important avant lancement public
Le projet protège les mutations critiques par des fonctions RPC `security definer`. Les policies RLS sont volontairement simples pour ce MVP. Avant une grosse ouverture publique, ajouter rate limiting, anti-spam et une politique RLS plus stricte sur les données de joueurs.
