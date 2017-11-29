CREATE OR REPLACE FUNCTION public.get_all_shifts_byline(line_name character varying)
 RETURNS TABLE(shiftinstanceid integer, shiftid integer, linename character varying, shiftname character varying, starttime character varying, endtime character varying, weekday character varying)
 LANGUAGE plpgsql
 STABLE
AS $function$


declare
	rec record;
	var_lineid varchar;
	var_current_date date;
	var_weekday integer;
	var_diff integer;
	var_temp_startdate timestamp;
	var_shift_start_time_return varchar;
	var_temp_enddate timestamp;
	var_shift_end_time_return varchar;
	
begin
	var_current_date := current_date;
	var_weekday := cast (to_char(var_current_date, 'd') as int);

	-- Adjust day of week
	if var_weekday = 1 then
    		var_weekday := 7;
    	else
        	var_weekday := (var_weekday - 1);
    	end if;
    	
	select split_part(line_name, '_', 1) into var_lineid;
	
	raise notice 'var_lineid: %', var_lineid;
	
	for rec in 
    select b.shiftstarttime, b.shiftendtime, b.weekday, b.shiftid, b.id, a.shiftname
    from public.see_shiftmaster a,public.see_shiftsettings b
    where a.id = b.shiftid 
    	and a.lineid = var_lineid
	and b.shiftstarttime is not null
	and b.shiftstarttime <> ''
	order by b.weekday, shiftname
	LOOP
		var_diff := rec.weekday - var_weekday;
		select var_current_date + INTERVAL '1 day' * var_diff
		into var_temp_startdate;	
	
		var_shift_start_time_return := date_part('year', var_temp_startdate) ||''|| 
		to_char(date_part('month', var_temp_startdate), 'fm00')||''||
		to_char(date_part('day', var_temp_startdate), 'fm00') || to_char(rec.shiftstarttime::time,'HH24MISS');
		
		if rec.shiftstarttime > rec.shiftendtime then
			select var_temp_startdate + INTERVAL '1 day'
			into var_temp_enddate;
		else 
			var_temp_enddate := var_temp_startdate; 
		end if;
		
		var_shift_end_time_return := date_part('year', var_temp_enddate) ||''|| 
		to_char(date_part('month', var_temp_enddate), 'fm00')||''||
		to_char(date_part('day', var_temp_enddate), 'fm00') || to_char(rec.shiftendtime::time,'HH24MISS');
		
		SHIFTINSTANCEID := rec.id;
		SHIFTID := rec.shiftid;
		LINENAME := line_name;
		SHIFTNAME := rec.shiftname;
		STARTTIME := var_shift_start_time_return;
		ENDTIME := var_shift_end_time_return;
		WEEKDAY := rec.weekday;
		
		RETURN NEXT;
	end LOOP;
	
	return;

end;

$function$
