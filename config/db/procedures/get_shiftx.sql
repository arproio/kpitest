CREATE OR REPLACE FUNCTION public.get_shiftx(line_name character varying, par_timestamp character varying)
 RETURNS TABLE(start_shift_weekday integer, starttime character varying, starttime_weekday integer, endtime character varying, endtime_weekday integer)
 LANGUAGE plpgsql
AS $function$


declare
	rec record;
	var_index integer;
	var_timestamp timestamp;
	var_base_timestamp timestamp;
	var_base_par_timestamp timestamp;
	var_starttime_timestamp timestamp;
	var_endtime_timestamp timestamp;
	var_weekday integer;
	var_timepart varchar;	
	
	var_id integer; 
	var_shiftinstanceid integer;
	var_shiftid integer;
	var_linename varchar; 
	var_shiftname varchar; 
	var_starttime varchar; 
	var_prev_shift_start varchar;
	var_endtime varchar;
	var_after_weekday integer;
	var_last_shift_index integer;
	var_lineid varchar;
	var_starttime_weekday integer;
	var_starttime_weekday_start integer;
	var_endtime_weekday integer;
	shifts_to_process integer;
	shift_details varchar[];
	var_shift_string varchar;
	var_shift_array varchar[];
	shift varchar;
	var_interval_string varchar;
	var_diff integer;
	
begin

	
	select split_part(line_name, '_', 1) into var_lineid;

	CREATE TEMP TABLE shifts(id int, shiftinstanceid int, shiftid int, linename varchar, shiftname varchar, starttime character varying, endtime character varying, weekday integer);
	
	-- Get all shifts for line and store into temp table
	var_index := 1;
	for rec in 
    select b.shiftstarttime, b.shiftendtime, b.weekday, b.shiftid, b.id, a.shiftname
    from public.see_shiftmaster a,public.see_shiftsettings b
    where a.id = b.shiftid 
    	and a.lineid = var_lineid
    	and b.shiftstarttime <> '' 
    	and b.shiftstarttime is not null 
    	and b.shiftendtime <> '' 
    	and b.shiftendtime is not null
	order by b.weekday, b.shiftstarttime
	LOOP
		insert into shifts(id, shiftinstanceid, shiftid, linename, shiftname, starttime, endtime, weekday)
		values(var_index, rec.id, rec.shiftid, line_name, rec.shiftname, rec.shiftstarttime, rec.shiftendtime, rec.weekday);	
		
		var_index := var_index + 1;
	end LOOP;
	

	var_timestamp := to_timestamp(par_timestamp,'YYYYMMDDHH24MISS');
	var_base_timestamp := to_timestamp('20170101000000','YYYYMMDDHH24MISS');
	var_weekday := cast (to_char(var_timestamp, 'd') as int);
	var_timepart := to_char(var_timestamp,'HH24:MI:SS');
	
	
	if var_weekday = 1 then
    		var_weekday := 7;
    	else
        	var_weekday := (var_weekday - 1);
    	end if;
    var_interval_string := var_weekday ||' day '|| var_timepart;
	var_base_par_timestamp := var_base_timestamp + interval '1 day' * var_weekday + var_timepart::time;
--	raise notice 'var_base_par_timestamp: %', var_base_par_timestamp;
--    	raise notice 'var_weekday: %', var_weekday;
--	raise notice 'var_timepart: %', var_timepart;
--	raise notice 'var_index: %', var_index;
	shifts_to_process := 0;
	
	for rec in 
		select a.starttime as astart, a.endtime, a.weekday as awd, b.starttime as bstart, b.weekday as bwd 
		from (select row_number() over (order by  shifts.weekday, shifts.starttime) as idx, id, shifts.starttime, shifts.endtime, shifts.weekday from shifts) a,
			 (select row_number() over (order by  shifts.weekday, shifts.starttime) as idx, id, shifts.starttime, shifts.endtime, shifts.weekday from shifts) b
		where
			case when a.id = var_index-1 then 
				b.id = 1
			else
				b.id = a.id + 1
			end
			and
			case when a.weekday > b.weekday then
				case when var_weekday >= a.weekday then
					a.weekday <= var_weekday and var_weekday <= 7
				else
					1 <= var_weekday and var_weekday <= b.weekday
				end
			else
				var_weekday between a.weekday and b.weekday
			end
	LOOP
		--raise notice 'rec: %', rec;
		shifts_to_process := shifts_to_process + 1;
		shift_details[shifts_to_process] := ARRAY[rec.astart,rec.endtime,rec.awd::varchar,rec.bstart,rec.bwd::varchar]; 


	end loop;
	
