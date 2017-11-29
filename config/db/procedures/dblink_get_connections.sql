CREATE OR REPLACE FUNCTION public.dblink_get_connections()
 RETURNS text[]
 LANGUAGE c
AS '$libdir/dblink', $function$dblink_get_connections$function$
