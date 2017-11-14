CREATE OR REPLACE FUNCTION public.asset_kpi_bytime_batch_hour(dailyshiftid character varying, shiftid character varying, shiftname character varying, kpi_date character varying, kpi_hour character varying, start_time_string character varying, end_time_string character varying, ideal_run_rate integer, machine_ids character varying[], machine_types character varying[], value_streams character varying[], streams character varying[], countable_machine_ids character varying[])
 RETURNS TABLE(totalcount integer, rejectcount integer)
 LANGUAGE plpgsql
AS $function$
declare
	myindex integer;
	machine_id character varying;
	var_current_value_stream character varying;
	var_current_stream character varying;
	var_current_machine_type character varying;
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
	
	TOTALCOUNT := 0;
	REJECTCOUNT := 0;
	
	myindex := 1;
	foreach machine_id in 
		array machine_ids 
	LOOP
		
		--RAISE NOTICE 'CURRENT MACHINE IS:%', machine_id;
		var_current_value_stream := value_streams[myindex];
		var_current_stream := streams[myindex];
		var_current_machine_type := machine_types[myindex];


		raise notice 'var_current_value_stream: %', var_current_value_stream;
		raise notice 'var_current_stream: %', var_current_stream;
		raise notice 'var_current_machine_type: %', var_current_machine_type;
		
		for myTOTALCOUNT, myREJECTCOUNT in
			select onemachine.totalcount, onemachine.rejectcount
			from asset_kpi_bytime_hour(var_current_value_stream, var_current_stream, machine_id, var_current_machine_type, start_time_string, end_time_string, ideal_run_rate, shiftname, kpi_date, kpi_hour) onemachine
		LOOP
		
			select machine_id = ANY (countable_machine_ids) into is_countable;
			
			
			
			if is_countable then
				TOTALCOUNT := TOTALCOUNT + myTOTALCOUNT;
			end if;
			
			REJECTCOUNT := REJECTCOUNT + myREJECTCOUNT;

		end LOOP;
		
		myindex := myindex + 1;
	END LOOP;
	
	raise notice 'TOTALCOUNT: %', TOTALCOUNT;
	raise notice 'REJECTCOUNT: %', REJECTCOUNT;
	
	
	return next;

END;
$function$
