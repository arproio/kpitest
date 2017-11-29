CREATE OR REPLACE FUNCTION public.upsert_value_stream_entry(entity_id_value character varying, source_id_value character varying, time_value timestamp without time zone, property_type_value integer, property_name_value character varying, property_value_value text)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$ DECLARE      id_value bigint;
BEGIN      
	BEGIN          
		INSERT INTO value_stream (entity_id, source_id, time, property_type, property_name, property_value)              
		values (entity_id_value, source_id_value, time_value, property_type_value, property_name_value, property_value_value) 
		RETURNING entry_id INTO id_value;          
		RETURN id_value;      
		EXCEPTION WHEN unique_violation THEN          /* try update */      
	END;      
	UPDATE value_stream SET property_value=property_value_value      
	WHERE entity_id=entity_id_value AND source_id=source_id_value AND time=time_value AND property_name=property_name_value AND property_type=property_type_value      
		RETURNING entry_id INTO id_value;      
	RETURN id_value; 
END; $function$
