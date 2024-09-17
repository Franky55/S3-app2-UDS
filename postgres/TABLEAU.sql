--Quelques reservations locaux
insert into public.reservation values(0, 'C1', '3125', 0, '2024-09-16 8:00:00', '2024-09-16 9:00:00', 'PMC');
insert into public.reservation values(1, 'C1', '3125', 0, '2024-09-16 10:00:00', '2024-09-16 11:00:00', 'Frank etait ici');


--Aller voir les local de categorie 1
SELECT * FROM TABLEAU('2024-09-16 08:00:00', '2024-09-16 12:00:00', 1);


--Quelques reservations cubicule
insert into public.reservation values(0, 'C1', '3125-1', 0, '2024-09-16 8:00:00', '2024-09-16 9:00:00', 'PMC cubicule');
insert into public.reservation values(1, 'C1', '3125-2', 0, '2024-09-16 10:00:00', '2024-09-16 11:00:00', 'Frank etait ici cubicule');

insert into public.reservation values(2, 'C1', '3125-3', 0, '2024-09-16 8:00:00', '2024-09-16 9:00:00', 'PMC cubicule3');
insert into public.reservation values(3, 'C1', '3125-1', 0, '2024-09-16 10:00:00', '2024-09-16 11:00:00', 'Frank etait ici cubicule4');

--Aller voir les local de categorie 4 cubicule
SELECT * FROM TABLEAU('2024-09-16 08:00:00', '2024-09-16 12:00:00', 4);