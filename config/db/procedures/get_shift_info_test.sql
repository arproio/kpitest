CREATE OR REPLACE FUNCTION public.get_shift_info_test(line_name character varying, par_timestamp character varying)
 RETURNS TABLE(shiftinstanceid integer, shiftid integer, linename character varying, shiftname character varying, starttime character varying, endtime character varying, weekday character varying)
 LANGUAGE plpgsql
 STABLE
AS $function$


declare
	var_weekday integer;
	var_after_weekday integer;
	var_timepart varchar;
	
	var_starttime varchar;
	var_starttime_return varchar;
	
	var_endtime varchar;
	var_endtime_return varchar;
	
	var_shiftname_return varchar;
	var_shiftid_return integer;
	var_id_return integer;
	var_linename_return varchar;
	var_shift_start_time_return varchar;
	
	var_timestamp_1d_earlier timestamp;
	var_shift_end_time_return varchar;
	var_timestamp_1d_after timestamp;
	weekday_array varchar array[7];
	var_weekday_return varchar;
	
	var_timestamp_1d_earlier_string varchar;
	var_timestamp_1d_after_string varchar;
	
	var_timestamp timestamp with time zone;
	var_day real;
	var_lineid varchar;
	var_starttime_weekday integer;
	var_endtime_weekday integer;
	
	var_starttime_string varchar;
	var_endtime_string varchar;
	var_start_day_diff integer;
	var_end_day_diff integer;
	var_timestamp_endtime timestamp;
	var_timestamp_starttime timestamp;
	
	
begin
	
	select split_part(line_name, '_', 1) into var_lineid;
	-- Extract Day of Week and Time from timestamp
	var_timestamp := to_timestamp(par_timestamp,'YYYYMMDDHH24MISS');
	var_weekday := cast (to_char(var_timestamp, 'd') as int);
	var_timepart := to_char(var_timestamp,'HH24:MI:SS');

	-- Adjust day of week
	if var_weekday = 1 then
    		var_weekday := 7;
    	else
        	var_weekday := (var_weekday - 1);
    	end if;
		
    	
    	
    select b.shiftstarttime, b.shiftendtime, b.weekday, b.shiftid, b.id, a.shiftname
    into var_starttime, var_endtime, var_starttime_weekday, var_shiftid_return, var_id_return, var_shiftname_return
    from public.see_shiftmaster a,public.see_shiftsettings b, public.see_clientassetmaster c
    where
    	a.id = b.shiftid 
    	and a.lineid = var_lineid
	and 
    	case when b.shiftstarttime::time > b.shiftendtime::time or b.shiftstarttime is null then
	    	case when (var_timepart::time < b.shiftstarttime::time or b.shiftstarttime is null) and var_weekday = 1 then 		    		
	    		b.weekday = 7
	    		and((var_timepart::time >= b.shiftstarttime::time and var_timepart::time <= '23:59:59'::time)
	    		or (var_timepart::time >= '00:00:00'::time and var_timepart::time < b.shiftendtime::time))
	    	when (var_timepart::time < b.shiftstarttime::time or b.shiftstarttime is null) and var_weekday <> 1 then	
	    		b.weekday = var_weekday-1
	    		and((var_timepart::time >= b.shiftstarttime::time and var_timepart::time <= '23:59:59'::time)
	    		or (var_timepart::time >= '00:00:00'::time and var_timepart::time < b.shiftendtime::time))
	    	else
	    		b.weekday = var_weekday
	    		and((var_timepart::time >= b.shiftstarttime::time and var_timepart::time <= '23:59:59'::time)
	    		or (var_timepart::time >= '00:00:00'::time and var_timepart::time < b.shiftendtime::time))
	    	end
    else
		b.weekday = var_weekday
		and (var_timepart::time >= b.shiftstarttime::time and var_timepart::time < b.shiftendtime::time) 
	end;
		
	raise notice 'var_timepart: %',var_timepart;
	raise notice 'var_weekday: %', var_weekday;

