CREATE OR REPLACE FUNCTION public.dblink_open(text, text, text, boolean)
 RETURNS text
 LANGUAGE c
 STRICT
AS '$libdir/dblink', $function$dblink_open$function$
