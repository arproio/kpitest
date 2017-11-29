CREATE OR REPLACE FUNCTION public.upsert_extension(extension_name character varying, extension_resource bytea, extension_checksum text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    FOR i IN 1..3 LOOP
        UPDATE extensions SET checksum = extension_checksum, resource = extension_resource WHERE name = extension_name;
        IF FOUND THEN
            RETURN;
        END IF;

        BEGIN
            INSERT INTO extensions (name, resource, checksum) VALUES (extension_name, extension_resource, extension_checksum);
            RETURN;
            EXCEPTION WHEN unique_violation THEN
        		SELECT pg_sleep(0.1); -- sleep 0.1 seconds and loop to try the UPDATE again.
        END;
    END LOOP;
END;
$function$