--	raise notice 'var_after_weekday: %', var_after_weekday;
--	raise notice 'var_starttime: %', var_starttime;
--	raise notice 'var_endtime: %', var_endtime;
--	raise notice 'var_shiftid_return: %', var_shiftid_return;
--	raise notice 'var_id_return: %', var_id_return;
--	raise notice 'var_shiftname_return: %', var_shiftname_return;

	if var_starttime is null or var_endtime is null then
	
		select shiftx.starttime, shiftx.starttime_weekday, shiftx.endtime, shiftx.endtime_weekday
		into var_starttime, var_starttime_weekday, var_endtime, var_endtime_weekday
		from public.get_shiftx(line_name, par_timestamp) shiftx;
		
		--get start date time
		var_start_day_diff := var_weekday - var_starttime_weekday;
		
		if var_start_day_diff < 0 then
			var_start_day_diff := var_start_day_diff + 7; 
		elseif var_start_day_diff = 0 then
			if var_starttime_weekday = var_endtime_weekday and var_starttime::time > var_endtime::time then
				var_start_day_diff := var_start_day_diff + 7;
			end if;
		end if;
		
		select var_timestamp - INTERVAL '1 day' * var_start_day_diff
    		into var_starttime_string;
    		
    		var_timestamp_starttime := to_timestamp(var_starttime_string,'YYYY-MM-DD HH24:MI:SS');
    		
    		var_shift_start_time_return := date_part('year', var_timestamp_starttime) ||''|| 
		to_char(date_part('month', var_timestamp_starttime), 'fm00')||''||
		to_char(date_part('day', var_timestamp_starttime), 'fm00') ||  to_char(var_starttime::time,'HH24MISS');
    		
    		--get end date time 
    		var_end_day_diff := var_endtime_weekday - var_weekday;
    		raise notice 'var_end_day_diff:% - % = %',var_endtime_weekday,var_weekday,var_end_day_diff;
    		if var_end_day_diff < 0 then
			var_end_day_diff := var_end_day_diff + 7;
		elseif var_end_day_diff = 0 then
			if var_starttime_weekday = var_endtime_weekday and var_starttime::time > var_endtime::time then
				raise notice 'HERE';
				raise notice '% - %', var_starttime::time, var_endtime::time;
				var_end_day_diff := var_end_day_diff + 7;
			end if;
		end if;
    		raise notice 'var_end_day_diff after: %', var_end_day_diff;

		select var_timestamp + INTERVAL '1 day' * var_end_day_diff
    		into var_endtime_string;
		
    		
    		var_timestamp_endtime := to_timestamp(var_endtime_string,'YYYY-MM-DD HH24:MI:SS');
    		raise notice 'var_timestamp_endtime: %', var_timestamp_endtime;
		var_shift_end_time_return := date_part('year', var_timestamp_endtime) ||''|| 
		to_char(date_part('month', var_timestamp_endtime), 'fm00')||''||
		to_char(date_part('day', var_timestamp_endtime), 'fm00') || to_char(var_endtime::time,'HH24MISS');
		
		var_shiftname_return := 'ShiftX';
		var_shiftid_return := null;
		var_id_return := null;
		
		
	else
		-- Get Start Date Time
		if var_weekday <> var_starttime_weekday then
			raise notice 'WEEKDAYS NOT EQUAL';
			select var_timestamp - INTERVAL '24 hour' into var_timestamp_1d_earlier_string;
			
			raise notice 'var_timestamp_1d_earlier_string: %',var_timestamp_1d_earlier_string;
			
			var_timestamp_1d_earlier := to_timestamp(var_timestamp_1d_earlier_string,'YYYY-MM-DD HH24:MI:SS');
			
			var_shift_start_time_return := date_part('year', var_timestamp_1d_earlier) ||''|| 
			to_char(date_part('month', var_timestamp_1d_earlier), 'fm00')||''||
			to_char(date_part('day', var_timestamp_1d_earlier), 'fm00') ||  to_char(var_starttime::time,'HH24MISS');

		else
			raise notice 'here';
				

			var_shift_start_time_return := date_part('year', var_timestamp) ||''|| 
			to_char(date_part('month', var_timestamp), 'fm00')||''||
			to_char(date_part('day', var_timestamp), 'fm00') ||  to_char(var_starttime::time,'HH24MISS');
		end if;
		
		-- Get End Date Time
		if var_weekday = var_starttime_weekday and var_timepart::time > var_endtime::time then
		 				
				select var_timestamp + INTERVAL '24 hour' into var_timestamp_1d_after_string;
				raise notice 'var_timestamp_1d_after_string: %', var_timestamp_1d_after_string;
				
 				var_timestamp_1d_after := to_timestamp(var_timestamp_1d_after_string,'YYYY-MM-DD HH24:MI:SS');
				
				
				
				var_shift_end_time_return := date_part('year', var_timestamp_1d_after) ||''|| 
				to_char(date_part('month', var_timestamp_1d_after), 'fm00')||''||
				to_char(date_part('day', var_timestamp_1d_after), 'fm00') ||  to_char(var_endtime::time,'HH24MISS');

		
	 	else
			var_shift_end_time_return := date_part('year', var_timestamp) ||''|| 
			to_char(date_part('month', var_timestamp), 'fm00')||''||
			to_char(date_part('day', var_timestamp), 'fm00') || to_char(var_endtime::time,'HH24MISS');
		end if;
		
		
	end if;
	
	
	select ('{"Mon","Tu","W", "Th", "F", "Sa", "Sun"}')
    into weekday_array; 
	var_weekday_return := weekday_array[var_starttime_weekday];
		
	
	SHIFTINSTANCEID := var_id_return;
	SHIFTID := var_shiftid_return;
	LINENAME := line_name;
	SHIFTNAME := var_shiftname_return;
	STARTTIME := var_shift_start_time_return;
	ENDTIME := var_shift_end_time_return;
	WEEKDAY := var_weekday_return;
	
	RETURN NEXT;
		
end;

$function$
