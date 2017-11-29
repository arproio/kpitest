CREATE OR REPLACE FUNCTION public.create_column(table_id text, column_id text, column_type text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
 DECLARE
  dtype text;
  command text;
 BEGIN

  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS WHERE COLUMN_NAME=column_id AND TABLE_NAME=table_id) THEN 
   command := format('ALTER TABLE %I ADD COLUMN %I %s', table_id, column_id, column_type);
   EXECUTE command;
  END IF;
  SELECT DATA_TYPE INTO dtype FROM information_schema.COLUMNS WHERE COLUMN_NAME=column_id AND TABLE_NAME=table_id;
  IF dtype != column_type THEN
   RAISE NOTICE 'Types are inconsistent for %.%: defined as %, expected %.', table_id, column_id, dtype, column_type;
  END IF;
 END;
$function$
