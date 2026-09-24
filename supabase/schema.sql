-- TABOO LIVE — Supabase production-oriented schema
-- Dashboard > Authentication > Providers > enable Anonymous Sign-Ins.
-- Then run this file in SQL Editor.

create extension if not exists pgcrypto;

drop table if exists public.players cascade;
drop table if exists public.rooms cascade;
drop table if exists public.cards cascade;

create table public.cards (
  id integer primary key,
  word text not null,
  forbidden text[] not null check (cardinality(forbidden)=5),
  category text not null default 'Général'
);

create table public.rooms (
  id uuid primary key default gen_random_uuid(),
  code text unique not null check (code ~ '^[A-Z0-9]{6}$'),
  host_player_id uuid,
  status text not null default 'lobby' check (status in ('lobby','playing','finished')),
  current_team text not null default 'A' check (current_team in ('A','B')),
  current_card_id integer references public.cards(id),
  used_card_ids integer[] not null default '{}',
  score_a integer not null default 0 check (score_a >= 0),
  score_b integer not null default 0 check (score_b >= 0),
  turn_ends_at timestamptz,
  turn_number integer not null default 0,
  guesser_id uuid,
  referee_id uuid,
  created_at timestamptz not null default now()
);

create table public.players (
  id uuid primary key,
  room_id uuid not null references public.rooms(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 24),
  team text not null check (team in ('A','B')),
  role text not null default 'player' check (role in ('guesser','referee','player')),
  connected boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.rooms add constraint rooms_host_fk foreign key (host_player_id) references public.players(id) on delete set null;
alter table public.rooms add constraint rooms_guesser_fk foreign key (guesser_id) references public.players(id) on delete set null;
alter table public.rooms add constraint rooms_referee_fk foreign key (referee_id) references public.players(id) on delete set null;
create index players_room_idx on public.players(room_id);
create index rooms_code_idx on public.rooms(code);
insert into public.cards(id,word,forbidden,category) values (1,'Lion',array['animal','savane','roi','Afrique','félin'],'Général');
insert into public.cards(id,word,forbidden,category) values (2,'Lion en peluche',array['savane','roi','Afrique','félin','animal'],'Général');
insert into public.cards(id,word,forbidden,category) values (3,'Lion au zoo',array['roi','Afrique','félin','animal','savane'],'Général');
insert into public.cards(id,word,forbidden,category) values (4,'Lion en dessin animé',array['Afrique','félin','animal','savane','roi'],'Général');
insert into public.cards(id,word,forbidden,category) values (5,'Lion dans un film',array['félin','animal','savane','roi','Afrique'],'Général');
insert into public.cards(id,word,forbidden,category) values (6,'Pizza',array['Italie','pâte','fromage','tomate','restaurant'],'Général');
insert into public.cards(id,word,forbidden,category) values (7,'Pizza en peluche',array['pâte','fromage','tomate','restaurant','Italie'],'Général');
insert into public.cards(id,word,forbidden,category) values (8,'Pizza au zoo',array['fromage','tomate','restaurant','Italie','pâte'],'Général');
insert into public.cards(id,word,forbidden,category) values (9,'Pizza en dessin animé',array['tomate','restaurant','Italie','pâte','fromage'],'Général');
insert into public.cards(id,word,forbidden,category) values (10,'Pizza dans un film',array['restaurant','Italie','pâte','fromage','tomate'],'Général');
insert into public.cards(id,word,forbidden,category) values (11,'Football',array['ballon','sport','équipe','but','terrain'],'Général');
insert into public.cards(id,word,forbidden,category) values (12,'Football en peluche',array['sport','équipe','but','terrain','ballon'],'Général');
insert into public.cards(id,word,forbidden,category) values (13,'Football au zoo',array['équipe','but','terrain','ballon','sport'],'Général');
insert into public.cards(id,word,forbidden,category) values (14,'Football en dessin animé',array['but','terrain','ballon','sport','équipe'],'Général');
insert into public.cards(id,word,forbidden,category) values (15,'Football dans un film',array['terrain','ballon','sport','équipe','but'],'Général');
insert into public.cards(id,word,forbidden,category) values (16,'Cinéma',array['film','acteur','écran','salle','Hollywood'],'Général');
insert into public.cards(id,word,forbidden,category) values (17,'Cinéma en peluche',array['acteur','écran','salle','Hollywood','film'],'Général');
insert into public.cards(id,word,forbidden,category) values (18,'Cinéma au zoo',array['écran','salle','Hollywood','film','acteur'],'Général');
insert into public.cards(id,word,forbidden,category) values (19,'Cinéma en dessin animé',array['salle','Hollywood','film','acteur','écran'],'Général');
insert into public.cards(id,word,forbidden,category) values (20,'Cinéma dans un film',array['Hollywood','acteur','écran','salle','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (21,'Avion',array['aéroport','pilote','voler','voyage','ailes'],'Général');
insert into public.cards(id,word,forbidden,category) values (22,'Avion en peluche',array['pilote','voler','voyage','ailes','aéroport'],'Général');
insert into public.cards(id,word,forbidden,category) values (23,'Avion au zoo',array['voler','voyage','ailes','aéroport','pilote'],'Général');
insert into public.cards(id,word,forbidden,category) values (24,'Avion en dessin animé',array['voyage','ailes','aéroport','pilote','voler'],'Général');
insert into public.cards(id,word,forbidden,category) values (25,'Avion dans un film',array['ailes','aéroport','pilote','voler','voyage'],'Général');
insert into public.cards(id,word,forbidden,category) values (26,'Plage',array['sable','mer','soleil','vacances','océan'],'Général');
insert into public.cards(id,word,forbidden,category) values (27,'Plage en peluche',array['mer','soleil','vacances','océan','sable'],'Général');
insert into public.cards(id,word,forbidden,category) values (28,'Plage au zoo',array['soleil','vacances','océan','sable','mer'],'Général');
insert into public.cards(id,word,forbidden,category) values (29,'Plage en dessin animé',array['vacances','océan','sable','mer','soleil'],'Général');
insert into public.cards(id,word,forbidden,category) values (30,'Plage dans un film',array['océan','sable','mer','soleil','vacances'],'Général');
insert into public.cards(id,word,forbidden,category) values (31,'Ordinateur',array['écran','clavier','souris','internet','PC'],'Général');
insert into public.cards(id,word,forbidden,category) values (32,'Ordinateur en peluche',array['clavier','souris','internet','PC','écran'],'Général');
insert into public.cards(id,word,forbidden,category) values (33,'Ordinateur au zoo',array['souris','internet','PC','écran','clavier'],'Général');
insert into public.cards(id,word,forbidden,category) values (34,'Ordinateur en dessin animé',array['internet','PC','écran','clavier','souris'],'Général');
insert into public.cards(id,word,forbidden,category) values (35,'Ordinateur dans un film',array['PC','écran','clavier','souris','internet'],'Général');
insert into public.cards(id,word,forbidden,category) values (36,'Téléphone',array['appel','portable','écran','SMS','smartphone'],'Général');
insert into public.cards(id,word,forbidden,category) values (37,'Téléphone en peluche',array['portable','écran','SMS','smartphone','appel'],'Général');
insert into public.cards(id,word,forbidden,category) values (38,'Téléphone au zoo',array['écran','SMS','smartphone','appel','portable'],'Général');
insert into public.cards(id,word,forbidden,category) values (39,'Téléphone en dessin animé',array['SMS','smartphone','appel','portable','écran'],'Général');
insert into public.cards(id,word,forbidden,category) values (40,'Téléphone dans un film',array['smartphone','appel','portable','écran','SMS'],'Général');
insert into public.cards(id,word,forbidden,category) values (41,'Chocolat',array['cacao','sucré','tablette','bonbon','dessert'],'Général');
insert into public.cards(id,word,forbidden,category) values (42,'Chocolat en peluche',array['sucré','tablette','bonbon','dessert','cacao'],'Général');
insert into public.cards(id,word,forbidden,category) values (43,'Chocolat au zoo',array['tablette','bonbon','dessert','cacao','sucré'],'Général');
insert into public.cards(id,word,forbidden,category) values (44,'Chocolat en dessin animé',array['bonbon','dessert','cacao','sucré','tablette'],'Général');
insert into public.cards(id,word,forbidden,category) values (45,'Chocolat dans un film',array['dessert','cacao','sucré','tablette','bonbon'],'Général');
insert into public.cards(id,word,forbidden,category) values (46,'Guitare',array['musique','cordes','instrument','jouer','concert'],'Général');
insert into public.cards(id,word,forbidden,category) values (47,'Guitare en peluche',array['cordes','instrument','jouer','concert','musique'],'Général');
insert into public.cards(id,word,forbidden,category) values (48,'Guitare au zoo',array['instrument','jouer','concert','musique','cordes'],'Général');
insert into public.cards(id,word,forbidden,category) values (49,'Guitare en dessin animé',array['jouer','concert','musique','cordes','instrument'],'Général');
insert into public.cards(id,word,forbidden,category) values (50,'Guitare dans un film',array['concert','musique','cordes','instrument','jouer'],'Général');
insert into public.cards(id,word,forbidden,category) values (51,'Paris',array['France','capitale','Eiffel','Louvre','Seine'],'Général');
insert into public.cards(id,word,forbidden,category) values (52,'Paris en peluche',array['capitale','Eiffel','Louvre','Seine','France'],'Général');
insert into public.cards(id,word,forbidden,category) values (53,'Paris au zoo',array['Eiffel','Louvre','Seine','France','capitale'],'Général');
insert into public.cards(id,word,forbidden,category) values (54,'Paris en dessin animé',array['Louvre','Seine','France','capitale','Eiffel'],'Général');
insert into public.cards(id,word,forbidden,category) values (55,'Paris dans un film',array['Seine','France','capitale','Eiffel','Louvre'],'Général');
insert into public.cards(id,word,forbidden,category) values (56,'Montagne',array['ski','neige','sommet','alpes','randonnée'],'Général');
insert into public.cards(id,word,forbidden,category) values (57,'Montagne en peluche',array['neige','sommet','alpes','randonnée','ski'],'Général');
insert into public.cards(id,word,forbidden,category) values (58,'Montagne au zoo',array['sommet','alpes','randonnée','ski','neige'],'Général');
insert into public.cards(id,word,forbidden,category) values (59,'Montagne en dessin animé',array['alpes','randonnée','ski','neige','sommet'],'Général');
insert into public.cards(id,word,forbidden,category) values (60,'Montagne dans un film',array['randonnée','ski','neige','sommet','alpes'],'Général');
insert into public.cards(id,word,forbidden,category) values (61,'Piscine',array['eau','nager','bassin','maillot','plongeon'],'Général');
insert into public.cards(id,word,forbidden,category) values (62,'Piscine en peluche',array['nager','bassin','maillot','plongeon','eau'],'Général');
insert into public.cards(id,word,forbidden,category) values (63,'Piscine au zoo',array['bassin','maillot','plongeon','eau','nager'],'Général');
insert into public.cards(id,word,forbidden,category) values (64,'Piscine en dessin animé',array['maillot','plongeon','eau','nager','bassin'],'Général');
insert into public.cards(id,word,forbidden,category) values (65,'Piscine dans un film',array['plongeon','eau','nager','bassin','maillot'],'Général');
insert into public.cards(id,word,forbidden,category) values (66,'Voiture',array['route','moteur','roues','conduire','garage'],'Général');
insert into public.cards(id,word,forbidden,category) values (67,'Voiture en peluche',array['moteur','roues','conduire','garage','route'],'Général');
insert into public.cards(id,word,forbidden,category) values (68,'Voiture au zoo',array['roues','conduire','garage','route','moteur'],'Général');
insert into public.cards(id,word,forbidden,category) values (69,'Voiture en dessin animé',array['conduire','garage','route','moteur','roues'],'Général');
insert into public.cards(id,word,forbidden,category) values (70,'Voiture dans un film',array['garage','route','moteur','roues','conduire'],'Général');
insert into public.cards(id,word,forbidden,category) values (71,'Train',array['gare','rails','wagon','SNCF','voyage'],'Général');
insert into public.cards(id,word,forbidden,category) values (72,'Train en peluche',array['rails','wagon','SNCF','voyage','gare'],'Général');
insert into public.cards(id,word,forbidden,category) values (73,'Train au zoo',array['wagon','SNCF','voyage','gare','rails'],'Général');
insert into public.cards(id,word,forbidden,category) values (74,'Train en dessin animé',array['SNCF','voyage','gare','rails','wagon'],'Général');
insert into public.cards(id,word,forbidden,category) values (75,'Train dans un film',array['voyage','gare','rails','wagon','SNCF'],'Général');
insert into public.cards(id,word,forbidden,category) values (76,'Restaurant',array['manger','menu','serveur','table','cuisine'],'Général');
insert into public.cards(id,word,forbidden,category) values (77,'Restaurant en peluche',array['menu','serveur','table','cuisine','manger'],'Général');
insert into public.cards(id,word,forbidden,category) values (78,'Restaurant au zoo',array['serveur','table','cuisine','manger','menu'],'Général');
insert into public.cards(id,word,forbidden,category) values (79,'Restaurant en dessin animé',array['table','cuisine','manger','menu','serveur'],'Général');
insert into public.cards(id,word,forbidden,category) values (80,'Restaurant dans un film',array['cuisine','manger','menu','serveur','table'],'Général');
insert into public.cards(id,word,forbidden,category) values (81,'Anniversaire',array['gâteau','cadeau','bougies','fête','âge'],'Général');
insert into public.cards(id,word,forbidden,category) values (82,'Anniversaire en peluche',array['cadeau','bougies','fête','âge','gâteau'],'Général');
insert into public.cards(id,word,forbidden,category) values (83,'Anniversaire au zoo',array['bougies','fête','âge','gâteau','cadeau'],'Général');
insert into public.cards(id,word,forbidden,category) values (84,'Anniversaire en dessin animé',array['fête','âge','gâteau','cadeau','bougies'],'Général');
insert into public.cards(id,word,forbidden,category) values (85,'Anniversaire dans un film',array['âge','gâteau','cadeau','bougies','fête'],'Général');
insert into public.cards(id,word,forbidden,category) values (86,'Mariage',array['mariée','robe','amour','cérémonie','époux'],'Général');
insert into public.cards(id,word,forbidden,category) values (87,'Mariage en peluche',array['robe','amour','cérémonie','époux','mariée'],'Général');
insert into public.cards(id,word,forbidden,category) values (88,'Mariage au zoo',array['amour','cérémonie','époux','mariée','robe'],'Général');
insert into public.cards(id,word,forbidden,category) values (89,'Mariage en dessin animé',array['cérémonie','époux','mariée','robe','amour'],'Général');
insert into public.cards(id,word,forbidden,category) values (90,'Mariage dans un film',array['époux','mariée','robe','amour','cérémonie'],'Général');
insert into public.cards(id,word,forbidden,category) values (91,'École',array['élève','professeur','classe','cours','cartable'],'Général');
insert into public.cards(id,word,forbidden,category) values (92,'École en peluche',array['professeur','classe','cours','cartable','élève'],'Général');
insert into public.cards(id,word,forbidden,category) values (93,'École au zoo',array['classe','cours','cartable','élève','professeur'],'Général');
insert into public.cards(id,word,forbidden,category) values (94,'École en dessin animé',array['cours','cartable','élève','professeur','classe'],'Général');
insert into public.cards(id,word,forbidden,category) values (95,'École dans un film',array['cartable','élève','professeur','classe','cours'],'Général');
insert into public.cards(id,word,forbidden,category) values (96,'Hôpital',array['médecin','patient','soins','urgence','infirmière'],'Général');
insert into public.cards(id,word,forbidden,category) values (97,'Hôpital en peluche',array['patient','soins','urgence','infirmière','médecin'],'Général');
insert into public.cards(id,word,forbidden,category) values (98,'Hôpital au zoo',array['soins','urgence','infirmière','médecin','patient'],'Général');
insert into public.cards(id,word,forbidden,category) values (99,'Hôpital en dessin animé',array['urgence','infirmière','médecin','patient','soins'],'Général');
insert into public.cards(id,word,forbidden,category) values (100,'Hôpital dans un film',array['infirmière','médecin','patient','soins','urgence'],'Général');
insert into public.cards(id,word,forbidden,category) values (101,'Chien',array['animal','aboyer','maître','laisse','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (102,'Chien en peluche',array['aboyer','maître','laisse','animal','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (103,'Chien au zoo',array['maître','laisse','animal','aboyer','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (104,'Chien en dessin animé',array['laisse','animal','aboyer','maître','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (105,'Chien dans un film',array['laisse','animal','aboyer','maître','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (106,'Chat',array['animal','miaou','félin','croquettes','griffes'],'Général');
insert into public.cards(id,word,forbidden,category) values (107,'Chat en peluche',array['miaou','félin','croquettes','griffes','animal'],'Général');
insert into public.cards(id,word,forbidden,category) values (108,'Chat au zoo',array['félin','croquettes','griffes','animal','miaou'],'Général');
insert into public.cards(id,word,forbidden,category) values (109,'Chat en dessin animé',array['croquettes','griffes','animal','miaou','félin'],'Général');
insert into public.cards(id,word,forbidden,category) values (110,'Chat dans un film',array['griffes','animal','miaou','félin','croquettes'],'Général');
insert into public.cards(id,word,forbidden,category) values (111,'Éléphant',array['animal','trompe','Afrique','grand','oreilles'],'Général');
insert into public.cards(id,word,forbidden,category) values (112,'Éléphant en peluche',array['trompe','Afrique','grand','oreilles','animal'],'Général');
insert into public.cards(id,word,forbidden,category) values (113,'Éléphant au zoo',array['Afrique','grand','oreilles','animal','trompe'],'Général');
insert into public.cards(id,word,forbidden,category) values (114,'Éléphant en dessin animé',array['grand','oreilles','animal','trompe','Afrique'],'Général');
insert into public.cards(id,word,forbidden,category) values (115,'Éléphant dans un film',array['oreilles','animal','trompe','Afrique','grand'],'Général');
insert into public.cards(id,word,forbidden,category) values (116,'Girafe',array['animal','cou','Afrique','taches','haute'],'Général');
insert into public.cards(id,word,forbidden,category) values (117,'Girafe en peluche',array['cou','Afrique','taches','haute','animal'],'Général');
insert into public.cards(id,word,forbidden,category) values (118,'Girafe au zoo',array['Afrique','taches','haute','animal','cou'],'Général');
insert into public.cards(id,word,forbidden,category) values (119,'Girafe en dessin animé',array['taches','haute','animal','cou','Afrique'],'Général');
insert into public.cards(id,word,forbidden,category) values (120,'Girafe dans un film',array['haute','animal','cou','Afrique','taches'],'Général');
insert into public.cards(id,word,forbidden,category) values (121,'Tigre',array['animal','rayures','félin','orange','jungle'],'Général');
insert into public.cards(id,word,forbidden,category) values (122,'Tigre en peluche',array['rayures','félin','orange','jungle','animal'],'Général');
insert into public.cards(id,word,forbidden,category) values (123,'Tigre au zoo',array['félin','orange','jungle','animal','rayures'],'Général');
insert into public.cards(id,word,forbidden,category) values (124,'Tigre en dessin animé',array['orange','jungle','animal','rayures','félin'],'Général');
insert into public.cards(id,word,forbidden,category) values (125,'Tigre dans un film',array['jungle','animal','rayures','félin','orange'],'Général');
insert into public.cards(id,word,forbidden,category) values (126,'Dauphin',array['animal','mer','nage','mammifère','océan'],'Général');
insert into public.cards(id,word,forbidden,category) values (127,'Dauphin en peluche',array['mer','nage','mammifère','océan','animal'],'Général');
insert into public.cards(id,word,forbidden,category) values (128,'Dauphin au zoo',array['nage','mammifère','océan','animal','mer'],'Général');
insert into public.cards(id,word,forbidden,category) values (129,'Dauphin en dessin animé',array['mammifère','océan','animal','mer','nage'],'Général');
insert into public.cards(id,word,forbidden,category) values (130,'Dauphin dans un film',array['océan','animal','mer','nage','mammifère'],'Général');
insert into public.cards(id,word,forbidden,category) values (131,'Panda',array['animal','Chine','bambou','ours','noir'],'Général');
insert into public.cards(id,word,forbidden,category) values (132,'Panda en peluche',array['Chine','bambou','ours','noir','animal'],'Général');
insert into public.cards(id,word,forbidden,category) values (133,'Panda au zoo',array['bambou','ours','noir','animal','Chine'],'Général');
insert into public.cards(id,word,forbidden,category) values (134,'Panda en dessin animé',array['ours','noir','animal','Chine','bambou'],'Général');
insert into public.cards(id,word,forbidden,category) values (135,'Panda dans un film',array['noir','animal','Chine','bambou','ours'],'Général');
insert into public.cards(id,word,forbidden,category) values (136,'Banane',array['fruit','jaune','peau','manger','régime'],'Général');
insert into public.cards(id,word,forbidden,category) values (137,'Banane en peluche',array['jaune','peau','manger','régime','fruit'],'Général');
insert into public.cards(id,word,forbidden,category) values (138,'Banane au zoo',array['peau','manger','régime','fruit','jaune'],'Général');
insert into public.cards(id,word,forbidden,category) values (139,'Banane en dessin animé',array['manger','régime','fruit','jaune','peau'],'Général');
insert into public.cards(id,word,forbidden,category) values (140,'Banane dans un film',array['régime','fruit','jaune','peau','manger'],'Général');
insert into public.cards(id,word,forbidden,category) values (141,'Pomme',array['fruit','rouge','verger','croquer','jus'],'Général');
insert into public.cards(id,word,forbidden,category) values (142,'Pomme en peluche',array['rouge','verger','croquer','jus','fruit'],'Général');
insert into public.cards(id,word,forbidden,category) values (143,'Pomme au zoo',array['verger','croquer','jus','fruit','rouge'],'Général');
insert into public.cards(id,word,forbidden,category) values (144,'Pomme en dessin animé',array['croquer','jus','fruit','rouge','verger'],'Général');
insert into public.cards(id,word,forbidden,category) values (145,'Pomme dans un film',array['jus','fruit','rouge','verger','croquer'],'Général');
insert into public.cards(id,word,forbidden,category) values (146,'Hamburger',array['pain','viande','frites','fast-food','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (147,'Hamburger en peluche',array['viande','frites','fast-food','pain','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (148,'Hamburger au zoo',array['frites','fast-food','pain','viande','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (149,'Hamburger en dessin animé',array['frites','fast-food','pain','viande','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (150,'Hamburger dans un film',array['fast-food','pain','viande','frites','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (151,'Frites',array['pomme de terre','huile','sel','restaurant','croustillant'],'Général');
insert into public.cards(id,word,forbidden,category) values (152,'Frites en peluche',array['huile','sel','restaurant','croustillant','pomme de terre'],'Général');
insert into public.cards(id,word,forbidden,category) values (153,'Frites au zoo',array['sel','restaurant','croustillant','pomme de terre','huile'],'Général');
insert into public.cards(id,word,forbidden,category) values (154,'Frites en dessin animé',array['restaurant','croustillant','pomme de terre','huile','sel'],'Général');
insert into public.cards(id,word,forbidden,category) values (155,'Frites dans un film',array['croustillant','pomme de terre','huile','sel','restaurant'],'Général');
insert into public.cards(id,word,forbidden,category) values (156,'Glace',array['froid','dessert','cornet','vanille','boule'],'Général');
insert into public.cards(id,word,forbidden,category) values (157,'Glace en peluche',array['dessert','cornet','vanille','boule','froid'],'Général');
insert into public.cards(id,word,forbidden,category) values (158,'Glace au zoo',array['cornet','vanille','boule','froid','dessert'],'Général');
insert into public.cards(id,word,forbidden,category) values (159,'Glace en dessin animé',array['vanille','boule','froid','dessert','cornet'],'Général');
insert into public.cards(id,word,forbidden,category) values (160,'Glace dans un film',array['boule','froid','dessert','cornet','vanille'],'Général');
insert into public.cards(id,word,forbidden,category) values (161,'Café',array['boisson','tasse','matin','espresso','caféine'],'Général');
insert into public.cards(id,word,forbidden,category) values (162,'Café en peluche',array['tasse','matin','espresso','caféine','boisson'],'Général');
insert into public.cards(id,word,forbidden,category) values (163,'Café au zoo',array['matin','espresso','caféine','boisson','tasse'],'Général');
insert into public.cards(id,word,forbidden,category) values (164,'Café en dessin animé',array['espresso','caféine','boisson','tasse','matin'],'Général');
insert into public.cards(id,word,forbidden,category) values (165,'Café dans un film',array['caféine','boisson','tasse','matin','espresso'],'Général');
insert into public.cards(id,word,forbidden,category) values (166,'Thé',array['boisson','tasse','chaud','infusion','sachet'],'Général');
insert into public.cards(id,word,forbidden,category) values (167,'Thé en peluche',array['tasse','chaud','infusion','sachet','boisson'],'Général');
insert into public.cards(id,word,forbidden,category) values (168,'Thé au zoo',array['chaud','infusion','sachet','boisson','tasse'],'Général');
insert into public.cards(id,word,forbidden,category) values (169,'Thé en dessin animé',array['infusion','sachet','boisson','tasse','chaud'],'Général');
insert into public.cards(id,word,forbidden,category) values (170,'Thé dans un film',array['sachet','boisson','tasse','chaud','infusion'],'Général');
insert into public.cards(id,word,forbidden,category) values (171,'Bière',array['boisson','bar','alcool','mousse','verre'],'Général');
insert into public.cards(id,word,forbidden,category) values (172,'Bière en peluche',array['bar','alcool','mousse','verre','boisson'],'Général');
insert into public.cards(id,word,forbidden,category) values (173,'Bière au zoo',array['alcool','mousse','verre','boisson','bar'],'Général');
insert into public.cards(id,word,forbidden,category) values (174,'Bière en dessin animé',array['mousse','verre','boisson','bar','alcool'],'Général');
insert into public.cards(id,word,forbidden,category) values (175,'Bière dans un film',array['verre','boisson','bar','alcool','mousse'],'Général');
insert into public.cards(id,word,forbidden,category) values (176,'Eau',array['boisson','robinet','bouteille','soif','liquide'],'Général');
insert into public.cards(id,word,forbidden,category) values (177,'Eau en peluche',array['robinet','bouteille','soif','liquide','boisson'],'Général');
insert into public.cards(id,word,forbidden,category) values (178,'Eau au zoo',array['bouteille','soif','liquide','boisson','robinet'],'Général');
insert into public.cards(id,word,forbidden,category) values (179,'Eau en dessin animé',array['soif','liquide','boisson','robinet','bouteille'],'Général');
insert into public.cards(id,word,forbidden,category) values (180,'Eau dans un film',array['liquide','boisson','robinet','bouteille','soif'],'Général');
insert into public.cards(id,word,forbidden,category) values (181,'Lunettes',array['yeux','vision','monture','verres','opticien'],'Général');
insert into public.cards(id,word,forbidden,category) values (182,'Lunettes en peluche',array['vision','monture','verres','opticien','yeux'],'Général');
insert into public.cards(id,word,forbidden,category) values (183,'Lunettes au zoo',array['monture','verres','opticien','yeux','vision'],'Général');
insert into public.cards(id,word,forbidden,category) values (184,'Lunettes en dessin animé',array['verres','opticien','yeux','vision','monture'],'Général');
insert into public.cards(id,word,forbidden,category) values (185,'Lunettes dans un film',array['opticien','yeux','vision','monture','verres'],'Général');
insert into public.cards(id,word,forbidden,category) values (186,'Chapeau',array['tête','porter','casquette','mode','soleil'],'Général');
insert into public.cards(id,word,forbidden,category) values (187,'Chapeau en peluche',array['porter','casquette','mode','soleil','tête'],'Général');
insert into public.cards(id,word,forbidden,category) values (188,'Chapeau au zoo',array['casquette','mode','soleil','tête','porter'],'Général');
insert into public.cards(id,word,forbidden,category) values (189,'Chapeau en dessin animé',array['mode','soleil','tête','porter','casquette'],'Général');
insert into public.cards(id,word,forbidden,category) values (190,'Chapeau dans un film',array['soleil','tête','porter','casquette','mode'],'Général');
insert into public.cards(id,word,forbidden,category) values (191,'Chaussure',array['pied','marcher','basket','lacets','semelle'],'Général');
insert into public.cards(id,word,forbidden,category) values (192,'Chaussure en peluche',array['marcher','basket','lacets','semelle','pied'],'Général');
insert into public.cards(id,word,forbidden,category) values (193,'Chaussure au zoo',array['basket','lacets','semelle','pied','marcher'],'Général');
insert into public.cards(id,word,forbidden,category) values (194,'Chaussure en dessin animé',array['lacets','semelle','pied','marcher','basket'],'Général');
insert into public.cards(id,word,forbidden,category) values (195,'Chaussure dans un film',array['semelle','pied','marcher','basket','lacets'],'Général');
insert into public.cards(id,word,forbidden,category) values (196,'Manteau',array['vêtement','hiver','chaud','porter','veste'],'Général');
insert into public.cards(id,word,forbidden,category) values (197,'Manteau en peluche',array['hiver','chaud','porter','veste','vêtement'],'Général');
insert into public.cards(id,word,forbidden,category) values (198,'Manteau au zoo',array['chaud','porter','veste','vêtement','hiver'],'Général');
insert into public.cards(id,word,forbidden,category) values (199,'Manteau en dessin animé',array['porter','veste','vêtement','hiver','chaud'],'Général');
insert into public.cards(id,word,forbidden,category) values (200,'Manteau dans un film',array['veste','vêtement','hiver','chaud','porter'],'Général');
insert into public.cards(id,word,forbidden,category) values (201,'Parapluie',array['mouillé','ouvrir','ombre','météo','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (202,'Parapluie en peluche',array['mouillé','ouvrir','ombre','météo','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (203,'Parapluie au zoo',array['ouvrir','ombre','météo','mouillé','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (204,'Parapluie en dessin animé',array['ombre','météo','mouillé','ouvrir','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (205,'Parapluie dans un film',array['météo','mouillé','ouvrir','ombre','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (206,'Neige',array['hiver','blanc','froid','ski','flocon'],'Général');
insert into public.cards(id,word,forbidden,category) values (207,'Neige en peluche',array['blanc','froid','ski','flocon','hiver'],'Général');
insert into public.cards(id,word,forbidden,category) values (208,'Neige au zoo',array['froid','ski','flocon','hiver','blanc'],'Général');
insert into public.cards(id,word,forbidden,category) values (209,'Neige en dessin animé',array['ski','flocon','hiver','blanc','froid'],'Général');
insert into public.cards(id,word,forbidden,category) values (210,'Neige dans un film',array['flocon','hiver','blanc','froid','ski'],'Général');
insert into public.cards(id,word,forbidden,category) values (211,'Orage',array['tonnerre','éclair','pluie','ciel','tempête'],'Général');
insert into public.cards(id,word,forbidden,category) values (212,'Orage en peluche',array['éclair','pluie','ciel','tempête','tonnerre'],'Général');
insert into public.cards(id,word,forbidden,category) values (213,'Orage au zoo',array['pluie','ciel','tempête','tonnerre','éclair'],'Général');
insert into public.cards(id,word,forbidden,category) values (214,'Orage en dessin animé',array['ciel','tempête','tonnerre','éclair','pluie'],'Général');
insert into public.cards(id,word,forbidden,category) values (215,'Orage dans un film',array['tempête','tonnerre','éclair','pluie','ciel'],'Général');
insert into public.cards(id,word,forbidden,category) values (216,'Soleil',array['été','ciel','chaud','lumière','rayons'],'Général');
insert into public.cards(id,word,forbidden,category) values (217,'Soleil en peluche',array['ciel','chaud','lumière','rayons','été'],'Général');
insert into public.cards(id,word,forbidden,category) values (218,'Soleil au zoo',array['chaud','lumière','rayons','été','ciel'],'Général');
insert into public.cards(id,word,forbidden,category) values (219,'Soleil en dessin animé',array['lumière','rayons','été','ciel','chaud'],'Général');
insert into public.cards(id,word,forbidden,category) values (220,'Soleil dans un film',array['rayons','été','ciel','chaud','lumière'],'Général');
insert into public.cards(id,word,forbidden,category) values (221,'Lune',array['nuit','ciel','étoile','satellite','croissant'],'Général');
insert into public.cards(id,word,forbidden,category) values (222,'Lune en peluche',array['ciel','étoile','satellite','croissant','nuit'],'Général');
insert into public.cards(id,word,forbidden,category) values (223,'Lune au zoo',array['étoile','satellite','croissant','nuit','ciel'],'Général');
insert into public.cards(id,word,forbidden,category) values (224,'Lune en dessin animé',array['satellite','croissant','nuit','ciel','étoile'],'Général');
insert into public.cards(id,word,forbidden,category) values (225,'Lune dans un film',array['croissant','nuit','ciel','étoile','satellite'],'Général');
insert into public.cards(id,word,forbidden,category) values (226,'Étoile',array['ciel','nuit','lumière','espace','astre'],'Général');
insert into public.cards(id,word,forbidden,category) values (227,'Étoile en peluche',array['nuit','lumière','espace','astre','ciel'],'Général');
insert into public.cards(id,word,forbidden,category) values (228,'Étoile au zoo',array['lumière','espace','astre','ciel','nuit'],'Général');
insert into public.cards(id,word,forbidden,category) values (229,'Étoile en dessin animé',array['espace','astre','ciel','nuit','lumière'],'Général');
insert into public.cards(id,word,forbidden,category) values (230,'Étoile dans un film',array['astre','ciel','nuit','lumière','espace'],'Général');
insert into public.cards(id,word,forbidden,category) values (231,'Planète',array['Terre','espace','Mars','orbite','astronaute'],'Général');
insert into public.cards(id,word,forbidden,category) values (232,'Planète en peluche',array['espace','Mars','orbite','astronaute','Terre'],'Général');
insert into public.cards(id,word,forbidden,category) values (233,'Planète au zoo',array['Mars','orbite','astronaute','Terre','espace'],'Général');
insert into public.cards(id,word,forbidden,category) values (234,'Planète en dessin animé',array['orbite','astronaute','Terre','espace','Mars'],'Général');
insert into public.cards(id,word,forbidden,category) values (235,'Planète dans un film',array['astronaute','Terre','espace','Mars','orbite'],'Général');
insert into public.cards(id,word,forbidden,category) values (236,'Astronaute',array['espace','fusée','NASA','lune','combinaison'],'Général');
insert into public.cards(id,word,forbidden,category) values (237,'Astronaute en peluche',array['fusée','NASA','lune','combinaison','espace'],'Général');
insert into public.cards(id,word,forbidden,category) values (238,'Astronaute au zoo',array['NASA','lune','combinaison','espace','fusée'],'Général');
insert into public.cards(id,word,forbidden,category) values (239,'Astronaute en dessin animé',array['lune','combinaison','espace','fusée','NASA'],'Général');
insert into public.cards(id,word,forbidden,category) values (240,'Astronaute dans un film',array['combinaison','espace','fusée','NASA','lune'],'Général');
insert into public.cards(id,word,forbidden,category) values (241,'Fusée',array['espace','décollage','astronaute','NASA','propulsion'],'Général');
insert into public.cards(id,word,forbidden,category) values (242,'Fusée en peluche',array['décollage','astronaute','NASA','propulsion','espace'],'Général');
insert into public.cards(id,word,forbidden,category) values (243,'Fusée au zoo',array['astronaute','NASA','propulsion','espace','décollage'],'Général');
insert into public.cards(id,word,forbidden,category) values (244,'Fusée en dessin animé',array['NASA','propulsion','espace','décollage','astronaute'],'Général');
insert into public.cards(id,word,forbidden,category) values (245,'Fusée dans un film',array['propulsion','espace','décollage','astronaute','NASA'],'Général');
insert into public.cards(id,word,forbidden,category) values (246,'Robot',array['machine','automatique','IA','métal','humain'],'Général');
insert into public.cards(id,word,forbidden,category) values (247,'Robot en peluche',array['automatique','IA','métal','humain','machine'],'Général');
insert into public.cards(id,word,forbidden,category) values (248,'Robot au zoo',array['IA','métal','humain','machine','automatique'],'Général');
insert into public.cards(id,word,forbidden,category) values (249,'Robot en dessin animé',array['métal','humain','machine','automatique','IA'],'Général');
insert into public.cards(id,word,forbidden,category) values (250,'Robot dans un film',array['humain','machine','automatique','IA','métal'],'Général');
insert into public.cards(id,word,forbidden,category) values (251,'Internet',array['web','réseau','ordinateur','site','connexion'],'Général');
insert into public.cards(id,word,forbidden,category) values (252,'Internet en peluche',array['réseau','ordinateur','site','connexion','web'],'Général');
insert into public.cards(id,word,forbidden,category) values (253,'Internet au zoo',array['ordinateur','site','connexion','web','réseau'],'Général');
insert into public.cards(id,word,forbidden,category) values (254,'Internet en dessin animé',array['site','connexion','web','réseau','ordinateur'],'Général');
insert into public.cards(id,word,forbidden,category) values (255,'Internet dans un film',array['connexion','web','réseau','ordinateur','site'],'Général');
insert into public.cards(id,word,forbidden,category) values (256,'Instagram',array['réseau','photo','stories','likes','application'],'Général');
insert into public.cards(id,word,forbidden,category) values (257,'Instagram en peluche',array['photo','stories','likes','application','réseau'],'Général');
insert into public.cards(id,word,forbidden,category) values (258,'Instagram au zoo',array['stories','likes','application','réseau','photo'],'Général');
insert into public.cards(id,word,forbidden,category) values (259,'Instagram en dessin animé',array['likes','application','réseau','photo','stories'],'Général');
insert into public.cards(id,word,forbidden,category) values (260,'Instagram dans un film',array['application','réseau','photo','stories','likes'],'Général');
insert into public.cards(id,word,forbidden,category) values (261,'YouTube',array['vidéo','chaîne','abonnés','streaming','créateur'],'Général');
insert into public.cards(id,word,forbidden,category) values (262,'YouTube en peluche',array['chaîne','abonnés','streaming','créateur','vidéo'],'Général');
insert into public.cards(id,word,forbidden,category) values (263,'YouTube au zoo',array['abonnés','streaming','créateur','vidéo','chaîne'],'Général');
insert into public.cards(id,word,forbidden,category) values (264,'YouTube en dessin animé',array['streaming','créateur','vidéo','chaîne','abonnés'],'Général');
insert into public.cards(id,word,forbidden,category) values (265,'YouTube dans un film',array['créateur','vidéo','chaîne','abonnés','streaming'],'Général');
insert into public.cards(id,word,forbidden,category) values (266,'TikTok',array['vidéo','danse','réseau','application','vertical'],'Général');
insert into public.cards(id,word,forbidden,category) values (267,'TikTok en peluche',array['danse','réseau','application','vertical','vidéo'],'Général');
insert into public.cards(id,word,forbidden,category) values (268,'TikTok au zoo',array['réseau','application','vertical','vidéo','danse'],'Général');
insert into public.cards(id,word,forbidden,category) values (269,'TikTok en dessin animé',array['application','vertical','vidéo','danse','réseau'],'Général');
insert into public.cards(id,word,forbidden,category) values (270,'TikTok dans un film',array['vertical','vidéo','danse','réseau','application'],'Général');
insert into public.cards(id,word,forbidden,category) values (271,'Snapchat',array['photo','stories','filtre','message','fantôme'],'Général');
insert into public.cards(id,word,forbidden,category) values (272,'Snapchat en peluche',array['stories','filtre','message','fantôme','photo'],'Général');
insert into public.cards(id,word,forbidden,category) values (273,'Snapchat au zoo',array['filtre','message','fantôme','photo','stories'],'Général');
insert into public.cards(id,word,forbidden,category) values (274,'Snapchat en dessin animé',array['message','fantôme','photo','stories','filtre'],'Général');
insert into public.cards(id,word,forbidden,category) values (275,'Snapchat dans un film',array['fantôme','photo','stories','filtre','message'],'Général');
insert into public.cards(id,word,forbidden,category) values (276,'Musique',array['son','chanson','écouter','artiste','instrument'],'Général');
insert into public.cards(id,word,forbidden,category) values (277,'Musique en peluche',array['chanson','écouter','artiste','instrument','son'],'Général');
insert into public.cards(id,word,forbidden,category) values (278,'Musique au zoo',array['écouter','artiste','instrument','son','chanson'],'Général');
insert into public.cards(id,word,forbidden,category) values (279,'Musique en dessin animé',array['artiste','instrument','son','chanson','écouter'],'Général');
insert into public.cards(id,word,forbidden,category) values (280,'Musique dans un film',array['instrument','son','chanson','écouter','artiste'],'Général');
insert into public.cards(id,word,forbidden,category) values (281,'Chanson',array['musique','paroles','couplet','refrain','chanter'],'Général');
insert into public.cards(id,word,forbidden,category) values (282,'Chanson en peluche',array['paroles','couplet','refrain','chanter','musique'],'Général');
insert into public.cards(id,word,forbidden,category) values (283,'Chanson au zoo',array['couplet','refrain','chanter','musique','paroles'],'Général');
insert into public.cards(id,word,forbidden,category) values (284,'Chanson en dessin animé',array['refrain','chanter','musique','paroles','couplet'],'Général');
insert into public.cards(id,word,forbidden,category) values (285,'Chanson dans un film',array['chanter','musique','paroles','couplet','refrain'],'Général');
insert into public.cards(id,word,forbidden,category) values (286,'DJ',array['musique','platines','soirée','mix','club'],'Général');
insert into public.cards(id,word,forbidden,category) values (287,'DJ en peluche',array['platines','soirée','mix','club','musique'],'Général');
insert into public.cards(id,word,forbidden,category) values (288,'DJ au zoo',array['soirée','mix','club','musique','platines'],'Général');
insert into public.cards(id,word,forbidden,category) values (289,'DJ en dessin animé',array['mix','club','musique','platines','soirée'],'Général');
insert into public.cards(id,word,forbidden,category) values (290,'DJ dans un film',array['club','musique','platines','soirée','mix'],'Général');
insert into public.cards(id,word,forbidden,category) values (291,'Danse',array['musique','bouger','corps','chorégraphie','piste'],'Général');
insert into public.cards(id,word,forbidden,category) values (292,'Danse en peluche',array['bouger','corps','chorégraphie','piste','musique'],'Général');
insert into public.cards(id,word,forbidden,category) values (293,'Danse au zoo',array['corps','chorégraphie','piste','musique','bouger'],'Général');
insert into public.cards(id,word,forbidden,category) values (294,'Danse en dessin animé',array['chorégraphie','piste','musique','bouger','corps'],'Général');
insert into public.cards(id,word,forbidden,category) values (295,'Danse dans un film',array['piste','musique','bouger','corps','chorégraphie'],'Général');
insert into public.cards(id,word,forbidden,category) values (296,'Concert',array['musique','public','scène','artiste','billet'],'Général');
insert into public.cards(id,word,forbidden,category) values (297,'Concert en peluche',array['public','scène','artiste','billet','musique'],'Général');
insert into public.cards(id,word,forbidden,category) values (298,'Concert au zoo',array['scène','artiste','billet','musique','public'],'Général');
insert into public.cards(id,word,forbidden,category) values (299,'Concert en dessin animé',array['artiste','billet','musique','public','scène'],'Général');
insert into public.cards(id,word,forbidden,category) values (300,'Concert dans un film',array['billet','musique','public','scène','artiste'],'Général');
insert into public.cards(id,word,forbidden,category) values (301,'Batterie',array['instrument','rythme','tambours','musique','baguettes'],'Général');
insert into public.cards(id,word,forbidden,category) values (302,'Batterie en peluche',array['rythme','tambours','musique','baguettes','instrument'],'Général');
insert into public.cards(id,word,forbidden,category) values (303,'Batterie au zoo',array['tambours','musique','baguettes','instrument','rythme'],'Général');
insert into public.cards(id,word,forbidden,category) values (304,'Batterie en dessin animé',array['musique','baguettes','instrument','rythme','tambours'],'Général');
insert into public.cards(id,word,forbidden,category) values (305,'Batterie dans un film',array['baguettes','instrument','rythme','tambours','musique'],'Général');
insert into public.cards(id,word,forbidden,category) values (306,'Piano',array['instrument','touches','musique','clavier','concert'],'Général');
insert into public.cards(id,word,forbidden,category) values (307,'Piano en peluche',array['touches','musique','clavier','concert','instrument'],'Général');
insert into public.cards(id,word,forbidden,category) values (308,'Piano au zoo',array['musique','clavier','concert','instrument','touches'],'Général');
insert into public.cards(id,word,forbidden,category) values (309,'Piano en dessin animé',array['clavier','concert','instrument','touches','musique'],'Général');
insert into public.cards(id,word,forbidden,category) values (310,'Piano dans un film',array['concert','instrument','touches','musique','clavier'],'Général');
insert into public.cards(id,word,forbidden,category) values (311,'Guitare électrique',array['instrument','cordes','ampli','rock','musique'],'Général');
insert into public.cards(id,word,forbidden,category) values (312,'Guitare électrique en peluche',array['cordes','ampli','rock','musique','instrument'],'Général');
insert into public.cards(id,word,forbidden,category) values (313,'Guitare électrique au zoo',array['ampli','rock','musique','instrument','cordes'],'Général');
insert into public.cards(id,word,forbidden,category) values (314,'Guitare électrique en dessin animé',array['rock','musique','instrument','cordes','ampli'],'Général');
insert into public.cards(id,word,forbidden,category) values (315,'Guitare électrique dans un film',array['musique','instrument','cordes','ampli','rock'],'Général');
insert into public.cards(id,word,forbidden,category) values (316,'Basketball',array['sport','panier','ballon','NBA','terrain'],'Général');
insert into public.cards(id,word,forbidden,category) values (317,'Basketball en peluche',array['panier','ballon','NBA','terrain','sport'],'Général');
insert into public.cards(id,word,forbidden,category) values (318,'Basketball au zoo',array['ballon','NBA','terrain','sport','panier'],'Général');
insert into public.cards(id,word,forbidden,category) values (319,'Basketball en dessin animé',array['NBA','terrain','sport','panier','ballon'],'Général');
insert into public.cards(id,word,forbidden,category) values (320,'Basketball dans un film',array['terrain','sport','panier','ballon','NBA'],'Général');
insert into public.cards(id,word,forbidden,category) values (321,'Tennis',array['sport','raquette','balle','court','match'],'Général');
insert into public.cards(id,word,forbidden,category) values (322,'Tennis en peluche',array['raquette','balle','court','match','sport'],'Général');
insert into public.cards(id,word,forbidden,category) values (323,'Tennis au zoo',array['balle','court','match','sport','raquette'],'Général');
insert into public.cards(id,word,forbidden,category) values (324,'Tennis en dessin animé',array['court','match','sport','raquette','balle'],'Général');
insert into public.cards(id,word,forbidden,category) values (325,'Tennis dans un film',array['match','sport','raquette','balle','court'],'Général');
insert into public.cards(id,word,forbidden,category) values (326,'Rugby',array['sport','ballon','essai','équipe','terrain'],'Général');
insert into public.cards(id,word,forbidden,category) values (327,'Rugby en peluche',array['ballon','essai','équipe','terrain','sport'],'Général');
insert into public.cards(id,word,forbidden,category) values (328,'Rugby au zoo',array['essai','équipe','terrain','sport','ballon'],'Général');
insert into public.cards(id,word,forbidden,category) values (329,'Rugby en dessin animé',array['équipe','terrain','sport','ballon','essai'],'Général');
insert into public.cards(id,word,forbidden,category) values (330,'Rugby dans un film',array['terrain','sport','ballon','essai','équipe'],'Général');
insert into public.cards(id,word,forbidden,category) values (331,'Natation',array['sport','piscine','nager','eau','crawl'],'Général');
insert into public.cards(id,word,forbidden,category) values (332,'Natation en peluche',array['piscine','nager','eau','crawl','sport'],'Général');
insert into public.cards(id,word,forbidden,category) values (333,'Natation au zoo',array['nager','eau','crawl','sport','piscine'],'Général');
insert into public.cards(id,word,forbidden,category) values (334,'Natation en dessin animé',array['eau','crawl','sport','piscine','nager'],'Général');
insert into public.cards(id,word,forbidden,category) values (335,'Natation dans un film',array['crawl','sport','piscine','nager','eau'],'Général');
insert into public.cards(id,word,forbidden,category) values (336,'Course',array['sport','courir','marathon','jambes','chrono'],'Général');
insert into public.cards(id,word,forbidden,category) values (337,'Course en peluche',array['courir','marathon','jambes','chrono','sport'],'Général');
insert into public.cards(id,word,forbidden,category) values (338,'Course au zoo',array['marathon','jambes','chrono','sport','courir'],'Général');
insert into public.cards(id,word,forbidden,category) values (339,'Course en dessin animé',array['jambes','chrono','sport','courir','marathon'],'Général');
insert into public.cards(id,word,forbidden,category) values (340,'Course dans un film',array['chrono','sport','courir','marathon','jambes'],'Général');
insert into public.cards(id,word,forbidden,category) values (341,'Boxe',array['sport','gants','ring','combat','coup'],'Général');
insert into public.cards(id,word,forbidden,category) values (342,'Boxe en peluche',array['gants','ring','combat','coup','sport'],'Général');
insert into public.cards(id,word,forbidden,category) values (343,'Boxe au zoo',array['ring','combat','coup','sport','gants'],'Général');
insert into public.cards(id,word,forbidden,category) values (344,'Boxe en dessin animé',array['combat','coup','sport','gants','ring'],'Général');
insert into public.cards(id,word,forbidden,category) values (345,'Boxe dans un film',array['coup','sport','gants','ring','combat'],'Général');
insert into public.cards(id,word,forbidden,category) values (346,'Cyclisme',array['vélo','sport','course','pédale','casque'],'Général');
insert into public.cards(id,word,forbidden,category) values (347,'Cyclisme en peluche',array['sport','course','pédale','casque','vélo'],'Général');
insert into public.cards(id,word,forbidden,category) values (348,'Cyclisme au zoo',array['course','pédale','casque','vélo','sport'],'Général');
insert into public.cards(id,word,forbidden,category) values (349,'Cyclisme en dessin animé',array['pédale','casque','vélo','sport','course'],'Général');
insert into public.cards(id,word,forbidden,category) values (350,'Cyclisme dans un film',array['casque','vélo','sport','course','pédale'],'Général');
insert into public.cards(id,word,forbidden,category) values (351,'Ski',array['neige','montagne','pistes','hiver','glisse'],'Général');
insert into public.cards(id,word,forbidden,category) values (352,'Ski en peluche',array['montagne','pistes','hiver','glisse','neige'],'Général');
insert into public.cards(id,word,forbidden,category) values (353,'Ski au zoo',array['pistes','hiver','glisse','neige','montagne'],'Général');
insert into public.cards(id,word,forbidden,category) values (354,'Ski en dessin animé',array['hiver','glisse','neige','montagne','pistes'],'Général');
insert into public.cards(id,word,forbidden,category) values (355,'Ski dans un film',array['glisse','neige','montagne','pistes','hiver'],'Général');
insert into public.cards(id,word,forbidden,category) values (356,'Surf',array['vague','planche','mer','plage','océan'],'Général');
insert into public.cards(id,word,forbidden,category) values (357,'Surf en peluche',array['planche','mer','plage','océan','vague'],'Général');
insert into public.cards(id,word,forbidden,category) values (358,'Surf au zoo',array['mer','plage','océan','vague','planche'],'Général');
insert into public.cards(id,word,forbidden,category) values (359,'Surf en dessin animé',array['plage','océan','vague','planche','mer'],'Général');
insert into public.cards(id,word,forbidden,category) values (360,'Surf dans un film',array['océan','vague','planche','mer','plage'],'Général');
insert into public.cards(id,word,forbidden,category) values (361,'Paddle',array['raquette','balle','court','tennis','sport'],'Général');
insert into public.cards(id,word,forbidden,category) values (362,'Paddle en peluche',array['balle','court','tennis','sport','raquette'],'Général');
insert into public.cards(id,word,forbidden,category) values (363,'Paddle au zoo',array['court','tennis','sport','raquette','balle'],'Général');
insert into public.cards(id,word,forbidden,category) values (364,'Paddle en dessin animé',array['tennis','sport','raquette','balle','court'],'Général');
insert into public.cards(id,word,forbidden,category) values (365,'Paddle dans un film',array['sport','raquette','balle','court','tennis'],'Général');
insert into public.cards(id,word,forbidden,category) values (366,'Livre',array['lecture','pages','roman','auteur','bibliothèque'],'Général');
insert into public.cards(id,word,forbidden,category) values (367,'Livre en peluche',array['pages','roman','auteur','bibliothèque','lecture'],'Général');
insert into public.cards(id,word,forbidden,category) values (368,'Livre au zoo',array['roman','auteur','bibliothèque','lecture','pages'],'Général');
insert into public.cards(id,word,forbidden,category) values (369,'Livre en dessin animé',array['auteur','bibliothèque','lecture','pages','roman'],'Général');
insert into public.cards(id,word,forbidden,category) values (370,'Livre dans un film',array['bibliothèque','lecture','pages','roman','auteur'],'Général');
insert into public.cards(id,word,forbidden,category) values (371,'Journal',array['actualité','papier','article','presse','quotidien'],'Général');
insert into public.cards(id,word,forbidden,category) values (372,'Journal en peluche',array['papier','article','presse','quotidien','actualité'],'Général');
insert into public.cards(id,word,forbidden,category) values (373,'Journal au zoo',array['article','presse','quotidien','actualité','papier'],'Général');
insert into public.cards(id,word,forbidden,category) values (374,'Journal en dessin animé',array['presse','quotidien','actualité','papier','article'],'Général');
insert into public.cards(id,word,forbidden,category) values (375,'Journal dans un film',array['quotidien','actualité','papier','article','presse'],'Général');
insert into public.cards(id,word,forbidden,category) values (376,'Télévision',array['écran','chaîne','regarder','programme','télécommande'],'Général');
insert into public.cards(id,word,forbidden,category) values (377,'Télévision en peluche',array['chaîne','regarder','programme','télécommande','écran'],'Général');
insert into public.cards(id,word,forbidden,category) values (378,'Télévision au zoo',array['regarder','programme','télécommande','écran','chaîne'],'Général');
insert into public.cards(id,word,forbidden,category) values (379,'Télévision en dessin animé',array['programme','télécommande','écran','chaîne','regarder'],'Général');
insert into public.cards(id,word,forbidden,category) values (380,'Télévision dans un film',array['télécommande','écran','chaîne','regarder','programme'],'Général');
insert into public.cards(id,word,forbidden,category) values (381,'Radio',array['son','station','animateur','FM','écouter'],'Général');
insert into public.cards(id,word,forbidden,category) values (382,'Radio en peluche',array['station','animateur','FM','écouter','son'],'Général');
insert into public.cards(id,word,forbidden,category) values (383,'Radio au zoo',array['animateur','FM','écouter','son','station'],'Général');
insert into public.cards(id,word,forbidden,category) values (384,'Radio en dessin animé',array['FM','écouter','son','station','animateur'],'Général');
insert into public.cards(id,word,forbidden,category) values (385,'Radio dans un film',array['écouter','son','station','animateur','FM'],'Général');
insert into public.cards(id,word,forbidden,category) values (386,'Appareil photo',array['objectif','image','caméra','photographe','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (387,'Appareil photo en peluche',array['objectif','image','caméra','photographe','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (388,'Appareil photo au zoo',array['image','caméra','photographe','objectif','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (389,'Appareil photo en dessin animé',array['caméra','photographe','objectif','image','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (390,'Appareil photo dans un film',array['photographe','objectif','image','caméra','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (391,'Caméra',array['film','vidéo','objectif','tournage','cinéma'],'Général');
insert into public.cards(id,word,forbidden,category) values (392,'Caméra en peluche',array['vidéo','objectif','tournage','cinéma','film'],'Général');
insert into public.cards(id,word,forbidden,category) values (393,'Caméra au zoo',array['objectif','tournage','cinéma','film','vidéo'],'Général');
insert into public.cards(id,word,forbidden,category) values (394,'Caméra en dessin animé',array['tournage','cinéma','film','vidéo','objectif'],'Général');
insert into public.cards(id,word,forbidden,category) values (395,'Caméra dans un film',array['cinéma','vidéo','objectif','tournage','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (396,'Clé',array['porte','serrure','ouvrir','maison','trousseau'],'Général');
insert into public.cards(id,word,forbidden,category) values (397,'Clé en peluche',array['serrure','ouvrir','maison','trousseau','porte'],'Général');
insert into public.cards(id,word,forbidden,category) values (398,'Clé au zoo',array['ouvrir','maison','trousseau','porte','serrure'],'Général');
insert into public.cards(id,word,forbidden,category) values (399,'Clé en dessin animé',array['maison','trousseau','porte','serrure','ouvrir'],'Général');
insert into public.cards(id,word,forbidden,category) values (400,'Clé dans un film',array['trousseau','porte','serrure','ouvrir','maison'],'Général');
insert into public.cards(id,word,forbidden,category) values (401,'Maison',array['habiter','pièce','toit','famille','domicile'],'Général');
insert into public.cards(id,word,forbidden,category) values (402,'Maison en peluche',array['pièce','toit','famille','domicile','habiter'],'Général');
insert into public.cards(id,word,forbidden,category) values (403,'Maison au zoo',array['toit','famille','domicile','habiter','pièce'],'Général');
insert into public.cards(id,word,forbidden,category) values (404,'Maison en dessin animé',array['famille','domicile','habiter','pièce','toit'],'Général');
insert into public.cards(id,word,forbidden,category) values (405,'Maison dans un film',array['domicile','habiter','pièce','toit','famille'],'Général');
insert into public.cards(id,word,forbidden,category) values (406,'Appartement',array['logement','immeuble','pièce','locataire','loyer'],'Général');
insert into public.cards(id,word,forbidden,category) values (407,'Appartement en peluche',array['immeuble','pièce','locataire','loyer','logement'],'Général');
insert into public.cards(id,word,forbidden,category) values (408,'Appartement au zoo',array['pièce','locataire','loyer','logement','immeuble'],'Général');
insert into public.cards(id,word,forbidden,category) values (409,'Appartement en dessin animé',array['locataire','loyer','logement','immeuble','pièce'],'Général');
insert into public.cards(id,word,forbidden,category) values (410,'Appartement dans un film',array['loyer','logement','immeuble','pièce','locataire'],'Général');
insert into public.cards(id,word,forbidden,category) values (411,'Cuisine',array['repas','four','frigo','cuisiner','plats'],'Général');
insert into public.cards(id,word,forbidden,category) values (412,'Cuisine en peluche',array['four','frigo','cuisiner','plats','repas'],'Général');
insert into public.cards(id,word,forbidden,category) values (413,'Cuisine au zoo',array['frigo','cuisiner','plats','repas','four'],'Général');
insert into public.cards(id,word,forbidden,category) values (414,'Cuisine en dessin animé',array['cuisiner','plats','repas','four','frigo'],'Général');
insert into public.cards(id,word,forbidden,category) values (415,'Cuisine dans un film',array['plats','repas','four','frigo','cuisiner'],'Général');
insert into public.cards(id,word,forbidden,category) values (416,'Frigo',array['froid','cuisine','nourriture','glace','réfrigérateur'],'Général');
insert into public.cards(id,word,forbidden,category) values (417,'Frigo en peluche',array['cuisine','nourriture','glace','réfrigérateur','froid'],'Général');
insert into public.cards(id,word,forbidden,category) values (418,'Frigo au zoo',array['nourriture','glace','réfrigérateur','froid','cuisine'],'Général');
insert into public.cards(id,word,forbidden,category) values (419,'Frigo en dessin animé',array['glace','réfrigérateur','froid','cuisine','nourriture'],'Général');
insert into public.cards(id,word,forbidden,category) values (420,'Frigo dans un film',array['réfrigérateur','froid','cuisine','nourriture','glace'],'Général');
insert into public.cards(id,word,forbidden,category) values (421,'Four',array['cuisine','cuire','chaleur','pizza','gâteau'],'Général');
insert into public.cards(id,word,forbidden,category) values (422,'Four en peluche',array['cuire','chaleur','pizza','gâteau','cuisine'],'Général');
insert into public.cards(id,word,forbidden,category) values (423,'Four au zoo',array['chaleur','pizza','gâteau','cuisine','cuire'],'Général');
insert into public.cards(id,word,forbidden,category) values (424,'Four en dessin animé',array['pizza','gâteau','cuisine','cuire','chaleur'],'Général');
insert into public.cards(id,word,forbidden,category) values (425,'Four dans un film',array['gâteau','cuisine','cuire','chaleur','pizza'],'Général');
insert into public.cards(id,word,forbidden,category) values (426,'Lit',array['dormir','chambre','matelas','oreiller','nuit'],'Général');
insert into public.cards(id,word,forbidden,category) values (427,'Lit en peluche',array['chambre','matelas','oreiller','nuit','dormir'],'Général');
insert into public.cards(id,word,forbidden,category) values (428,'Lit au zoo',array['matelas','oreiller','nuit','dormir','chambre'],'Général');
insert into public.cards(id,word,forbidden,category) values (429,'Lit en dessin animé',array['oreiller','nuit','dormir','chambre','matelas'],'Général');
insert into public.cards(id,word,forbidden,category) values (430,'Lit dans un film',array['nuit','dormir','chambre','matelas','oreiller'],'Général');
insert into public.cards(id,word,forbidden,category) values (431,'Canapé',array['salon','s''asseoir','coussin','meuble','télévision'],'Général');
insert into public.cards(id,word,forbidden,category) values (432,'Canapé en peluche',array['s''asseoir','coussin','meuble','télévision','salon'],'Général');
insert into public.cards(id,word,forbidden,category) values (433,'Canapé au zoo',array['coussin','meuble','télévision','salon','s''asseoir'],'Général');
insert into public.cards(id,word,forbidden,category) values (434,'Canapé en dessin animé',array['meuble','télévision','salon','s''asseoir','coussin'],'Général');
insert into public.cards(id,word,forbidden,category) values (435,'Canapé dans un film',array['télévision','salon','s''asseoir','coussin','meuble'],'Général');
insert into public.cards(id,word,forbidden,category) values (436,'Table',array['manger','chaise','meuble','repas','surface'],'Général');
insert into public.cards(id,word,forbidden,category) values (437,'Table en peluche',array['chaise','meuble','repas','surface','manger'],'Général');
insert into public.cards(id,word,forbidden,category) values (438,'Table au zoo',array['meuble','repas','surface','manger','chaise'],'Général');
insert into public.cards(id,word,forbidden,category) values (439,'Table en dessin animé',array['repas','surface','manger','chaise','meuble'],'Général');
insert into public.cards(id,word,forbidden,category) values (440,'Table dans un film',array['surface','manger','chaise','meuble','repas'],'Général');
insert into public.cards(id,word,forbidden,category) values (441,'Chaise',array['s''asseoir','table','meuble','dos','siège'],'Général');
insert into public.cards(id,word,forbidden,category) values (442,'Chaise en peluche',array['table','meuble','dos','siège','s''asseoir'],'Général');
insert into public.cards(id,word,forbidden,category) values (443,'Chaise au zoo',array['meuble','dos','siège','s''asseoir','table'],'Général');
insert into public.cards(id,word,forbidden,category) values (444,'Chaise en dessin animé',array['dos','siège','s''asseoir','table','meuble'],'Général');
insert into public.cards(id,word,forbidden,category) values (445,'Chaise dans un film',array['siège','s''asseoir','table','meuble','dos'],'Général');
insert into public.cards(id,word,forbidden,category) values (446,'Lampe',array['lumière','éclairage','ampoule','table','interrupteur'],'Général');
insert into public.cards(id,word,forbidden,category) values (447,'Lampe en peluche',array['éclairage','ampoule','table','interrupteur','lumière'],'Général');
insert into public.cards(id,word,forbidden,category) values (448,'Lampe au zoo',array['ampoule','table','interrupteur','lumière','éclairage'],'Général');
insert into public.cards(id,word,forbidden,category) values (449,'Lampe en dessin animé',array['table','interrupteur','lumière','éclairage','ampoule'],'Général');
insert into public.cards(id,word,forbidden,category) values (450,'Lampe dans un film',array['interrupteur','lumière','éclairage','ampoule','table'],'Général');
insert into public.cards(id,word,forbidden,category) values (451,'Miroir',array['reflet','glace','visage','salle de bain','regarder'],'Général');
insert into public.cards(id,word,forbidden,category) values (452,'Miroir en peluche',array['glace','visage','salle de bain','regarder','reflet'],'Général');
insert into public.cards(id,word,forbidden,category) values (453,'Miroir au zoo',array['visage','salle de bain','regarder','reflet','glace'],'Général');
insert into public.cards(id,word,forbidden,category) values (454,'Miroir en dessin animé',array['salle de bain','regarder','reflet','glace','visage'],'Général');
insert into public.cards(id,word,forbidden,category) values (455,'Miroir dans un film',array['regarder','reflet','glace','visage','salle de bain'],'Général');
insert into public.cards(id,word,forbidden,category) values (456,'Savon',array['douche','lavage','mains','mousse','hygiène'],'Général');
insert into public.cards(id,word,forbidden,category) values (457,'Savon en peluche',array['lavage','mains','mousse','hygiène','douche'],'Général');
insert into public.cards(id,word,forbidden,category) values (458,'Savon au zoo',array['mains','mousse','hygiène','douche','lavage'],'Général');
insert into public.cards(id,word,forbidden,category) values (459,'Savon en dessin animé',array['mousse','hygiène','douche','lavage','mains'],'Général');
insert into public.cards(id,word,forbidden,category) values (460,'Savon dans un film',array['hygiène','douche','lavage','mains','mousse'],'Général');
insert into public.cards(id,word,forbidden,category) values (461,'Brosse à dents',array['dentifrice','bouche','matin','lavage','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (462,'Brosse à dents en peluche',array['dentifrice','bouche','matin','lavage','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (463,'Brosse à dents au zoo',array['bouche','matin','lavage','dentifrice','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (464,'Brosse à dents en dessin animé',array['matin','lavage','dentifrice','bouche','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (465,'Brosse à dents dans un film',array['lavage','dentifrice','bouche','matin','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (466,'Shampoing',array['cheveux','douche','lavage','bouteille','salle de bain'],'Général');
insert into public.cards(id,word,forbidden,category) values (467,'Shampoing en peluche',array['douche','lavage','bouteille','salle de bain','cheveux'],'Général');
insert into public.cards(id,word,forbidden,category) values (468,'Shampoing au zoo',array['lavage','bouteille','salle de bain','cheveux','douche'],'Général');
insert into public.cards(id,word,forbidden,category) values (469,'Shampoing en dessin animé',array['bouteille','salle de bain','cheveux','douche','lavage'],'Général');
insert into public.cards(id,word,forbidden,category) values (470,'Shampoing dans un film',array['salle de bain','cheveux','douche','lavage','bouteille'],'Général');
insert into public.cards(id,word,forbidden,category) values (471,'Parfum',array['odeur','flacon','sentir','cosmétique','fragrance'],'Général');
insert into public.cards(id,word,forbidden,category) values (472,'Parfum en peluche',array['flacon','sentir','cosmétique','fragrance','odeur'],'Général');
insert into public.cards(id,word,forbidden,category) values (473,'Parfum au zoo',array['sentir','cosmétique','fragrance','odeur','flacon'],'Général');
insert into public.cards(id,word,forbidden,category) values (474,'Parfum en dessin animé',array['cosmétique','fragrance','odeur','flacon','sentir'],'Général');
insert into public.cards(id,word,forbidden,category) values (475,'Parfum dans un film',array['fragrance','odeur','flacon','sentir','cosmétique'],'Général');
insert into public.cards(id,word,forbidden,category) values (476,'Médecin',array['docteur','patient','hôpital','soigner','cabinet'],'Général');
insert into public.cards(id,word,forbidden,category) values (477,'Médecin en peluche',array['patient','hôpital','soigner','cabinet','docteur'],'Général');
insert into public.cards(id,word,forbidden,category) values (478,'Médecin au zoo',array['hôpital','soigner','cabinet','docteur','patient'],'Général');
insert into public.cards(id,word,forbidden,category) values (479,'Médecin en dessin animé',array['soigner','cabinet','docteur','patient','hôpital'],'Général');
insert into public.cards(id,word,forbidden,category) values (480,'Médecin dans un film',array['cabinet','docteur','patient','hôpital','soigner'],'Général');
insert into public.cards(id,word,forbidden,category) values (481,'Dentiste',array['cabinet','soin','bouche','carie','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (482,'Dentiste en peluche',array['cabinet','soin','bouche','carie','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (483,'Dentiste au zoo',array['soin','bouche','carie','cabinet','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (484,'Dentiste en dessin animé',array['bouche','carie','cabinet','soin','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (485,'Dentiste dans un film',array['carie','cabinet','soin','bouche','jouet'],'Général');
insert into public.cards(id,word,forbidden,category) values (486,'Police',array['agent','uniforme','loi','voiture','commissariat'],'Général');
insert into public.cards(id,word,forbidden,category) values (487,'Police en peluche',array['uniforme','loi','voiture','commissariat','agent'],'Général');
insert into public.cards(id,word,forbidden,category) values (488,'Police au zoo',array['loi','voiture','commissariat','agent','uniforme'],'Général');
insert into public.cards(id,word,forbidden,category) values (489,'Police en dessin animé',array['voiture','commissariat','agent','uniforme','loi'],'Général');
insert into public.cards(id,word,forbidden,category) values (490,'Police dans un film',array['commissariat','agent','uniforme','loi','voiture'],'Général');
insert into public.cards(id,word,forbidden,category) values (491,'Pompier',array['feu','caserne','incendie','camion','secours'],'Général');
insert into public.cards(id,word,forbidden,category) values (492,'Pompier en peluche',array['caserne','incendie','camion','secours','feu'],'Général');
insert into public.cards(id,word,forbidden,category) values (493,'Pompier au zoo',array['incendie','camion','secours','feu','caserne'],'Général');
insert into public.cards(id,word,forbidden,category) values (494,'Pompier en dessin animé',array['camion','secours','feu','caserne','incendie'],'Général');
insert into public.cards(id,word,forbidden,category) values (495,'Pompier dans un film',array['secours','feu','caserne','incendie','camion'],'Général');
insert into public.cards(id,word,forbidden,category) values (496,'Avocat',array['justice','tribunal','droit','client','procès'],'Général');
insert into public.cards(id,word,forbidden,category) values (497,'Avocat en peluche',array['tribunal','droit','client','procès','justice'],'Général');
insert into public.cards(id,word,forbidden,category) values (498,'Avocat au zoo',array['droit','client','procès','justice','tribunal'],'Général');
insert into public.cards(id,word,forbidden,category) values (499,'Avocat en dessin animé',array['client','procès','justice','tribunal','droit'],'Général');
insert into public.cards(id,word,forbidden,category) values (500,'Avocat dans un film',array['procès','justice','tribunal','droit','client'],'Général');


alter table public.rooms enable row level security;
alter table public.players enable row level security;
alter table public.cards enable row level security;

create policy cards_select on public.cards for select to authenticated using (true);
create policy rooms_select on public.rooms for select to authenticated using (exists (select 1 from public.players p where p.room_id=rooms.id and p.id=auth.uid()) or host_player_id=auth.uid());
create policy rooms_insert on public.rooms for insert to authenticated with check (host_player_id is null);
create policy rooms_update_member on public.rooms for update to authenticated using (exists (select 1 from public.players p where p.room_id=rooms.id and p.id=auth.uid())) with check (true);
create policy players_select on public.players for select to authenticated using (exists (select 1 from public.players me where me.room_id=players.room_id and me.id=auth.uid()) or id=auth.uid());
create policy players_insert on public.players for insert to authenticated with check (auth.uid()=id);
create policy players_update_self on public.players for update to authenticated using (auth.uid()=id) with check (auth.uid()=id);

alter publication supabase_realtime add table public.rooms;
alter publication supabase_realtime add table public.players;

-- Atomic room creation: creates the player first, then assigns host.
create or replace function public.create_room(p_code text, p_name text)
returns public.rooms
language plpgsql
security definer
set search_path=public
as $$
declare r public.rooms; uid uuid := auth.uid();
begin
 if uid is null then raise exception 'Not authenticated'; end if;
 insert into rooms(code) values (upper(p_code)) returning * into r;
 insert into players(id,room_id,name,team) values(uid,r.id,left(trim(p_name),24),'A');
 update rooms set host_player_id=uid where id=r.id returning * into r;
 return r;
end $$;

create or replace function public.join_room(p_code text,p_name text,p_team text)
returns public.players
language plpgsql
security definer
set search_path=public
as $$
declare r public.rooms; p public.players; uid uuid := auth.uid(); n integer;
begin
 if uid is null then raise exception 'Not authenticated'; end if;
 select * into r from rooms where code=upper(p_code) for update;
 if r.id is null then raise exception 'Room introuvable'; end if;
 if r.status <> 'lobby' then raise exception 'La partie a déjà commencé'; end if;
 select count(*) into n from players where room_id=r.id and team=upper(p_team);
 if n >= 4 then raise exception 'Cette équipe est complète'; end if;
 insert into players(id,room_id,name,team) values(uid,r.id,left(trim(p_name),24),upper(p_team))
 on conflict(id) do update set room_id=excluded.room_id,name=excluded.name,team=excluded.team,connected=true
 returning * into p;
 return p;
end $$;

create or replace function public.start_game(p_code text)
returns public.rooms
language plpgsql
security definer
set search_path=public
as $$
declare r public.rooms; a uuid; b uuid; cid integer; uid uuid := auth.uid();
begin
 select * into r from rooms where code=upper(p_code) for update;
 if r.id is null then raise exception 'Room introuvable'; end if;
 if r.host_player_id <> uid then raise exception 'Seul le créateur peut lancer la partie'; end if;
 if (select count(*) from players where room_id=r.id and team='A')=0 or (select count(*) from players where room_id=r.id and team='B')=0 then raise exception 'Une personne minimum par équipe'; end if;
 select id into a from players where room_id=r.id and team='A' order by created_at limit 1;
 select id into b from players where room_id=r.id and team='B' order by created_at limit 1;
 select id into cid from cards order by random() limit 1;
 update rooms set status='playing',current_team='A',current_card_id=cid,used_card_ids=array[cid],score_a=0,score_b=0,turn_ends_at=now()+interval '75 seconds',turn_number=1,guesser_id=a,referee_id=b where id=r.id returning * into r;
 update players set role=case when id=a then 'guesser' when id=b then 'referee' else 'player' end where room_id=r.id;
 return r;
end $$;

create or replace function public.game_action(p_code text,p_action text)
returns public.rooms
language plpgsql
security definer
set search_path=public
as $$
declare r public.rooms; cid integer; uid uuid := auth.uid();
begin
 select * into r from rooms where code=upper(p_code) for update;
 if r.id is null or r.status <> 'playing' then raise exception 'Partie indisponible'; end if;
 if p_action='buzz' and r.referee_id <> uid then raise exception 'Seul l’arbitre peut buzzer'; end if;
 if p_action in ('found','pass') and r.guesser_id <> uid then raise exception 'Seul le joueur qui fait deviner peut agir'; end if;
 select id into cid from cards where not (id = any(r.used_card_ids)) order by random() limit 1;
 if cid is null then select id into cid from cards order by random() limit 1; update rooms set used_card_ids=array[cid] where id=r.id; else update rooms set used_card_ids=array_append(r.used_card_ids,cid) where id=r.id; end if;
 if p_action='found' and r.current_team='A' then update rooms set score_a=score_a+1 where id=r.id; elsif p_action='found' and r.current_team='B' then update rooms set score_b=score_b+1 where id=r.id; end if;
 update rooms set current_card_id=cid returning * into r;
 return r;
end $$;

create or replace function public.end_turn(p_code text)
returns public.rooms
language plpgsql
security definer
set search_path=public
as $$
declare r public.rooms; uid uuid := auth.uid(); next_team text; gid uuid; rid uuid; ids uuid[]; pos integer; i integer;
begin
 select * into r from rooms where code=upper(p_code) for update;
 if r.id is null or r.status <> 'playing' then raise exception 'Partie indisponible'; end if;
 if now() < r.turn_ends_at then raise exception 'Le chrono n’est pas terminé'; end if;
 if not exists(select 1 from players where room_id=r.id and id=uid) then raise exception 'Joueur inconnu'; end if;
 next_team:=case when r.current_team='A' then 'B' else 'A' end;
 select array_agg(id order by created_at) into ids from players where room_id=r.id and team=next_team;
 if ids is null or cardinality(ids)=0 then raise exception 'Équipe vide'; end if;
 pos:=coalesce(array_position(ids,r.guesser_id),0); i:=case when pos=0 or pos=cardinality(ids) then 1 else pos+1 end; gid:=ids[i];
 select id into rid from players where room_id=r.id and team<>next_team order by created_at limit 1;
 update rooms set current_team=next_team,guesser_id=gid,referee_id=rid,turn_number=turn_number+1,turn_ends_at=now()+interval '75 seconds' where id=r.id returning * into r;
 update players set role=case when id=gid then 'guesser' when id=rid then 'referee' else 'player' end where room_id=r.id;
 return r;
end $$;

grant execute on function public.create_room(text,text) to authenticated;
grant execute on function public.join_room(text,text,text) to authenticated;
grant execute on function public.start_game(text) to authenticated;
grant execute on function public.game_action(text,text) to authenticated;
grant execute on function public.end_turn(text) to authenticated;

create or replace function public.get_room_snapshot(p_code text)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare r public.rooms; ps jsonb;
begin
 select * into r from rooms where code=upper(p_code);
 if r.id is null then raise exception 'Room introuvable'; end if;
 select coalesce(jsonb_agg(to_jsonb(p) order by p.created_at),'[]'::jsonb) into ps from players p where p.room_id=r.id;
 return jsonb_build_object('room',to_jsonb(r),'players',ps);
end $$;
grant execute on function public.get_room_snapshot(text) to authenticated;
