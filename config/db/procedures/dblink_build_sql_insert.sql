CREATE OR REPLACE FUNCTION public.dblink_build_sql_insert(text, int2vector, integer, text[], text[])
 RETURNS text
 LANGUAGE c
 STRICT
AS '$libdir/dblink', $function$dblink_build_sql_insert$function$
