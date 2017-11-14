CREATE OR REPLACE FUNCTION public.asset_kpi_bytime_vr8600e(value_stream_name character varying, machine_id character varying, start_time_string character varying, end_time_string character varying, shift_start_time character varying, ideal_run_rate integer, capacity_potential_window real, throughput_window real, efficiency_window real, availability_window real)
 RETURNS TABLE(average real, cyclecount integer, productcount integer, throughput real, availability real, capacitypotential real, efficiency real, starttime character varying, endtime character varying, machineid character varying)
 LANGUAGE plpgsql
 STABLE
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
	rec RECORD;
	prerec RECORD;
	
	available_runtime_in_sec	real;
	available_stoptime_in_sec	real;

	var_time_gap real;
	var_speedcpm_last  real;	
	var_average_return	real;	-- return value
	var_total  real;
	
	var_count_last	integer;
	var_count_end	integer;
	var_count_return	integer;	-- return value
	var_count_efficiency integer;
	var_productcount_return	integer;	-- return value
	var_productcount_throughput integer;
	var_productcount_capacity_potential integer;
	var_productcount_efficiency integer;
	var_throughput_return	real;		-- return value
	var_availability_return real;		-- return value

	var_idearunrate	integer;
	var_capacitypotential_return	real;	-- return value
	var_efficiency_return	real;		-- return value
	
	var_capacity_potential_start_time timestamp with time zone;
	var_throughput_start_time timestamp with time zone;
	var_efficiency_start_time timestamp with time zone;
	var_availability_start_time timestamp with time zone;

