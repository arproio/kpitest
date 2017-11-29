CREATE OR REPLACE FUNCTION public.dblink_get_pkey(text)
 RETURNS SETOF dblink_pkey_results
 LANGUAGE c
 STRICT
AS '$libdir/dblink', $function$dblink_get_pkey$function$
