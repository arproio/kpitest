CREATE OR REPLACE FUNCTION public.asset_statetimesum_batch_shift(dailyshiftid character varying, shiftid character varying, shiftname character varying, start_time_string character varying, end_time_string character varying, machine_ids character varying[], value_streams character varying[], streams character varying[], par_property_names character varying[], expected_values integer[], target_names character varying[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
-- value_stream_name: this is the associated value stream on Thing general info page.
-- machine_id: this is the Thing name in Thingworx
-- end_time_string: the time to check in string with format: YYYYMMDDHH24MISS, for example:20170919235959. assume UTC timezone
-- duration_in_sec: the time to look back in second. if you want to look up for 1 minute result, just give 60. 3600 for 1 hour. and 24*3600 for 1 day.

declare
	myindex integer;
	machine_id character varying;
	var_current_value_stream character varying;
	var_current_stream character varying;
	var_current_machine_type character varying;
	var_current_property_name character varying;
	var_current_expected_value integer;
	var_current_target_name character varying;
	
	var_sqlquery varchar;
	var_connections character varying[];
	
	
	

begin
	
	SELECT dblink_get_connections() into var_connections;
	
	if var_connections is null then
		perform dblink_connect('ExternalConnection', 'host=twperf-dev.digital.sealedair.com user=twadmin password=twadmin dbname=iotmetrics');
	end if;
	
	myindex := 1;
	foreach machine_id in 
		array machine_ids 
	LOOP
		
		--RAISE NOTICE 'CURRENT MACHINE IS:%', machine_id;
		var_current_value_stream := value_streams[myindex];
		var_current_stream := streams[myindex];
		var_current_property_name := par_property_names[myIndex];
		var_current_expected_value := expected_values[myIndex];
		var_current_target_name := target_names[myIndex];


		raise notice 'var_current_value_stream: %', var_current_value_stream;
		raise notice 'var_current_stream: %', var_current_stream;
		raise notice 'var_current_machine_type: %', var_current_machine_type;
		raise notice 'var_current_properties: %', var_current_property_name;
		perform public.asset_statetimesum_shift(var_current_value_stream, var_current_stream, machine_id, var_current_property_name, var_current_expected_value, var_current_target_name, start_time_string, end_time_string, shiftname);
		myindex := myindex + 1;
	END LOOP;
end;

$function$
