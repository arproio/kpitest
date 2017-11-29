CREATE OR REPLACE FUNCTION public.asset_alarmtimesum_batch_realtime(dailyshiftid character varying, shiftid character varying, shiftname character varying, kpi_date character varying, start_time_string character varying, end_time_string character varying, machine_ids character varying[], machine_types character varying[], value_streams character varying[], streams character varying[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
declare
	myindex integer;
	machine_id character varying;
	var_current_value_stream character varying;
	var_current_stream character varying;
	var_current_machine_type character varying;
	var_current_properties character varying[];
	var_sqlquery varchar;
	var_connections character varying[];
	myTOTALCOUNT integer;
	myREJECTCOUNT integer;
	is_countable boolean;
BEGIN
	--RAISE NOTICE 'INPUT ARRAY IS:%', machine_ids;
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
		var_current_machine_type := machine_types[myindex];
		select properties into var_current_properties from public.machine_type_properties where machine_type = var_current_machine_type;


		raise notice 'var_current_value_stream: %', var_current_value_stream;
		raise notice 'var_current_stream: %', var_current_stream;
		raise notice 'var_current_machine_type: %', var_current_machine_type;
		raise notice 'var_current_properties: %', var_current_properties;
		
		perform public.asset_alarmtimesum_realtime(var_current_value_stream, var_current_stream, machine_id, var_current_properties, start_time_string, end_time_string, shiftname);
		
		myindex := myindex + 1;
	END LOOP;
	
END;
$function$
