CREATE OR REPLACE FUNCTION public.get_last_shift(line_name character varying, par_timestamp character varying)
 RETURNS TABLE(shiftinstanceid integer, shiftid integer, linename character varying, shiftname character varying, starttime character varying, endtime character varying, weekday character varying)
 LANGUAGE plpgsql
AS $function$


declare
	rec record;
	var_index integer;
	var_timestamp timestamp;
	var_weekday integer;
	var_timepart varchar;	
	
	var_id integer; 
	var_shiftinstanceid integer;
	var_shiftid integer;
	var_linename varchar; 
	var_shiftname varchar; 
	var_starttime varchar; 
	var_endtime varchar;
	var_after_weekday integer;
	var_last_shift_index integer;
	var_lineid varchar;
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
	var_weekday := cast (to_char(var_timestamp, 'd') as int);
	var_timepart := to_char(var_timestamp,'HH24:MI:SS');
	raise notice 'var_weekday: %', var_weekday;
	raise notice 'var_timepart: %', var_timepart;
	raise notice 'var_index: %', var_index;
	
	-- Adjust day of week
	if var_weekday = 1 then
    		var_weekday := 7;
    	else
        	var_weekday := (var_weekday - 1);
    	end if;
		
    select a.id, a.shiftinstanceid, a.shiftid, a.linename, a.shiftname, a.starttime, a.endtime, a.weekday
    into var_id, var_shiftinstanceid, var_shiftid, var_linename, var_shiftname, var_starttime, var_endtime, var_after_weekday
    from shifts a
    where
    	case when a.starttime::time > a.endtime::time or a.starttime is null then
	    	case when (var_timepart::time < a.starttime::time or a.starttime is null) and var_weekday = 1 then 		    		
	    		a.weekday = 7
	    		and((var_timepart::time >= a.starttime::time and var_timepart::time <= '23:59:59'::time)
	    		or (var_timepart::time >= '00:00:00'::time and var_timepart::time < a.endtime::time))
	    	when (var_timepart::time < a.starttime::time or a.starttime is null) and var_weekday <> 1 then	
	    		a.weekday = var_weekday-1
	    		and((var_timepart::time >= a.starttime::time and var_timepart::time <= '23:59:59'::time)
	    		or (var_timepart::time >= '00:00:00'::time and var_timepart::time < a.endtime::time))
	    	else
	    		a.weekday = var_weekday
	    		and((var_timepart::time >= a.starttime::time and var_timepart::time <= '23:59:59'::time)
	    		or (var_timepart::time >= '00:00:00'::time and var_timepart::time < a.endtime::time))
	    	end
    else
		a.weekday = var_weekday
		and (var_timepart::time >= a.starttime::time and var_timepart::time < a.endtime::time) 
	end;
	
	-- Time is not on shift
	if var_id is null then
		select a.shiftinstanceid, a.shiftid, a.linename, a.shiftname, a.starttime, a.endtime, a.weekday
		into var_shiftinstanceid, var_shiftid, var_linename, var_shiftname, var_starttime, var_endtime, var_after_weekday
		from (select row_number() over (order by  shifts.weekday, shifts.starttime) as idx, id, shifts.shiftinstanceid, shifts.shiftid, shifts.linename, shifts.shiftname, shifts.starttime, shifts.endtime, shifts.weekday from shifts) a,
			 (select row_number() over (order by  shifts.weekday, shifts.starttime) as idx, id, shifts.shiftinstanceid, shifts.shiftid, shifts.linename, shifts.shiftname, shifts.starttime, shifts.endtime, shifts.weekday from shifts) b
		where
		case when a.id = var_index-1 then 
			b.id = 1
		else
			b.id = a.id + 1
		end
		and
		case when a.endtime::time > b.starttime::time or a.endtime is null then
	    		case when (var_timepart::time < a.endtime::time or a.endtime is null) and var_weekday = 1 then 		    		
		    		a.weekday = 7
		    		and((var_timepart::time >= a.endtime::time and var_timepart::time <= '23:59:59'::time)
		    		or (var_timepart::time >= '00:00:00'::time and var_timepart::time < b.starttime::time))
		    	when (var_timepart::time < a.endtime::time or a.endtime is null) and var_weekday <> 1 then	
		    		a.weekday = var_weekday - 1
		    		and((var_timepart::time >= a.endtime::time and var_timepart::time <= '23:59:59'::time)
		    		or (var_timepart::time >= '00:00:00'::time and var_timepart::time < b.starttime::time))
		    	else
		    		a.weekday = var_weekday
		    		and((var_timepart::time >= a.endtime::time and var_timepart::time <= '23:59:59'::time)
		    		or (var_timepart::time >= '00:00:00'::time and var_timepart::time < b.starttime::time))
		    	end
	    else
			a.weekday = var_weekday
			and (var_timepart::time >= a.endtime::time and var_timepart::time < b.starttime::time) 
		end;
		
	else
	
	--	raise notice 'var_starttime: %', var_starttime;
	--	raise notice 'var_endtime: %', var_endtime;
		raise notice 'var_after_weekday: %', var_after_weekday;
	--	raise notice 'var_id: %', var_id;
	--	raise notice 'var_shiftinstanceid: %', var_shiftinstanceid;
	--	raise notice 'var_shiftid: %', var_shiftid;
	--	raise notice 'var_linename: %', var_linename;
	--	raise notice 'var_shiftname: %', var_shiftname;
		var_last_shift_index := var_id - 1;
	
		if var_last_shift_index = 0 then
			var_last_shift_index = var_index - 1;
		end if;
		raise notice 'var_last_shift_index: %', var_last_shift_index;
	
		select a.shiftinstanceid, a.shiftid, a.linename, a.shiftname, a.starttime, a.endtime, a.weekday
	    into var_shiftinstanceid, var_shiftid, var_linename, var_shiftname, var_starttime, var_endtime, var_after_weekday
	    from shifts a
	    where id = var_last_shift_index;
	end if;   
	
	-- raise notice 'var_shiftname: %', var_shiftname;
	SHIFTINSTANCEID := var_shiftinstanceid;
	SHIFTID := var_shiftid;
	LINENAME := line_name;
	SHIFTNAME := var_shiftname;
	STARTTIME := var_starttime;
	ENDTIME := var_endtime;
	WEEKDAY := var_after_weekday;
	
	drop table if exists shifts;
	return next;
	

end;

$function$
