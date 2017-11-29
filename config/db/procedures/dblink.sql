CREATE OR REPLACE FUNCTION public.dblink(text, boolean)
 RETURNS SETOF record
 LANGUAGE c
 STRICT
AS '$libdir/dblink', $function$dblink_record$function$
