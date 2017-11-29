CREATE OR REPLACE FUNCTION public.dblink_error_message(text)
 RETURNS text
 LANGUAGE c
 STRICT
AS '$libdir/dblink', $function$dblink_error_message$function$
