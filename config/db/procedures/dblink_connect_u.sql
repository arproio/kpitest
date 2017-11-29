CREATE OR REPLACE FUNCTION public.dblink_connect_u(text, text)
 RETURNS text
 LANGUAGE c
 STRICT SECURITY DEFINER
AS '$libdir/dblink', $function$dblink_connect$function$
