CREATE OR REPLACE FUNCTION public.dblink_get_notify(conname text, OUT notify_name text, OUT be_pid integer, OUT extra text)
 RETURNS SETOF record
 LANGUAGE c
 STRICT
AS '$libdir/dblink', $function$dblink_get_notify$function$
