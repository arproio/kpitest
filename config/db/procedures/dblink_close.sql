CREATE OR REPLACE FUNCTION public.dblink_close(text, text, boolean)
 RETURNS text
 LANGUAGE c
 STRICT
AS '$libdir/dblink', $function$dblink_close$function$
