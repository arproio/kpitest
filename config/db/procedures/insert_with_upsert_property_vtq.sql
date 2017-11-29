CREATE OR REPLACE FUNCTION public.insert_with_upsert_property_vtq(insertingid text, insertingname text, insertingvalue bytea, insertingtime bigint, insertingquality text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	INSERT INTO property_vtq (id, name, value, time, quality) VALUES (insertingId, insertingName, insertingValue, insertingTime, insertingQuality);
	EXCEPTION WHEN unique_violation THEN
		UPDATE property_vtq SET value = insertingValue, time = insertingTime, quality = insertingQuality WHERE id = insertingId AND name = insertingName;
END;
$function$
