CREATE OR REPLACE FUNCTION public.dblink_current_query()
 RETURNS text
 LANGUAGE c
AS '$libdir/dblink', $function$dblink_current_query$function$
