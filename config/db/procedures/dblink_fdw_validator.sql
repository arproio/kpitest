CREATE OR REPLACE FUNCTION public.dblink_fdw_validator(options text[], catalog oid)
 RETURNS void
 LANGUAGE c
 STRICT
AS '$libdir/dblink', $function$dblink_fdw_validator$function$
