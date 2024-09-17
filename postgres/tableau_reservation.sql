CREATE OR REPLACE FUNCTION TABLEAU(p_debut TIMESTAMP, p_fin TIMESTAMP, p_categorie INT)
    RETURNS TABLE
            (
                pavillon_id VARCHAR,
                local_id    VARCHAR,
                timeslot    TIMESTAMP,
                status      VARCHAR,
                commentary  TEXT
            )
    LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN QUERY
        -- Generate 15-minute time slots between p_debut and p_fin
        WITH time_slots AS (SELECT generate_series(p_debut, p_fin, interval '15 minutes') AS timeslot)
        SELECT l.pavillon_id::VARCHAR AS pavillon_id,
               l.local_id::VARCHAR    AS local_id,
               ts.timeslot,                      -- 15m interval
               CASE
                   -- Check if the timeslot falls within a reservation period for that local
                   WHEN (r.reservation_id IS NOT NULL AND ts.timeslot >= r.reserved_for AND
                         ts.timeslot < r.reservation_end) OR
                        (NOT is_cubicules_free(l.pavillon_id, l.local_id, ts.timeslot, ts.timeslot)) OR
                        (NOT parent_free(l.pavillon_id, l.local_id, ts.timeslot, ts.timeslot))THEN
                       'reserved'::VARCHAR
                   ELSE
                       'free'::VARCHAR
                   END                AS status, -- "reserved" or "free" status for each timeslot
                -- for commentaries
               CASE
                   -- Fetch commentary based on the reservation, cubicule, or parent local
                   WHEN (r.reservation_id IS NOT NULL AND ts.timeslot >= r.reserved_for AND
                         ts.timeslot < r.reservation_end) THEN
                       get_reservation_commentary(r.reservation_id, l.pavillon_id, l.local_id, ts.timeslot, ts.timeslot)
                   WHEN NOT is_cubicules_free(l.pavillon_id, l.local_id, ts.timeslot, ts.timeslot) THEN
                       get_cubicule_commentary(l.pavillon_id, l.local_id, ts.timeslot, ts.timeslot)
                   WHEN NOT parent_free(l.pavillon_id, l.local_id, ts.timeslot, ts.timeslot) THEN
                       get_parent_commentary(l.pavillon_id, l.local_id, ts.timeslot, ts.timeslot)
                   ELSE
                       NULL
                   END AS commentary

        FROM public.local_type l
                 CROSS JOIN
             time_slots ts -- Associate each local with each timeslot
                 LEFT JOIN
             public.reservation r ON l.local_id = r.local_id
                 AND ts.timeslot >= r.reserved_for
                 AND ts.timeslot < r.reservation_end
        WHERE l.local_category_id = p_categorie
        ORDER BY l.local_id, ts.timeslot; -- Order by local and timeslot
END;
$$;


CREATE OR REPLACE FUNCTION get_reservation_commentary(wanted_reservation_id INT, big_pavillon_id TEXT, big_local_id TEXT, wanted_reserved_for TIMESTAMP,
                                                      wanted_reservation_end TIMESTAMP) RETURNS TEXT AS
$$
    DECLARE
        result TEXT;
    BEGIN
        RAISE INFO 'res id: %', wanted_reservation_id;
        SELECT commentary INTO result FROM reservation WHERE reservation_id=wanted_reservation_id;
        RETURN result;
    END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION is_cubicules_free(big_pavillon_id TEXT, big_local_id TEXT, wanted_reserved_for TIMESTAMP,
                                             wanted_reservation_end TIMESTAMP) RETURNS BOOLEAN AS
$$
DECLARE
    all_available      BOOLEAN := true;
    cubicules          RECORD; -- To store each row of the result
    reservation_record RECORD;
    cubicules_cursor CURSOR FOR
        SELECT pavillon_id_1, local_id_1
        FROM local_with_locals
        WHERE local_id = big_local_id
          AND pavillon_id = big_pavillon_id;
BEGIN
    -- Open the cursor
    OPEN cubicules_cursor;

-- Loop through each record
    LOOP
        FETCH cubicules_cursor INTO cubicules;
        EXIT WHEN NOT FOUND;

        -- Access individual values using cubicules.pavillon_id_1 and cubicules.local_id_1
        -- Perform your logic here; for example:
        --RAISE NOTICE '--- CUBICULE FOUND: Pavillon ID: %, Local ID: %', cubicules.pavillon_id_1, cubicules.local_id_1;

        FOR reservation_record IN
            SELECT reservation_id
            FROM public.reservation
            WHERE pavillon_id = cubicules.pavillon_id_1
              AND local_id = cubicules.local_id_1
            LOOP
                IF (reservation_in_conflict(reservation_record.reservation_id, wanted_reserved_for,
                                            wanted_reservation_end)) THEN
                    --RAISE INFO '- The cubicule is reserved during your wanted scheduling!!!';
                    --RAISE INFO '- for % end %', wanted_reserved_for, wanted_reservation_end;
                    all_available := false;
                    CLOSE cubicules_cursor;
                    RETURN all_available;
                END IF;
            END LOOP;
    END LOOP;

    -- Close the cursor
    CLOSE cubicules_cursor;

    RETURN all_available;
END;
$$ LANGUAGE plpgsql;


-------------------------------------------------------
-- Verifie si le local est un sous-local d'un plus gros local qui serait peut-etre reserve
-------------------------------------------------------
CREATE OR REPLACE FUNCTION parent_free(small_pavillon_id TEXT, small_local_id TEXT, wanted_reserved_for TIMESTAMP,
                                       wanted_reservation_end TIMESTAMP) RETURNS BOOLEAN AS
