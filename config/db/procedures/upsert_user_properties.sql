CREATE OR REPLACE FUNCTION public.upsert_user_properties(inserting_name character varying, inserting_key character varying, inserting_value text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    FOR i IN 1..3 LOOP
        UPDATE user_model_properties SET entity_name = inserting_name, key = inserting_key, value = inserting_value WHERE entity_name = inserting_name AND key = inserting_key;
        IF FOUND THEN
            RETURN;
        END IF;

        BEGIN
            INSERT INTO user_model_properties (entity_name, key, value) VALUES (inserting_name, inserting_key, inserting_value);
            RETURN;
            EXCEPTION WHEN unique_violation THEN
        		SELECT pg_sleep(0.1); -- sleep 0.1 seconds and loop to try the UPDATE again.
        END;
    END LOOP;
END;
$function$
