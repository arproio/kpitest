CREATE OR REPLACE FUNCTION public.dblink_exec(text, boolean)
 RETURNS text
 LANGUAGE c
 STRICT
AS '$libdir/dblink', $function$dblink_exec$function$
