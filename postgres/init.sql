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
                            reserved_for TIMESTAMP NOT NULL,
                            reservation_end TIMESTAMP NOT NULL,
                            PRIMARY KEY(person_id, pavillon_id, local_id),
                            UNIQUE(reservation_id),
                            FOREIGN KEY(person_id) REFERENCES person(person_id),
                            FOREIGN KEY(pavillon_id, local_id) REFERENCES local_type(pavillon_id, local_id)
);

CREATE TABLE reservation_permissions(
                                        departement_id INTEGER,
                                        local_category_id INTEGER,
                                        personal_category_id INTEGER,
                                        allowed_preorder_duration TIME NOT NULL,
                                        max_reservatoion_duration TIME NOT NULL,
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





CREATE OR REPLACE FUNCTION TABLEAU(p_debut TIMESTAMP, p_fin TIMESTAMP, p_categorie INT)
    RETURNS TABLE (
                      local VARCHAR,
                      timeslot TIMESTAMP,
                      reservation_status VARCHAR
                  )
    LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
        -- Génère des plages horaires de 15 minutes et les associe aux locaux
        WITH time_slots AS (
            -- Génère toutes les plages horaires de 15 minutes entre p_debut et p_fin
            SELECT generate_series(p_debut, p_fin, interval '15 minutes') AS timeslot
        )
        SELECT
            l.local_id::VARCHAR AS local,
            ts.timeslot,
            CASE
                -- Si une réservation existe dans cette plage, retourne l'ID de la réservation
                WHEN r.reserved_for IS NOT NULL AND ts.timeslot >= r.reserved_for AND ts.timeslot < r.reservation_end THEN
                    'Réservation ID: ' || r.reservation_id
                ELSE 'Disponible'  -- Sinon, indique que la plage est disponible
                END AS reservation_status
        FROM
            public.local_type l
                CROSS JOIN
            time_slots ts  -- Associe chaque local à chaque plage horaire
                LEFT JOIN
            public.reservation r ON l.local_id = r.local_id
                AND ts.timeslot >= r.reserved_for
                AND ts.timeslot < r.reservation_end
        WHERE
            l.local_category_id = p_categorie
        ORDER BY
            l.local_id, ts.timeslot;
END;
$$;

--insert into public.reservation values(0, 'C1', '3125', 0, 1, 2);