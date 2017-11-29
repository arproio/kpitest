CREATE OR REPLACE FUNCTION public.upsert_aspect_model(inserting_name character varying, inserting_type integer, inserting_key character varying, inserting_value text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    FOR i IN 1..3 LOOP
        UPDATE aspect_model SET entity_name = inserting_name, entity_type = inserting_type, key = inserting_key, value = inserting_value WHERE entity_name = inserting_name AND entity_type = inserting_type AND key = inserting_key;
        IF FOUND THEN
            RETURN;
        END IF;

        BEGIN
            INSERT INTO aspect_model (entity_name, entity_type, key, value) VALUES (inserting_name, inserting_type, inserting_key, inserting_value);
            RETURN;
            EXCEPTION WHEN unique_violation THEN
        		SELECT pg_sleep(0.1); -- sleep 0.1 seconds and loop to try the UPDATE again.
        END;
    END LOOP;
END;
$function$
