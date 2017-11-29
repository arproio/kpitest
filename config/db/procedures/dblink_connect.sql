CREATE OR REPLACE FUNCTION public.dblink_connect(text, text)
 RETURNS text
 LANGUAGE c
 STRICT
AS '$libdir/dblink', $function$dblink_connect$function$
