CREATE OR REPLACE FUNCTION public.dblink_is_busy(text)
 RETURNS integer
 LANGUAGE c
 STRICT
AS '$libdir/dblink', $function$dblink_is_busy$function$
