-------------------------------------------------------
-- Get toutes les reservations pour un local X
-------------------------------------------------------
CREATE OR REPLACE FUNCTION reservation_in_conflict(wanted_reservation_id INT, start_date TIMESTAMP, end_date TIMESTAMP) RETURNS BOOLEAN AS
$$
    DECLARE
       reservation_start_time TIMESTAMP;
       reservation_end_time TIMESTAMP;
    BEGIN
        SELECT reserved_for INTO reservation_start_time FROM public.reservation WHERE reservation_id = wanted_reservation_id;
        SELECT reservation_end INTO reservation_end_time FROM public.reservation WHERE reservation_id = wanted_reservation_id;
        RETURN is_dates_in_conflict(reservation_start_time, reservation_end_time, start_date, end_date);
    END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------
-- Check si les dates de reservations sont en conflit
-------------------------------------------------------
CREATE OR REPLACE FUNCTION is_dates_in_conflict(reservation_start_time TIMESTAMP, reservation_end_time TIMESTAMP, date_to_check_start TIMESTAMP, date_to_check_end TIMESTAMP) RETURNS BOOLEAN AS
$$
    BEGIN
        IF ((date_to_check_start < reservation_start_time OR date_to_check_start > reservation_end_time) AND (date_to_check_end < reservation_start_time OR date_to_check_end > reservation_end_time)) THEN
            RETURN false;
        ELSE
           RETURN true;
        END IF;
    END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------
-- Verifie si tu peut loue le local based of si ces sous-locaux ont des reservations
-------------------------------------------------------
CREATE OR REPLACE FUNCTION local_cubicules_available(big_pavillon_id TEXT, big_local_id TEXT, wanted_reserved_for TIMESTAMP, wanted_reservation_end TIMESTAMP) RETURNS BOOLEAN AS
$$
DECLARE
    all_available BOOLEAN := true;
    cubicules RECORD; -- To store each row of the result
    reservation_record RECORD;
    cubicules_cursor CURSOR FOR
        SELECT pavillon_id_1, local_id_1
        FROM local_with_locals
        WHERE local_id = big_local_id AND pavillon_id = big_pavillon_id;
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
            WHERE pavillon_id=cubicules.pavillon_id_1 AND local_id=cubicules.local_id_1
        LOOP
            IF(reservation_in_conflict(reservation_record.reservation_id,wanted_reserved_for,wanted_reservation_end)) THEN
                --RAISE INFO '- The cubicule is reserved during your wanted scheduling!!!';
                --all_available := false;
                --CLOSE cubicules_cursor;
                --RETURN all_available;
                RAISE EXCEPTION 'Your reservation failed because some cubicules are reserved during your wanted scheduling. % - %', cubicules.pavillon_id_1, cubicules.local_id_1;
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
CREATE OR REPLACE FUNCTION parent_local_available(small_pavillon_id TEXT, small_local_id TEXT, wanted_reserved_for TIMESTAMP, wanted_reservation_end TIMESTAMP) RETURNS BOOLEAN AS
$$
DECLARE
    parent_available BOOLEAN := true;
    parents RECORD; -- To store each row of the result
    reservation_record RECORD;
    parents_cursor CURSOR FOR
        SELECT pavillon_id, local_id
        FROM local_with_locals
        WHERE local_id_1 = small_local_id AND pavillon_id_1 = small_pavillon_id;
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
            WHERE pavillon_id=parents.pavillon_id AND local_id=parents.local_id
        LOOP
            IF(reservation_in_conflict(reservation_record.reservation_id,wanted_reserved_for,wanted_reservation_end)) THEN
                --RAISE INFO '- The parent is reserved during your wanted scheduling!!!';
                --parent_available := false;
                --CLOSE parents_cursor;
                --RETURN parent_available;
                RAISE EXCEPTION 'Your reservation failed because the cubicules parent is reserved during your scheduling. % - %', parents.pavillon_id, parents.local_id;
            END IF;
        END LOOP;
    END LOOP;

    -- Close the cursor
    CLOSE parents_cursor;

    RETURN parent_available;
END;
$$ LANGUAGE plpgsql;
-------------------------------------------------------
-- Insert une nouvelle reservation si les dates matches
-------------------------------------------------------
CREATE OR REPLACE FUNCTION new_reservation() RETURNS TRIGGER AS
$$
    DECLARE
        can_reserve BOOLEAN := true;
        new_id INT;
        reservation_record RECORD;
    BEGIN
        RAISE INFO '----------------------------------------------------------- NEW RESERVATION';

        RAISE INFO 'Checking if the local has cubicules in it...';
        -- Check if the lcoal has sub-locals in it. If yes, then they'll all be checked for their own reservations
        IF local_cubicules_available(NEW.pavillon_id, NEW.local_id, NEW.reserved_for, NEW.reservation_end) THEN
            RAISE INFO '- No conflict found / local does not have cubicules';
        END IF;

        RAISE INFO 'Checking if youre reserving a cubicule';
        IF parent_local_available(NEW.pavillon_id, NEW.local_id, NEW.reserved_for, NEW.reservation_end) THEN
            RAISE INFO '- No conflict found / local is not a cubicule';
        END IF;

        -- For each reservation of the wanted local, check if their dates conflicts with the wanted one
        FOR reservation_record IN
            SELECT reservation_id
            FROM public.reservation
            WHERE pavillon_id=NEW.pavillon_id AND local_id=NEW.local_id
        LOOP
            IF(reservation_in_conflict(reservation_record.reservation_id,NEW.reserved_for,NEW.reservation_end)) THEN
                RAISE INFO '- Another reservation is in conflict with the wanted one!';
                can_reserve := false;
            END IF;
        END LOOP;

        IF (can_reserve) THEN
            SELECT COALESCE(MAX(reservation_id), 0) + 1 INTO new_id FROM public.reservation;
            NEW.reservation_id := new_id;
            RAISE INFO '----------------------------- SUCCESS!';
            return NEW;
        ElSE
            RAISE EXCEPTION 'Schedule conflict found! Reservation cancelled. Youre trying to reserve a local that is already reserved in the time you want!';
        END IF;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_reservation
BEFORE INSERT ON public.reservation
FOR EACH ROW
EXECUTE FUNCTION new_reservation();