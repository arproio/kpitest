CREATE OR REPLACE FUNCTION public.dblink_disconnect(text)
 RETURNS text
 LANGUAGE c
 STRICT
AS '$libdir/dblink', $function$dblink_disconnect$function$
