--Quelques reservations
insert into public.reservation values(0, 'C1', '3125', 0, '2024-09-16 8:00:00', '2024-09-16 9:00:00');
insert into public.reservation values(1, 'C1', '3125', 0, '2024-09-16 10:00:00', '2024-09-16 11:00:00');


--Aller voir la tab
SELECT * FROM TABLEAU('2024-09-16 08:00:00', '2024-09-16 12:00:00', 1);