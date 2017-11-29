CREATE OR REPLACE FUNCTION public.upsert_property_vtq(insertingid text, insertingname text, insertingvalue bytea, insertingtime bigint, insertingquality text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    FOR i IN 1..3 LOOP
        UPDATE property_vtq SET value = insertingValue, time = insertingTime, quality = insertingQuality WHERE id = insertingId AND name = insertingName;
        IF FOUND THEN
            RETURN;
        END IF;

        BEGIN
            INSERT INTO property_vtq (id, name, value, time, quality) VALUES (insertingId, insertingName, insertingValue, insertingTime, insertingQuality);
            RETURN;
        	EXCEPTION WHEN unique_violation THEN
        		SELECT pg_sleep(0.1); -- sleep 0.1 seconds and loop to try the UPDATE again.
        END;       
    END LOOP;
END;
$function$