--	raise notice 'shifts_to_process: %', shifts_to_process;
--	raise notice 'shift_details: %', shift_details;
	if shifts_to_process = 1 then
		var_shift_string := shift_details[shifts_to_process];
		var_shift_array := string_to_array(substring(var_shift_string from 2 for (char_length(var_shift_string) -2)), ',');
		var_prev_shift_start := var_shift_array[1];
		var_starttime := var_shift_array[2];
		var_starttime_weekday_start := var_shift_array[3];
		var_endtime := var_shift_array[4];
		var_endtime_weekday := var_shift_array[5];
		
		if var_prev_shift_start > var_starttime then
	
			if var_starttime_weekday_start = 7 then
				var_starttime_weekday := 1;
			else
				var_starttime_weekday := var_starttime_weekday + 1;
			end if;
		else
			var_starttime_weekday := var_starttime_weekday_start;
		end if;
	else 
		
		foreach shift in array shift_details LOOP
			
			--raise notice 'shift: %', shift;
			var_shift_array := string_to_array(substring(shift from 2 for (char_length(shift) -2)), ',');
			var_prev_shift_start := var_shift_array[1];
			var_starttime := var_shift_array[2];
			var_starttime_weekday_start := var_shift_array[3];
			var_endtime := var_shift_array[4];
			var_endtime_weekday := var_shift_array[5];
			
			if var_prev_shift_start > var_starttime then
	
				if var_starttime_weekday_start = 7 then
					var_starttime_weekday := 1;
				else
					var_starttime_weekday := var_starttime_weekday_start + 1;
				end if;
			else
				var_starttime_weekday := var_starttime_weekday_start;
			end if;
			
			
			if var_starttime_weekday > var_endtime_weekday then
			
				var_starttime_timestamp := var_base_timestamp + interval '1 day' * var_starttime_weekday + var_starttime::time;
				
				var_diff := 7 - var_starttime_weekday;
				var_diff := var_diff + var_endtime_weekday; 
				
				var_endtime_timestamp := var_base_timestamp + interval '1 day' * var_diff + var_endtime::time;
					
				if var_base_par_timestamp >= var_starttime_timestamp and var_base_par_timestamp < var_endtime_timestamp then
					EXIT;
				end if;
				
			
			elseif var_starttime_weekday < var_endtime_weekday then
				var_starttime_timestamp := var_base_timestamp + interval '1 day' * var_starttime_weekday + var_starttime::time;
				var_endtime_timestamp := var_base_timestamp + interval '1 day' * var_endtime_weekday + var_endtime::time;
				
				if var_base_par_timestamp >= var_starttime_timestamp and var_base_par_timestamp < var_endtime_timestamp then
					EXIT;
				end if;
			else
			
				if var_starttime > var_endtime then
					
					var_diff := var_endtime_weekday + 7;
					var_starttime_timestamp := var_base_timestamp + interval '1 day' * var_starttime_weekday + var_starttime::time;
					var_endtime_timestamp := var_base_timestamp + interval '1 day' * var_diff + var_endtime::time;
					
					if var_base_par_timestamp >= var_starttime_timestamp and var_base_par_timestamp < var_endtime_timestamp then
						EXIT;
					end if;
				else
					var_starttime_timestamp := var_base_timestamp + interval '1 day' * var_starttime_weekday + var_starttime::time;
					var_endtime_timestamp := var_base_timestamp + interval '1 day' * var_endtime_weekday + var_endtime::time;
					
					if var_base_par_timestamp >= var_starttime_timestamp and var_base_par_timestamp < var_endtime_timestamp then
						EXIT;
					end if;
				
				end if;
			end if;
			
		end LOOP;
		
	end if;
		
		

	
--	raise notice 'var_prev_shift_start: %', var_prev_shift_start;
--	raise notice 'var_starttime: %', var_starttime;
--	raise notice 'var_starttime_weekday first: %', var_starttime_weekday;
--	
--	raise notice 'var_endtime: %', var_endtime;
--	raise notice 'var_endtime_weekday: %', var_endtime_weekday;
	

	
	START_SHIFT_WEEKDAY := var_starttime_weekday_start;
	STARTTIME := var_starttime;
	STARTTIME_WEEKDAY := var_starttime_weekday;
	ENDTIME := var_endtime;
	ENDTIME_WEEKDAY := var_endtime_weekday;
	
	drop table if exists shifts;
	return next;
	

end;

$function$
