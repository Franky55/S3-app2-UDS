-------------------------------------------------------
-- Get toutes les reservations pour un local X
-------------------------------------------------------
CREATE OR REPLACE FUNCTION reservation_in_conflict(wanted_reservation_id INT, start_date BIGINT, end_date BIGINT) RETURNS BOOLEAN AS
$$
    DECLARE
       reservation_start_time INT;
       reservation_end_time INT;
    BEGIN
        SELECT reserved_for INTO reservation_start_time FROM public.reservation WHERE reservation_id = wanted_reservation_id;
        SELECT reservation_end INTO reservation_end_time FROM public.reservation WHERE reservation_id = wanted_reservation_id;
        RETURN is_dates_in_conflict(reservation_start_time, reservation_end_time, start_date, end_date);
    END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------
-- Check si les dates de reservations sont en conflit
-------------------------------------------------------
CREATE OR REPLACE FUNCTION is_dates_in_conflict(reservation_start_time BIGINT, reservation_end_time BIGINT, date_to_check_start BIGINT, date_to_check_end BIGINT) RETURNS BOOLEAN AS
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
-- Insert une nouvelle reservation si les dates matches
-------------------------------------------------------
CREATE OR REPLACE FUNCTION new_reservation() RETURNS TRIGGER AS
$$
    DECLARE
        can_reserve BOOLEAN;
        new_id INT;
        reservation_record RECORD;
    BEGIN
        -- Get les reservations pour ce local la
        --SELECT reservation_id INTO reservations FROM public.reservation WHERE pavillon_id=$1,local_id=$2;
        can_reserve := true;

        FOR reservation_record IN
            SELECT reservation_id
            FROM public.reservation
            WHERE pavillon_id=NEW.pavillon_id AND local_id=NEW.local_id
        LOOP
            IF(reservation_in_conflict(reservation_record.reservation_id,NEW.reserved_for,NEW.reservation_end)) THEN
                can_reserve := false;
            END IF;
        END LOOP;

        IF (can_reserve) THEN
            SELECT COALESCE(MAX(reservation_id), 0) + 1 INTO new_id FROM public.reservation;
            NEW.reservation_id := new_id;
            return NEW;
        ElSE
            RAISE EXCEPTION 'Conflit!';
        END IF;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_reservation
BEFORE INSERT ON public.reservation
FOR EACH ROW
EXECUTE FUNCTION new_reservation();