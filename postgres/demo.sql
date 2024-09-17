-- personne 1 essaye de faire une reservation. It works!
insert into public.reservation values(1, 'C1', '3125', 0, '2024-09-16 8:00:00', '2024-09-16 9:00:00', 'Ma premiere reservation!');

-- personne 1 essaye de reserver un autre local, pour du tutorat. It works!
insert into public.reservation values(1, 'C1', '5119', 0, '2024-09-16 8:00:00', '2024-09-16 9:00:00', 'Mon local de tutorat!');

-- personne 2 essaye de reserver un cubicule du local 3125, mais plus tard dans la journee. it works!
insert into public.reservation values(2, 'C1', '3125-1', 0, '2024-09-16 10:00:00', '2024-09-16 11:00:00', 'Jai juste besoin dun cubicule');



-- La personne 3 essaye de reserver le gros local 3125. Mais la personne 2 a deja reserver un cubicule
insert into public.reservation values(1, 'C1', '3125', 0, '2024-09-16 10:00:00', '2024-09-16 11:00:00', 'Jai un cours a donnee!');

-- Quelqu'un essaye de reserver un cubicule, mais le 3125 est deja reserver!
insert into public.reservation values(3, 'C1', '3125-3', 0, '2024-09-16 8:00:00', '2024-09-16 11:00:00', 'Faudrait que je travail la la');
