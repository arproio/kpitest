CREATE OR REPLACE FUNCTION public.asset_kpi_bytime_batch_minute(dailyshiftid character varying, shiftid character varying, shiftname character varying, kpi_date character varying, kpi_hour character varying, kpi_minute character varying, minutes integer, ideal_run_rate integer, machine_ids character varying[], machine_types character varying[], value_streams character varying[], streams character varying[])
 RETURNS void
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
	
	var_start_time_minute character varying;
	var_start_time_hour character varying;
	var_start_time_date character varying;
	
	var_end_time_minute character varying;
	var_end_time_hour character varying;
	var_end_time_date character varying;
	
	start_time_string character varying;
	end_time_string character varying;
	end_time_timestamp timestamp with time zone;
	minuteIndex integer;
	

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


		raise notice 'var_current_value_stream: %', var_current_value_stream;
		raise notice 'var_current_stream: %', var_current_stream;
		raise notice 'var_current_machine_type: %', var_current_machine_type;
		
		var_start_time_minute := kpi_minute; 
		var_start_time_hour := kpi_hour;
		var_start_time_date := kpi_date;
		
		var_end_time_hour := kpi_hour;
		var_end_time_date := kpi_date;
		
		minuteIndex := 0;
		while minuteIndex < minutes LOOP 
			start_time_string := var_start_time_date || var_start_time_hour || var_start_time_minute || '00';
			
			var_end_time_minute := to_char(var_start_time_minute::int + 1, 'fm00');
		
			if var_end_time_minute = '60' then
				
				var_end_time_minute := '00';
				var_end_time_hour := to_char(var_start_time_hour::int + 1, 'fm00'); 
				
				if var_end_time_hour = '24' then 
				
					var_end_time_hour = '00';
					end_time_timestamp := to_timestamp(var_start_time_date,'YYYYMMDDHH') + INTERVAL '1 day';
					var_end_time_date := to_char(date_part('year', end_time_timestamp), 'fm0000') || to_char(date_part('month', end_time_timestamp), 'fm00') || to_char(date_part('day', end_time_timestamp), 'fm00');
					--select to_timestamp(to_timestamp(kpi_date,'YYYYMMDDHH') + INTERVAL '1 day', 'YYYYMMDDHH') into kpi_date;
					
				end if;
				
			end if;
			
			raise notice 'var_end_time_date: %', var_end_time_date;
			raise notice 'var_end_time_hour: %', var_end_time_hour;
			raise notice 'var_end_time_minute: %', var_end_time_minute;
			
			end_time_string := var_end_time_date || var_end_time_hour || var_end_time_minute || '00';
			
			raise notice 'start_time_string: %', start_time_string;
			raise notice 'end_time_string: %', end_time_string;
			
			perform public.asset_kpi_bytime_minute(var_current_value_stream, var_current_stream, machine_id, var_current_machine_type, start_time_string, end_time_string, ideal_run_rate, shiftname, var_start_time_date, var_start_time_hour, var_start_time_minute);
			
			var_start_time_minute := var_end_time_minute;
			var_start_time_hour := var_end_time_hour;
			var_start_time_date := var_end_time_date;
			minuteIndex := minuteIndex + 1;
		end loop;	
		myindex := myindex + 1;
	END LOOP;

END;
    $function$
