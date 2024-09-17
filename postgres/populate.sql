--Departements
insert into public.departement values(0,'Genie electrique et Genie informatique');
insert into public.departement values(1,'Genie mecanique');
insert into public.departement values(2,'Genie chimique et biotechnologie');
insert into public.departement values(3,'Genie civil et du batiment');

--Categories de locals
insert into public.local_category values(0,'Laboratoire');
insert into public.local_category values(1,'Tutorat');
insert into public.local_category values(2,'Auditorium');
insert into public.local_category values(3,'reunion');
insert into public.local_category values(4,'cubicule');

-- Ressources qui peut avoir dans un local
insert into public.local_ressource values(0,'Tableau blanc');
insert into public.local_ressource values(1,'Projecteur');
insert into public.local_ressource values(2,'Table');
insert into public.local_ressource values(3,'Cubicule');
insert into public.local_ressource values(4,'Chaises');

-- Categories de membres
insert into public.member_category values(0,'Etudiants', 0);
insert into public.member_category values(1,'Enseignant', 1);
insert into public.member_category values(2,'Personnel de soutient', 2);
insert into public.member_category values(3,'Administrateurs',3);

-- Pavillons
insert into public.pavillon values('C1','C1');
insert into public.pavillon values('C2','C2');
insert into public.pavillon values('C3','C3');







-- Quelques personnes
insert into public.person values(0, 'Lyam', 'BRS');
insert into public.person values(1, 'Frank', 'Gratton');
insert into public.person values(2, 'Clovis', 'Langevin');
insert into public.person values(3, 'Victor', 'Larose');
insert into public.person values(4, 'Charles', 'Something');
-- Leurs departements
insert into public.people_in_departement values(0, 0);
insert into public.people_in_departement values(1, 1);
insert into public.people_in_departement values(2, 2);
insert into public.people_in_departement values(3, 3);
insert into public.people_in_departement values(4, 0);

-- Leurs status
insert into public.peoples_statuses values(0, 0);
insert into public.peoples_statuses values(1, 1);
insert into public.peoples_statuses values(2, 2);
insert into public.peoples_statuses values(3, 3);
insert into public.peoples_statuses values(4, 0); -- Lui, il a plusieurs status
insert into public.peoples_statuses values(4, 3); -- Lui, il a plusieurs status



-- Quelques locaux. Cree les locaux
insert into public.local_type values('C1', '3125', 'Laboratoire proceduraux 1', 1);
insert into public.local_type values('C1', '3126', 'Laboratoire proceduraux 2', 1);
insert into public.local_type values('C1', '5119', 'Laboratoire de chimie', 0);
insert into public.local_type values('C2', '2014', 'Auditorium 2', 2);
insert into public.local_type values('C3', '1001', 'Local de reunion', 3);
insert into public.local_type values('C3', '1400', 'Laboratoire de mecanique', 0);

-- Les 3 cubicules du local 3125
insert into public.local_type values('C1', '3125-1', 'cubicule du laboratoire', 4);
insert into public.local_type values('C1', '3125-2', 'cubicule du laboratoire', 4);
insert into public.local_type values('C1', '3125-3', 'cubicule du laboratoire', 4);

-- Les ressources de ces locaux la
insert into public.locals_ressources values('C1', '3125', 3, 10); -- 3 cubicules dans ce local la
insert into public.locals_ressources values('C1', '5119', 0, 1);
insert into public.locals_ressources values('C2', '2014', 1, 2);
insert into public.locals_ressources values('C3', '1001', 2, 3);
insert into public.locals_ressources values('C3', '1400', 4, 30);

-- Les locaux avec des locaux dedans
insert into public.local_with_locals values('C1', '3125', 'C1', '3125-1');
insert into public.local_with_locals values('C1', '3125', 'C1', '3125-2');
insert into public.local_with_locals values('C1', '3125', 'C1', '3125-3');



-- Les permissions
insert into public.reservation_permissions values(0, 1, 0, '24:00', '24:00', true, true,false);
insert into public.reservation_permissions values(0, 1, 1, '24:00', '24:00', false, true,false);
insert into public.reservation_permissions values(0, 4, 2, '24:00', '24:00', true, true,true);
insert into public.reservation_permissions values(0, 3, 3, '24:00', '24:00', true, true,true);


