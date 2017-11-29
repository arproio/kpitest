CREATE OR REPLACE FUNCTION public.asset_alarmtimesum_shift(value_stream_name character varying, stream_name character varying, machine_id character varying, property_names character varying[], start_time_string character varying, end_time_string character varying, shiftname character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
-- value_stream_name: this is the associated value stream on Thing general info page.
-- machine_id: this is the Thing name in Thingworx
-- end_time_string: the time to check in string with format: YYYYMMDDHH24MISS, for example:20170919235959. assume UTC timezone
-- duration_in_sec: the time to look back in second. if you want to look up for 1 minute result, just give 60. 3600 for 1 hour. and 24*3600 for 1 day.

declare
	var_end_time timestamp with time zone;
	var_start_time timestamp with time zone;
	duration_in_sec integer;
	var_last_time timestamp with time zone;
	var_last_value character varying;
	time_in_sec real;
	values_string varchar;
	myIndex integer;
	var_last_val varchar;
	property varchar;
	update_date timestamptz;
	var_date_part varchar;
	var_sqlquery varchar;
	var_connections character varying[];
	rec RECORD;
	prerec RECORD;
	
	
	

begin
	
	
	select into var_end_time (to_timestamp(end_time_string,'YYYYMMDDHH24MISS')::timestamp with time zone) ;
	select into var_start_time (to_timestamp(start_time_string,'YYYYMMDDHH24MISS')::timestamp with time zone) ;
	duration_in_sec := extract('epoch' from (var_end_time - var_start_time));
	select into var_date_part substring(start_time_string,1,8);
	select now() at time zone 'utc' into update_date;

	IF duration_in_sec <=0 then
		RETURN;
	END IF;

	values_string := '';
	
	
	myIndex := 1;
	foreach property in
		array property_names
	LOOP
		if stream_name = '' then
			var_last_val := '0';
		
			select property_value from value_stream
			into var_last_val
			where entity_id=value_stream_name and source_id=machine_id and property_name=property
			and time <= var_start_time
			order by time desc limit 1;
			
			var_last_time := var_start_time;	-- setup start time in loop.
	
			time_in_sec = 0.0;
	
			for rec in 
				select time, property_value from value_stream 
				where entity_id=value_stream_name and source_id=machine_id and property_name=property
				and time < var_end_time and time > var_start_time
				order by time
			LOOP
				if var_last_val = 'true' then
					time_in_sec := extract(epoch from rec.time - var_last_time) + time_in_sec;
				end if;
				
				var_last_time := rec.time;
				var_last_val := rec.property_value;
			
			END LOOP;
			
			if var_last_val = 'true' then
				time_in_sec := extract(epoch from var_end_time - var_last_time) + time_in_sec;
			end if;
	--		raise notice 'shiftname: %', shiftname;
	--		raise notice 'machine_id: %', machine_id;
	--		raise notice 'var_start_time: %', var_start_time;
	--		raise notice 'var_end_time: %', var_end_time;
	--		raise notice 'update_date: %', update_date;
	--		raise notice 'var_date_part: %', var_date_part;
	--		raise notice 'property: %', property;
	--		raise notice 'time_in_sec: %', time_in_sec;
			raise notice 'var_last_val: %', var_last_val;
			raise notice 'var_last_time: %', var_last_time;
			
			if myIndex = 1 then
				values_string := values_string || '(''' || shiftname || ''',''' || machine_id || ''','''||var_start_time|| ''',''' || var_end_time || ''',''' || update_date || ''',''' || var_date_part||''',''' || property || ''','|| time_in_sec||')';
			else
				values_string := values_string || ', (''' || shiftname || ''',''' || machine_id || ''','''||var_start_time|| ''',''' || var_end_time || ''',''' || update_date ||''',''' || var_date_part||''',''' || property || ''','|| time_in_sec||')';
			end if;
		else
		
			select field_values->>property from stream 
			into var_last_val
			where entity_id=stream_name and source_id=machine_id
			and time <= var_start_time
			order by time desc limit 1;
			
			var_last_time := var_start_time;	-- setup start time in loop.
	
			time_in_sec = 0.0;
			for rec in
				select field_values->>property from stream 
				where entity_id=stream_name and source_id=machine_id
				and time < var_end_time and time > var_start_time
				order by time
			LOOP
				if var_last_val = 'true' then
					time_in_sec := extract(epoch from rec.time - var_last_time) + time_in_sec;
				end if;
				
				var_last_time := rec.time;
				var_last_val := rec.property_value;
			
			END LOOP;
			
			if var_last_val = 'true' then
				time_in_sec := extract(epoch from var_end_time - var_last_time) + time_in_sec;
			end if;
			
			if myIndex = 1 then
				values_string := values_string || '(''' || shiftname || ''',''' || machine_id || ''','''||var_start_time|| ''',''' || var_end_time || ''',''' || update_date || ''',''' || var_date_part||''',''' || property || ''','|| time_in_sec||')';
			else
				values_string := values_string || ', (''' || shiftname || ''',''' || machine_id || ''','''||var_start_time|| ''',''' || var_end_time || ''',''' || update_date ||''',''' || var_date_part||''',''' || property || ''','|| time_in_sec||')';
			end if;
		
		end if;
		myIndex := myIndex + 1;
	end loop;
	
	
	raise notice 'values_string: %', values_string;
	
	
	
	var_sqlquery := 'insert into cognipro.alarm_state_timesum_shift(shiftname,machine_id,starttime,endtime,update_date,date_string,property_name,property_sum) VALUES' || values_string; 
												
	raise notice 'var_sqlquery: %', var_sqlquery;
	perform dblink_exec('ExternalConnection', var_sqlquery);

end;

$function$
