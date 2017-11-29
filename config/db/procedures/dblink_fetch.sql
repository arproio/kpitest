CREATE OR REPLACE FUNCTION public.dblink_fetch(text, text, integer, boolean)
 RETURNS SETOF record
 LANGUAGE c
 STRICT
AS '$libdir/dblink', $function$dblink_fetch$function$