$$
DECLARE
    parent_available   BOOLEAN := true;
    parents            RECORD; -- To store each row of the result
    reservation_record RECORD;
    parents_cursor CURSOR FOR
        SELECT pavillon_id, local_id
        FROM local_with_locals
        WHERE local_id_1 = small_local_id
          AND pavillon_id_1 = small_pavillon_id;
BEGIN
    -- Open the cursor
    OPEN parents_cursor;

-- Loop through each record
    LOOP
        FETCH parents_cursor INTO parents;
        EXIT WHEN NOT FOUND;

        -- Access individual values using parents_cursor.pavillon_id and parents_cursor.local_id
        -- Perform your logic here; for example:
        --RAISE NOTICE '--- PARENT LOCAL FOUND: Pavillon ID: %, Local ID: %', parents.pavillon_id, parents.local_id;

        FOR reservation_record IN
            SELECT reservation_id
            FROM public.reservation
            WHERE pavillon_id = parents.pavillon_id
              AND local_id = parents.local_id
            LOOP
                IF (reservation_in_conflict(reservation_record.reservation_id, wanted_reserved_for,
                                            wanted_reservation_end)) THEN
                    --RAISE INFO '- The parent is reserved during your wanted scheduling!!!';
                    parent_available := false;
                    CLOSE parents_cursor;
                    RETURN parent_available;
                END IF;
            END LOOP;
    END LOOP;

    -- Close the cursor
    CLOSE parents_cursor;

    RETURN parent_available;
END;
$$ LANGUAGE plpgsql;





















CREATE OR REPLACE FUNCTION get_cubicule_commentary(big_pavillon_id TEXT, big_local_id TEXT, wanted_reserved_for TIMESTAMP,
                                             wanted_reservation_end TIMESTAMP) RETURNS TEXT AS
$$
DECLARE
    all_available      BOOLEAN := true;
    cubicules          RECORD; -- To store each row of the result
    reservation_record RECORD;
    comment TEXT;
    cubicules_cursor CURSOR FOR
        SELECT pavillon_id_1, local_id_1
        FROM local_with_locals
        WHERE local_id = big_local_id
          AND pavillon_id = big_pavillon_id;
BEGIN
    -- Open the cursor
    OPEN cubicules_cursor;

-- Loop through each record
    LOOP
        FETCH cubicules_cursor INTO cubicules;
        EXIT WHEN NOT FOUND;

        -- Access individual values using cubicules.pavillon_id_1 and cubicules.local_id_1
        -- Perform your logic here; for example:
        RAISE NOTICE '--- CUBICULE FOUND: Pavillon ID: %, Local ID: %', cubicules.pavillon_id_1, cubicules.local_id_1;

        FOR reservation_record IN
            SELECT reservation_id
            FROM public.reservation
            WHERE pavillon_id = cubicules.pavillon_id_1
              AND local_id = cubicules.local_id_1
            LOOP
                IF (reservation_in_conflict(reservation_record.reservation_id, wanted_reserved_for,
                                            wanted_reservation_end)) THEN
                    RAISE INFO '- The cubicule is reserved during your wanted scheduling!!!';
                    RAISE INFO '- for % end %', wanted_reserved_for, wanted_reservation_end;
                    all_available := false;
                    SELECT commentary INTO comment FROM reservation WHERE reservation_id=reservation_record.reservation_id;
                    CLOSE cubicules_cursor;
                    RETURN comment;
                END IF;
            END LOOP;
    END LOOP;

    -- Close the cursor
    CLOSE cubicules_cursor;

    RETURN comment;
END;
$$ LANGUAGE plpgsql;


-------------------------------------------------------
-- Verifie si le local est un sous-local d'un plus gros local qui serait peut-etre reserve
-------------------------------------------------------
CREATE OR REPLACE FUNCTION get_parent_commentary(small_pavillon_id TEXT, small_local_id TEXT, wanted_reserved_for TIMESTAMP,
                                       wanted_reservation_end TIMESTAMP) RETURNS TEXT AS
$$
DECLARE
    parent_available   BOOLEAN := true;
    parents            RECORD; -- To store each row of the result
    reservation_record RECORD;
    comment TEXT;
    parents_cursor CURSOR FOR
        SELECT pavillon_id, local_id
        FROM local_with_locals
        WHERE local_id_1 = small_local_id
          AND pavillon_id_1 = small_pavillon_id;
BEGIN
    -- Open the cursor
    OPEN parents_cursor;

-- Loop through each record
    LOOP
        FETCH parents_cursor INTO parents;
        EXIT WHEN NOT FOUND;

        -- Access individual values using parents_cursor.pavillon_id and parents_cursor.local_id
        -- Perform your logic here; for example:
        RAISE NOTICE '--- PARENT LOCAL FOUND: Pavillon ID: %, Local ID: %', parents.pavillon_id, parents.local_id;

        FOR reservation_record IN
            SELECT reservation_id
            FROM public.reservation
            WHERE pavillon_id = parents.pavillon_id
              AND local_id = parents.local_id
            LOOP
                IF (reservation_in_conflict(reservation_record.reservation_id, wanted_reserved_for,
                                            wanted_reservation_end)) THEN
                    RAISE INFO '- The parent is reserved during your wanted scheduling!!!';
                    parent_available := false;
                    SELECT commentary INTO comment FROM reservation WHERE reservation_id=reservation_record.reservation_id;
                    CLOSE parents_cursor;
                    RETURN comment;
                END IF;
            END LOOP;
    END LOOP;

    -- Close the cursor
    CLOSE parents_cursor;

    RETURN comment;
END;
$$ LANGUAGE plpgsql;
--insert into public.reservation values(0, 'C1', '3125', 0, 1, 2);