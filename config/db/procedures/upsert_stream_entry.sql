CREATE OR REPLACE FUNCTION public.upsert_stream_entry(entity_id_value character varying, source_id_value character varying, time_value timestamp without time zone, field_values_value jsonb, location_value character varying, source_type_value character varying, tags_value jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$ DECLARE    id_value bigint;
BEGIN     
	BEGIN         
		INSERT INTO stream (entity_id, source_id, time, field_values, location, source_type, tags)             
		values (entity_id_value, source_id_value, time_value, field_values_value, location_value, source_type_value, tags_value) 
		RETURNING entry_id INTO id_value;         
		RETURN id_value;     
		EXCEPTION WHEN unique_violation THEN         /* try update */     
	END;     
	UPDATE stream SET field_values=field_values_value, location=location_value, tags=tags_value     
	WHERE entity_id=entity_id_value and source_id=source_id_value and time=time_value and source_type=source_type_value 
		RETURNING entry_id INTO id_value;
	RETURN id_value; 
END; $function$
