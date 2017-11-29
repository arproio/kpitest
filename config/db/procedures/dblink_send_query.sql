CREATE OR REPLACE FUNCTION public.dblink_send_query(text, text)
 RETURNS integer
 LANGUAGE c
 STRICT
AS '$libdir/dblink', $function$dblink_send_query$function$