begin
	select into var_end_time (to_timestamp(end_time_string,'YYYYMMDDHH24MISS')::timestamp with time zone) ;
	select into var_start_time (to_timestamp(start_time_string,'YYYYMMDDHH24MISS')::timestamp with time zone) ;
	duration_in_sec := extract('epoch' from (var_end_time - var_start_time));

	IF duration_in_sec <=0 then
		AVERAGE := 0.0;
		CYCLECOUNT := 0;
		PRODUCTCOUNT := 0;
		THROUGHPUT := 0.0;
		AVAILABILITY := 0.0;
		CAPACITYPOTENTIAL := 0.0;
		EFFICIENCY := 0.0;
		STARTTIME := start_time_string;
		ENDTIME := end_time_string;
		MACHINEID := machine_id;
		RETURN NEXT;

		RETURN;
	END IF;
	
	----------------------------- Set up Windows --------------------------------
		
	select var_end_time - INTERVAL '1 second' * capacity_potential_window
    into var_capacity_potential_start_time;
    
    select var_end_time - INTERVAL '1 second' * throughput_window
    into var_throughput_start_time;
    
    select var_end_time - INTERVAL '1 second' * efficiency_window
    into var_efficiency_start_time;
    
    select var_end_time - INTERVAL '1 second' * availability_window
    into var_availability_start_time;
	
    
	raise notice 'var_capacity_potential_start_time: %', var_capacity_potential_start_time;
	raise notice 'var_throughput_start_time: %', var_throughput_start_time;
	raise notice 'var_efficiency_start_time: %', var_efficiency_start_time;
	raise notice 'var_availability_start_time: %', var_availability_start_time;
	
	
	
	
	-- raise notice 'Start from:%', now();
	-- Caution1:    all entered time must be UTC time.
	-- Caution2:    all msc will be cut off, 000 will be the default.
	-- Caution3:    in all query, end_time will be included, start_time will NOT be included.
	-- raise notice 'end time:%', var_end_time;
	-- raise notice 'start time:%', var_start_time;

	----------------------------    Average Calculation ---------------
	-- shift number will NOT be calculated here.
	-- shift start time will NOT be calculated here
	-- duration_in_sec equals planned production time. it should be calculated before invoke.
	-- property_name: param_speedcpm
	var_speedcpm_last := 0.0;
	for prerec in 
	select time, property_value from value_stream
	where entity_id=value_stream_name and source_id = machine_id and property_name='param_speedcpm'
	and time <= var_start_time
	order by time desc limit 1
	LOOP
	var_speedcpm_last := prerec.property_value;
	END LOOP;

	var_last_time := var_start_time;
	var_total := 0.0;
	for rec in 
	select time, property_value from value_stream
	where entity_id=value_stream_name and source_id = machine_id and property_name='param_speedcpm'
	and time < var_end_time and time > var_start_time
	order by time
	LOOP
	var_time_gap := extract(epoch from rec.time - var_last_time);
	var_total := var_time_gap * var_speedcpm_last + var_total;

	var_last_time := rec.time;
	var_speedcpm_last := rec.property_value; -- need string to real convertion?
	END LOOP;

	var_total := extract(epoch from var_end_time - var_last_time) * var_speedcpm_last + var_total;
	-- RAISE NOTICE 'Final total:(%) and average:(%)', var_total_distince, var_total_distince / duration_in_sec;

	var_average_return := var_total / duration_in_sec;

	----------------------------- cycle count -------------------------------------
	-- Property_Name: param_lifetimecycle
	var_count_last := 0;
	for prerec in 
	select time, property_value from value_stream
	where entity_id=value_stream_name and source_id = machine_id and property_name='param_lifetimecycle'
	and time <= var_start_time
	order by time desc limit 1
	LOOP
	var_count_last := prerec.property_value;
	END LOOP;

	var_count_end := var_count_last;
	for rec in 
	select time, property_value from value_stream
	where entity_id=value_stream_name and source_id = machine_id and property_name='param_lifetimecycle'
	and time < var_end_time and time > var_start_time
	order by time desc limit 1
	LOOP
	var_count_end := rec.property_value; -- need string to real convertion?
	END LOOP;
	var_count_return = var_count_end - var_count_last;

	----------------------------- product count -------------------------------------
	-- Property_Name: param_productcount
	var_count_last := 0;
	for prerec in 
	select time, property_value from value_stream
	where entity_id=value_stream_name and source_id = machine_id and property_name='param_productcount'
	and time <= var_start_time
	order by time desc limit 1
	LOOP
	var_count_last := prerec.property_value;
	END LOOP;

	var_count_end := var_count_last;
	for rec in 
	select time, property_value from value_stream
	where entity_id=value_stream_name and source_id = machine_id and property_name='param_productcount'
	and time < var_end_time and time > var_start_time
	order by time desc limit 1
	LOOP
	var_count_end := rec.property_value; -- need string to real convertion?
	END LOOP;
	var_productcount_return := var_count_end - var_count_last;

	----------------------------- throughput -------------------------------------
	if throughput_window <= 0.0 then
		var_throughput_return := 0.0;
	else
		var_count_last := 0;
		for prerec in 
		select time, property_value from value_stream
		where entity_id=value_stream_name and source_id = machine_id and property_name='param_productcount'
		and time <= var_throughput_start_time
		order by time desc limit 1
		LOOP
		var_count_last := prerec.property_value;
		END LOOP;
	
		var_count_end := var_count_last;
		for rec in 
		select time, property_value from value_stream
		where entity_id=value_stream_name and source_id = machine_id and property_name='param_productcount'
		and time < var_end_time and time > var_throughput_start_time
		order by time desc limit 1
		LOOP
		var_count_end := rec.property_value; -- need string to real convertion?
		END LOOP;
		
		raise notice 'var_count_end: %', var_count_end;
		raise notice 'var_count_last: %', var_count_last;
		var_productcount_throughput := var_count_end - var_count_last;
		
		
		-- Property_Name: param_productcount
		var_throughput_return := var_productcount_throughput * 60 / throughput_window;	-- throughput is measured at minute level.

	end if;
	----------------------------- availability -------------------------------------
	-- Property_Name: state_all
	
	if availability_window <= 0 then
		var_availability_return := 0.0;
	else
	
		var_last_value := '0'; -- setup default value.
		for prerec in
			select time, property_value from value_stream 
			where entity_id=value_stream_name and source_id=machine_id and property_name='state_all'
			and time <= var_availability_start_time
			order by time desc limit 1
		LOOP
			var_last_value := prerec.property_value;
		END LOOP;
		var_last_time := var_availability_start_time;	-- setup start time in loop.
	
		available_runtime_in_sec = 0.0;
		available_stoptime_in_sec = 0.0;
		for rec in 
			select time, property_value from value_stream 
			where entity_id=value_stream_name and source_id=machine_id and property_name='state_all'
			and time < var_end_time and time > var_availability_start_time
			order by time
		LOOP
			-- RAISE NOTICE '%:% - %:%', var_last_time, var_last_value, rec.time, rec.property_value;
			if var_last_value = '1' then
				available_runtime_in_sec := extract(epoch from rec.time - var_last_time)+ available_runtime_in_sec;
			ELSEIF var_last_value = '2' then
				available_stoptime_in_sec := extract(epoch from rec.time - var_last_time)+ available_stoptime_in_sec;
			ELSEIF var_last_value = '3' then
				available_runtime_in_sec := extract(epoch from rec.time - var_last_time)+ available_runtime_in_sec;
			END IF;
			var_last_time := rec.time;
			var_last_value := rec.property_value;
		END LOOP;
		-- add tail time.
		if var_last_value = '1' then
			available_runtime_in_sec := extract(epoch from var_end_time - var_last_time)+ available_runtime_in_sec;
		ELSEIF var_last_value = '2' then
			available_stoptime_in_sec := extract(epoch from var_end_time - var_last_time)+ available_stoptime_in_sec;
		ELSEIF var_last_value = '3' then
			available_runtime_in_sec := extract(epoch from var_end_time - var_last_time)+ available_runtime_in_sec;
		END IF;
		-- raise notice 'End at:%', now();
		var_availability_return := (available_runtime_in_sec+available_stoptime_in_sec)/availability_window;
	end if;
	----------------------------- Capacity Potential -------------------------------------
	
	-- get product count for capacity potential
	
	if capacity_potential_window <= 0.0 then
		var_capacitypotential_return := 0.0;
	else
		var_count_last := 0;
		for prerec in 
		select time, property_value from value_stream
		where entity_id=value_stream_name and source_id = machine_id and property_name='param_productcount'
		and time <= var_capacity_potential_start_time
		order by time desc limit 1
		LOOP
		var_count_last := prerec.property_value;
		END LOOP;
	
		var_count_end := var_count_last;
		for rec in 
		select time, property_value from value_stream
		where entity_id=value_stream_name and source_id = machine_id and property_name='param_productcount'
		and time < var_end_time and time > var_capacity_potential_start_time
		order by time desc limit 1
		LOOP
		var_count_end := rec.property_value; -- need string to real convertion?
		END LOOP;
		
		var_productcount_capacity_potential := var_count_end - var_count_last;
		
		-- get runtime for capacity potential
		var_last_value := '0'; -- setup default value.
		for prerec in
			select time, property_value from value_stream 
			where entity_id=value_stream_name and source_id=machine_id and property_name='state_all'
			and time <= var_capacity_potential_start_time
			order by time desc limit 1
		LOOP
			var_last_value := prerec.property_value;
		END LOOP;
		var_last_time := var_capacity_potential_start_time;	-- setup start time in loop.
	
		available_runtime_in_sec = 0.0;
		available_stoptime_in_sec = 0.0;
		for rec in 
			select time, property_value from value_stream 
			where entity_id=value_stream_name and source_id=machine_id and property_name='state_all'
			and time < var_end_time and time > var_capacity_potential_start_time
			order by time
		LOOP
			-- RAISE NOTICE '%:% - %:%', var_last_time, var_last_value, rec.time, rec.property_value;
			if var_last_value = '1' then
				available_runtime_in_sec := extract(epoch from rec.time - var_last_time)+ available_runtime_in_sec;
			END IF;
			var_last_time := rec.time;
			var_last_value := rec.property_value;
		END LOOP;
		-- add tail time.
		if var_last_value = '1' then
			available_runtime_in_sec := extract(epoch from var_end_time - var_last_time)+ available_runtime_in_sec;
		END IF;
		
		
		-- Property_Name: param_productcount
		var_idearunrate := ideal_run_rate;	-- this needs to be retrived from additional DB.
		if available_runtime_in_sec <= 0.0 then
			var_capacitypotential_return := 0.0;
		ELSEIF var_idearunrate <= 0.0 then
			var_capacitypotential_return := 0.0;
		ELSE
			var_capacitypotential_return := 1.0 - ((var_productcount_capacity_potential * 60 /available_runtime_in_sec) / var_idearunrate);
		END IF;
	end if;
	----------------------------- Efficiency -------------------------------------
	
	-- Property_Name: param_lifetimecycle
	if efficiency_window <= 0.0 then
		var_efficiency_return := 0.0;
	else 
	
		var_count_last := 0;
		for prerec in 
		select time, property_value from value_stream
		where entity_id=value_stream_name and source_id = machine_id and property_name='param_lifetimecycle'
		and time <= var_efficiency_start_time
		order by time desc limit 1
		LOOP
		var_count_last := prerec.property_value;
		END LOOP;
	
		var_count_end := var_count_last;
		for rec in 
		select time, property_value from value_stream
		where entity_id=value_stream_name and source_id = machine_id and property_name='param_lifetimecycle'
		and time < var_end_time and time > var_efficiency_start_time
		order by time desc limit 1
		LOOP
		var_count_end := rec.property_value; -- need string to real convertion?
		END LOOP;
		var_count_efficiency = var_count_end - var_count_last;
	
		-- Property_Name: param_productcount
		var_count_last := 0;
		for prerec in 
		select time, property_value from value_stream
		where entity_id=value_stream_name and source_id = machine_id and property_name='param_productcount'
		and time <= var_efficiency_start_time
		order by time desc limit 1
		LOOP
		var_count_last := prerec.property_value;
		END LOOP;
	
		var_count_end := var_count_last;
		for rec in 
		select time, property_value from value_stream
		where entity_id=value_stream_name and source_id = machine_id and property_name='param_productcount'
		and time < var_end_time and time > var_efficiency_start_time
		order by time desc limit 1
		LOOP
		var_count_end := rec.property_value; -- need string to real convertion?
		END LOOP;
		var_productcount_efficiency := var_count_end - var_count_last;
		
	
	
	
	-- Property_Name: param_productcount, param_lifetimecycle
		if var_count_efficiency > 0 then
			var_efficiency_return := var_productcount_efficiency * 1.0 / var_count_efficiency;
		ELSE
			var_efficiency_return := 0.0;
		END IF;
	end if;

	AVERAGE := var_average_return;
	CYCLECOUNT := var_count_return;
	PRODUCTCOUNT := var_productcount_return;
	THROUGHPUT := var_throughput_return;
	AVAILABILITY := var_availability_return;
	CAPACITYPOTENTIAL := var_capacitypotential_return;
	EFFICIENCY := var_efficiency_return;
	STARTTIME := start_time_string;
	ENDTIME := end_time_string;
	MACHINEID := machine_id;
	RETURN NEXT;

end;

$function$