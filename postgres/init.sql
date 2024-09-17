create schema public;
set search_path = public;

CREATE TABLE person(
   person_id INTEGER,
   name TEXT,
   last_name TEXT,
   PRIMARY KEY(person_id)
);

CREATE TABLE pavillon(
   pavillon_id CHAR(2) ,
   name TEXT NOT NULL,
   PRIMARY KEY(pavillon_id)
);

CREATE TABLE departement(
   departement_id INTEGER,
   name TEXT,
   PRIMARY KEY(departement_id)
);

CREATE TABLE local_category(
   local_category_id INTEGER,
   name TEXT,
   PRIMARY KEY(local_category_id)
);

CREATE TABLE member_category(
   personal_category_id INTEGER,
   name TEXT,
   priority INTEGER NOT NULL,
   PRIMARY KEY(personal_category_id)
);

CREATE TABLE local_ressource(
   local_ressource_id INTEGER,
   name TEXT,
   PRIMARY KEY(local_ressource_id)
);

CREATE TABLE log(
   log_id INTEGER,
   _timestamp BIGINT NOT NULL,
   message TEXT NOT NULL,
   PRIMARY KEY(log_id)
);

CREATE TABLE local_type(
   pavillon_id CHAR(2) ,
   local_id TEXT,
   name TEXT,
   local_category_id INTEGER NOT NULL,
   PRIMARY KEY(pavillon_id, local_id),
   FOREIGN KEY(pavillon_id) REFERENCES pavillon(pavillon_id),
   FOREIGN KEY(local_category_id) REFERENCES local_category(local_category_id)
);

CREATE TABLE people_in_departement(
   person_id INTEGER,
   departement_id INTEGER,
   PRIMARY KEY(person_id, departement_id),
   FOREIGN KEY(person_id) REFERENCES person(person_id),
   FOREIGN KEY(departement_id) REFERENCES departement(departement_id)
);

CREATE TABLE peoples_statuses(
   person_id INTEGER,
   personal_category_id INTEGER,
   PRIMARY KEY(person_id, personal_category_id),
   FOREIGN KEY(person_id) REFERENCES person(person_id),
   FOREIGN KEY(personal_category_id) REFERENCES member_category(personal_category_id)
);

CREATE TABLE reservation(
   person_id INTEGER,
   pavillon_id CHAR(2) ,
   local_id TEXT,
   reservation_id INTEGER NOT NULL,
   reserved_for BIGINT NOT NULL,
   reservation_end BIGINT NOT NULL,
   PRIMARY KEY(person_id, pavillon_id, local_id),
   UNIQUE(reservation_id),
   FOREIGN KEY(person_id) REFERENCES person(person_id),
   FOREIGN KEY(pavillon_id, local_id) REFERENCES local_type(pavillon_id, local_id)
);

CREATE TABLE reservation_permissions(
   departement_id INTEGER,
   local_category_id INTEGER,
   personal_category_id INTEGER,
   allowed_preorder_duration INTEGER NOT NULL,
   max_reservatoion_duration INTEGER NOT NULL,
   can_reserve BOOLEAN NOT NULL,
   can_see BOOLEAN NOT NULL,
   can_modify_others BOOLEAN NOT NULL,
   PRIMARY KEY(departement_id, local_category_id, personal_category_id),
   FOREIGN KEY(departement_id) REFERENCES departement(departement_id),
   FOREIGN KEY(local_category_id) REFERENCES local_category(local_category_id),
   FOREIGN KEY(personal_category_id) REFERENCES member_category(personal_category_id)
);

CREATE TABLE locals_ressources(
   pavillon_id CHAR(2) ,
   local_id TEXT,
   local_ressource_id INTEGER,
   available_quantity_ INTEGER NOT NULL,
   PRIMARY KEY(pavillon_id, local_id, local_ressource_id),
   FOREIGN KEY(pavillon_id, local_id) REFERENCES local_type(pavillon_id, local_id),
   FOREIGN KEY(local_ressource_id) REFERENCES local_ressource(local_ressource_id)
);

CREATE TABLE local_with_locals(
   pavillon_id CHAR(2) ,
   local_id TEXT,
   pavillon_id_1 CHAR(2) ,
   local_id_1 TEXT,
   PRIMARY KEY(pavillon_id, local_id, pavillon_id_1, local_id_1),
   FOREIGN KEY(pavillon_id, local_id) REFERENCES local_type(pavillon_id, local_id),
   FOREIGN KEY(pavillon_id_1, local_id_1) REFERENCES local_type(pavillon_id, local_id)
);



CREATE OR REPLACE FUNCTION  TABLEAU(p_debut INT, p_fin INT)
RETURNS TABLE (
    local VARCHAR,
    reserved_for BIGINT,
    reservation_end BIGINT
    )
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    -- Sélectionne les informations des réservations avec les conditions
    SELECT
        --l.description AS local,
        l.local_id::VARCHAR AS local,
        r.reserved_for,
        r.reservation_end
    FROM
        public.local_type l
    LEFT JOIN
        public.reservation r ON l.local_id = r.local_id
        AND r.reserved_for >= p_debut
        AND r.reservation_end <= p_fin
    --WHERE
        --l.categorie = p_categorie
    ORDER BY
        r.reserved_for;
END;
$$;