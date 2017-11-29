CREATE OR REPLACE FUNCTION public.dblink_build_sql_delete(text, int2vector, integer, text[])
 RETURNS text
 LANGUAGE c
 STRICT
AS '$libdir/dblink', $function$dblink_build_sql_delete$function$
