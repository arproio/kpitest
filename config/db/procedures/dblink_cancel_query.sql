CREATE OR REPLACE FUNCTION public.dblink_cancel_query(text)
 RETURNS text
 LANGUAGE c
 STRICT
AS '$libdir/dblink', $function$dblink_cancel_query$function$
