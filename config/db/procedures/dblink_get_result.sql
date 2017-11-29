CREATE OR REPLACE FUNCTION public.dblink_get_result(text, boolean)
 RETURNS SETOF record
 LANGUAGE c
 STRICT
AS '$libdir/dblink', $function$dblink_get_result$function$
