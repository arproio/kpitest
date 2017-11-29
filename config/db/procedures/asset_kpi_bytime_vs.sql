CREATE OR REPLACE FUNCTION public.asset_kpi_bytime_vs(value_stream_name character varying, machine_id character varying, start_time_string character varying, end_time_string character varying, shift_start_time character varying, ideal_run_rate integer, capacity_potential_window real, throughput_window real, efficiency_window real, availability_window real)
 RETURNS TABLE(availability real, throughputcycles real, throughput real, cyclesperminute real, vacreached real, efficiency real, deviation real, capacitypotential real, starttime character varying, endtime character varying, machineid character varying)
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
	var_capacity_potential_start_time timestamp with time zone;
	var_throughput_start_time timestamp with time zone;
	var_efficiency_start_time timestamp with time zone;
	var_availability_start_time timestamp with time zone;
	
	duration_in_sec integer;
	var_last_time timestamp with time zone;
	var_last_run_time timestamp with time zone;
	var_last_stop_time timestamp with time zone;
	var_last_alarm_time timestamp with time zone;
	var_last_value character varying;
	rec RECORD;
	prerec RECORD;
	
	available_runtime_in_sec	real;
	available_stoptime_in_sec	real;
	available_alarmtime_in_sec real;

	var_time_gap real;
	var_speedcpm_last  real;	
	var_average_return	real;	-- return value
	var_total  real;
	var_counter integer;
	
	var_count_last	integer;
	var_count_end	integer;
	var_count_return	integer;	-- return value
	var_productcount_return	integer;	-- return value
	var_throughput_return	real;		-- return value
	var_availability_return real;		-- return value

	var_idealrunrate	integer;
	var_capacitypotential_return	real;	-- return value
	var_efficiency_return	real;		-- return value
	var_utillizationtotal_last real;
	
	var_lifetimecycles_last real;
	var_current_lifetimecycles real;
	var_deviation_evaluated boolean;
	var_current_deviation real;
	var_deviation_return real;
	
	var_vacreached_last real;
	var_vacreached_return real;
	
	var_cyclesperminute_return real;
	var_throughputcycles_return real;
	
	var_last_run_val character varying; -- setup default value.
	var_last_stop_val character varying;
	var_last_alarm_val character varying;
	val_array character varying array[3];

	prerec_cycle record;
	prerec_param record;

	rec_cycle record;
	rec_param record;

	var_efficiency_count real;
	var_deviation_count real;
	
	

begin
	select into var_end_time (to_timestamp(end_time_string,'YYYYMMDDHH24MISS')::timestamp with time zone) ;
	select into var_start_time (to_timestamp(start_time_string,'YYYYMMDDHH24MISS')::timestamp with time zone) ;
	duration_in_sec := extract('epoch' from (var_end_time - var_start_time));
	
	

	IF duration_in_sec <=0 then
		AVAILABILITY := 0.0;
		THROUGHPUTCYCLES := 0.0;
		THROUGHPUT := 0.0;
		CYCLESPERMINUTE := 0.0;
		VACREACHED := 0.0;
		EFFICIENCY := 0.0;
		DEVIATION := 0.0;
		CAPACITYPOTENTIAL := 0.0;
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
	
    
	--raise notice 'var_capacity_potential_start_time: %', var_capacity_potential_start_time;
	--raise notice 'var_throughput_start_time: %', var_throughput_start_time;
	--raise notice 'var_efficiency_start_time: %', var_efficiency_start_time;
	raise notice 'var_availability_start_time: %', var_availability_start_time;
	
	-- --raise notice 'Start from:%', now();
	-- Caution1:    all entered time must be UTC time.
	-- Caution2:    all msc will be cut off, 000 will be the default.
	-- Caution3:    in all query, end_time will be included, start_time will NOT be included.
	-- --raise notice 'end time:%', var_end_time;
	-- --raise notice 'start time:%', var_start_time;

	----------------------------- Efficiency -------------------------------------
	-- Property_Name: param_utillizationtotal --- Cycle Based Strict Average
		
	if efficiency_window <= 0 then
		var_efficiency_return := 0;
	else
		var_efficiency_count := 0;
		var_utillizationtotal_last := 0.0;

		for prerec_cycle in 
		select time, property_value from value_stream
		where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_VacComplete'
		and time <= var_efficiency_start_time
		order by time desc limit 1
		LOOP	
			var_efficiency_count := var_efficiency_count + 1;
			for prerec_param in
			select time, property_value from value_stream
			where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_ProductLoadDone' and property_value::json->'rows'->0->>'param_utillizationtotal' <> '999'
			and time <= prerec_cycle.time
			order by time desc limit 1
			LOOP
			
				var_utillizationtotal_last := prerec_param.property_value::json->'rows'->0->>'param_utillizationtotal';
			
			end LOOP;
		END LOOP;
	
		
		for rec_cycle in 
		select time, property_value from value_stream
		where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_VacComplete'
		and time < var_end_time and time > var_efficiency_start_time
		order by time
		LOOP
			var_efficiency_count := var_efficiency_count + 1;
			for rec_param in
			select time, property_value from value_stream
			where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_ProductLoadDone' and property_value::json->'rows'->0->>'param_utillizationtotal' <> '999'
			and time <= rec_cycle.time
			order by time desc limit 1
			LOOP
			
				var_utillizationtotal_last := var_utillizationtotal_last + (prerec_param.property_value::json->'rows'->0->>'param_utillizationtotal')::real;
				
			end LOOP;
			
		
		end LOOP;

		
		var_efficiency_return := var_utillizationtotal_last / var_efficiency_count;		

--		raise notice 'var_efficiency_return: %', var_efficiency_return;
--		raise notice 'var_utillizationtotal_last: %', var_utillizationtotal_last;
--		raise notice 'var_efficiency_count: %', var_efficiency_count;


--		var_utillizationtotal_last := 0.0;
--		
--		for prerec in 
--		select time, property_value from value_stream
--		where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_ProductLoadDone' and property_value::json->'rows'->0->>'param_utillizationtotal' <> '999'
--		and time <= var_efficiency_start_time
--		order by time desc limit 1
--		LOOP
--			--raise notice 'time: %', prerec.time;
--			var_utillizationtotal_last := prerec.property_value::json->'rows'->0->>'param_utillizationtotal';
--		END LOOP;
--		--raise notice 'var_utillizationtotal_last: %', var_utillizationtotal_last;
--		
--		var_last_time := var_efficiency_start_time;
--		var_total := 0.0;
--		
--		--raise notice 'var_end_time: %', var_end_time;
--		
--		for rec in 
--		select time, property_value from value_stream
--		where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_ProductLoadDone' and property_value::json->'rows'->0->>'param_utillizationtotal' <> '999'
--		and time < var_end_time and time > var_efficiency_start_time
--		order by time
--		LOOP
--			--raise notice 'param_utillizationtotal: %', rec.property_value::json->'rows'->0->>'param_utillizationtotal';
--			var_time_gap := extract(epoch from rec.time - var_last_time);
--			var_total := var_time_gap * var_utillizationtotal_last + var_total;
--		
--			var_last_time := rec.time;
--			var_utillizationtotal_last := rec.property_value::json->'rows'->0->>'param_utillizationtotal'; -- need string to real convertion?
--		END LOOP;
--	
--		var_total := extract(epoch from var_end_time - var_last_time) * var_utillizationtotal_last + var_total;
--		-- --raise notice 'Final total:(%) and average:(%)', var_total_distince, var_total_distince / duration_in_sec;
--	
--		var_efficiency_return := var_total / efficiency_window;
	end if;

	

	------------------------------ Vacuum Deviation ------------------------------
	-- Cycle Based Strict Average
	
	var_lifetimecycles_last := 0.0;
	var_deviation_count := 0;
	var_deviation_evaluated := false;

	for prerec in 
	select time, property_value from value_stream
	where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_VacComplete'
	and time <= var_start_time
	order by time desc limit 1
	LOOP
		var_lifetimecycles_last := prerec.property_value::json->'rows'->0->>'param_lifetimecycles';
	END LOOP;
	
	
	--var_last_time := var_start_time;
	var_total := 0.0;
	var_current_deviation := 0.0;
	
	for rec in 
	select time, property_value from value_stream
	where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_VacComplete'
	and time < var_end_time and time > var_start_time
	order by time
	LOOP
		var_current_lifetimecycles := rec.property_value::json->'rows'->0->>'param_lifetimecycles';
		if var_current_lifetimecycles > var_lifetimecycles_last then
			var_deviation_evaluated := true;
			var_deviation_count := var_deviation_count + 1;
			--var_time_gap := extract(epoch from rec.time - var_last_time);
			
			select a.property_value::real - (rec.property_value::json->'rows'->0->>'param_vacreached')::real
			into var_current_deviation
			from 
				(select property_value
				from value_stream
				where entity_id=value_stream_name and source_id = machine_id and property_name='recipe_vactarget'
				and time <= rec.time order by time desc limit 1) as a;
			----raise notice 'var_current_deviation: %', var_current_deviation;
			----raise notice 'var_total: %', var_total;
			--var_total := var_time_gap * var_current_deviation + var_total;
			var_total := var_total + var_current_deviation;

		else
			var_deviation_evaluated := false;
		end if;
		--var_last_time := rec.time;
		var_lifetimecycles_last := var_current_lifetimecycles; -- need string to real convertion?
	END LOOP;
	
	----raise notice 'var_deviation_evaluated: %', var_deviation_evaluated;
	
--	if var_deviation_evaluated = true then	
--		var_total := extract(epoch from var_end_time - var_last_time) * var_current_deviation + var_total;
--	end if;
	-- --raise notice 'Final total:(%) and average:(%)', var_total_distince, var_total_distince / duration_in_sec;
	--raise notice 'var_total: %', var_total;

	var_deviation_return := var_total / var_deviation_count;
	
	raise notice 'var_deviation_return: %', var_deviation_return;
	raise notice 'var_deviation_count: %', var_deviation_count;
	raise notice 'var_total: %', var_total;

	---------------------------- Vacuum Reached ----------------------------
	var_vacreached_last := 0.0;
	for prerec in 
	select time, property_value from value_stream
	where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_VacComplete'
	and time <= var_start_time
	order by time desc limit 1
	LOOP
		var_vacreached_last := prerec.property_value::json->'rows'->0->>'param_vacreached';
	END LOOP;

--	var_last_time := var_start_time;
--	var_total := 0.0;
--	for rec in 
--	select time, property_value from value_stream
--	where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_VacComplete'
--	and time < var_end_time and time > var_start_time
--	order by time
--	LOOP
--	var_time_gap := extract(epoch from rec.time - var_last_time);
--	var_total := var_time_gap * var_vacreached_last + var_total;
--
--	var_last_time := rec.time;
--	var_vacreached_last := rec.property_value::json->'rows'->0->>'param_vacreached'; -- need string to real convertion?
--	END LOOP;
--
--	var_total := extract(epoch from var_end_time - var_last_time) * var_vacreached_last + var_total;
--	-- --raise notice 'Final total:(%) and average:(%)', var_total_distince, var_total_distince / duration_in_sec;
--
--	var_vacreached_return := var_total / duration_in_sec;

	---- Strict Average
	var_counter := 0;
	var_total := var_vacreached_last;
	for rec in 
		select time, property_value from value_stream
		where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_VacComplete'
		and time <= var_end_time and time > var_start_time
	LOOP
		var_vacreached_last := rec.property_value::json->'rows'->0->>'param_vacreached';
		var_total := var_vacreached_last + var_total;
		var_counter := var_counter + 1;
	END LOOP;

	var_vacreached_return := var_total / var_counter;
	
	----------------------------- Cycles Per Minute --------------------------------------
	var_speedcpm_last := 0.0;
	for prerec in 
	select time, property_value from value_stream
	where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_VacComplete'
	and time <= var_start_time
	order by time desc limit 1
	LOOP
	var_speedcpm_last := prerec.property_value::json->'rows'->0->>'param_speedCPM';
	END LOOP;

	var_last_time := var_start_time;
	var_total := 0.0;
	for rec in 
	select time, property_value from value_stream
	where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_VacComplete'
	and time < var_end_time and time > var_start_time
	order by time
	LOOP
	var_time_gap := extract(epoch from rec.time - var_last_time);
	var_total := var_time_gap * var_speedcpm_last + var_total;

	var_last_time := rec.time;
	var_speedcpm_last := rec.property_value::json->'rows'->0->>'param_speedCPM'; -- need string to real convertion?
	END LOOP;

	var_total := extract(epoch from var_end_time - var_last_time) * var_speedcpm_last + var_total;
	-- --raise notice 'Final total:(%) and average:(%)', var_total_distince, var_total_distince / duration_in_sec;

	var_cyclesperminute_return := var_total / duration_in_sec;
	
	----------------------------- cycle count -------------------------------------
	
	if throughput_window <= 0 then
		var_count_return := 0;
	else 
	-- Property_Name: param_lifetimecycle
		var_count_last := 0;
		for prerec in 
		select time, property_value from value_stream
		where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_VacComplete'
		and time <= var_throughput_start_time
		order by time desc limit 1
		LOOP
		var_count_last := prerec.property_value::json->'rows'->0->>'param_lifetimecycles';
		END LOOP;
	
		var_count_end := var_count_last;
		for rec in 
		select time, property_value from value_stream
		where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_VacComplete'
		and time < var_end_time and time > var_throughput_start_time
		order by time desc limit 1
		LOOP
		var_count_end := rec.property_value::json->'rows'->0->>'param_lifetimecycles'; -- need string to real convertion?
		END LOOP;
		var_count_return = var_count_end - var_count_last;
	end if;
	----------------------------- throughput -------------------------------------
	-- Property_Name: param_lifetimecycles
	if throughput_window <= 0.0 then
		var_throughput_return := 0.0;
		var_throughputcycles_return := 0.0;
	else
		var_throughput_return := var_count_return * 60 / throughput_window;	-- throughput is measured at minute level.
	
		var_throughputcycles_return := var_count_return * 60 / throughput_window;
	end if;
	
	
	----------------------------- availability ------------------------------------- 
	
	if availability_window <= 0.0 then
		var_availability_return := 0.0;
	else
		-- Property_Name: state_all
		var_last_run_val := '0'; -- setup default value.
		var_last_stop_val := '0';
		var_last_alarm_val := '0';
	
		select property_value from value_stream
		into var_last_run_val
		where entity_id=value_stream_name and source_id=machine_id and property_name='state_run'
		and time <= var_availability_start_time
		order by time desc limit 1;
		
		select property_value from value_stream
		into var_last_stop_val
		where entity_id=value_stream_name and source_id=machine_id and property_name='state_stop'
		and time <= var_availability_start_time
		order by time desc limit 1;
		
		select property_value from value_stream
		into var_last_alarm_val
		where entity_id=value_stream_name and source_id=machine_id and property_name='state_alarm'
		and time <= var_availability_start_time
		order by time desc limit 1;
		
		var_last_run_time := var_availability_start_time;	-- setup start time in loop.
		var_last_stop_time := var_availability_start_time;	-- setup start time in loop.
		var_last_alarm_time := var_availability_start_time;	-- setup start time in loop.
		
		available_runtime_in_sec = 0.0;
		available_stoptime_in_sec = 0.0;
		available_alarmtime_in_sec = 0.0;
	
		for rec in 
			select time, property_value from value_stream 
			where entity_id=value_stream_name and source_id=machine_id and property_name='state_run'
			and time < var_end_time and time > var_availability_start_time
			order by time
		LOOP
--			raise notice 'var_last_run_time: %', var_last_run_time;
--			raise notice 'var_last_run_val: %', var_last_run_val;
			-- --raise notice '%:% - %:%', var_last_time, var_last_value, rec.time, rec.property_value;
			if var_last_run_val = 'true' then
				available_runtime_in_sec := extract(epoch from rec.time - var_last_run_time)+ available_runtime_in_sec;
			end if;
			
			var_last_run_time := rec.time;
			var_last_run_val := rec.property_value;
		
		END LOOP;
		
		for rec in 
			select time, property_value from value_stream 
			where entity_id=value_stream_name and source_id=machine_id and property_name='state_stop'
			and time < var_end_time and time > var_availability_start_time
			order by time
		LOOP
			raise notice 'var_last_stop_time: %', var_last_stop_time;
			raise notice 'var_last_stop_val: %', var_last_stop_val;
			if var_last_stop_val = 'true' then
				available_stoptime_in_sec := extract(epoch from rec.time - var_last_stop_time)+ available_stoptime_in_sec;
			end if;
			
			
			var_last_stop_time := rec.time;
			var_last_stop_val := rec.property_value;
		
		END LOOP;
		
		for rec in 
			select time, property_value from value_stream 
			where entity_id=value_stream_name and source_id=machine_id and property_name='state_alarm'
			and time < var_end_time and time > var_availability_start_time
			order by time
		LOOP
		
			raise notice 'var_last_alarm_time: %', var_last_alarm_time;
			raise notice 'var_last_alarm_val: %', var_last_alarm_val;
			raise notice 'rec.time: %', rec.time;

			if var_last_alarm_val = 'true' then
				available_alarmtime_in_sec := extract(epoch from rec.time - var_last_alarm_time) + available_alarmtime_in_sec;
			end if;
			raise notice 'available_alarmtime_in_sec: %', available_alarmtime_in_sec;
			var_last_alarm_time := rec.time;
			var_last_alarm_val := rec.property_value;
		
		END LOOP;
		-- add tail time.
		if var_last_run_val = 'true' then
			available_runtime_in_sec := extract(epoch from var_end_time - var_last_run_time)+ available_runtime_in_sec;
		end if;
		if var_last_stop_val = 'true' then
			available_stoptime_in_sec := extract(epoch from var_end_time - var_last_stop_time)+ available_stoptime_in_sec;
		end if;
		if var_last_alarm_val = 'true' then
			available_alarmtime_in_sec := extract(epoch from var_end_time - var_last_alarm_time)+ available_alarmtime_in_sec;
		end if;
		-- --raise notice 'End at:%', now();
		var_availability_return := (available_runtime_in_sec + available_stoptime_in_sec - available_alarmtime_in_sec)/availability_window;
		
	end if;
	
	raise notice 'available_runtime_in_sec: %', available_runtime_in_sec;
	raise notice 'available_stoptime_in_sec: %', available_stoptime_in_sec;
	raise notice 'available_alarmtime_in_sec: %', available_alarmtime_in_sec;
	
	---------------------------- Alarm Time Sum ------------------------------
	
	
	---------------------------- State Time Sum ------------------------------
	
	
	
	----------------------------- Capacity Potential -------------------------------------
	-- re calculate count
	if capacity_potential_window <= 0 then
		var_capacitypotential_return := 0.0;
	else
		var_count_last := 0;
		
		for prerec in 
		select time, property_value from value_stream
		where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_VacComplete'
		and time <= var_capacity_potential_start_time
		order by time desc limit 1
		LOOP
			var_count_last := prerec.property_value::json->'rows'->0->>'param_lifetimecycles';
		END LOOP;
	
		var_count_end := var_count_last;
		
		for rec in 
		select time, property_value from value_stream
		where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_VacComplete'
		and time < var_end_time and time > var_capacity_potential_start_time
		order by time desc limit 1
		LOOP
			var_count_end := rec.property_value::json->'rows'->0->>'param_lifetimecycles'; -- need string to real convertion?
		END LOOP;
		
		var_count_return = var_count_end - var_count_last;	
		
		--raise notice 'var_count_return: %', var_count_return;
		
		select idealrunrate
		into var_idealrunrate
		from public.irrconfig
		where asset_id = machine_id
		and channelnumber = 1;
		
		--recalculate run time
		
		var_last_run_val := '0'; -- setup default value.
		
		select property_value from value_stream
		into var_last_run_val
		where entity_id=value_stream_name and source_id=machine_id and property_name='state_run'
		and time <= var_capacity_potential_start_time
		order by time desc limit 1;
		
		var_last_time := var_capacity_potential_start_time;
		
		for rec in 
		select time, property_value from value_stream 
		where entity_id=value_stream_name and source_id=machine_id and property_name='state_run'
		and time < var_end_time and time > var_capacity_potential_start_time
		order by time
		LOOP
		
			-- --raise notice '%:% - %:%', var_last_time, var_last_value, rec.time, rec.property_value;
			if var_last_run_val = 'true' then
				available_runtime_in_sec := extract(epoch from rec.time - var_last_time)+ available_runtime_in_sec;
			end if;
			
			var_last_time := rec.time;
			var_last_run_val := rec.property_value;
	
		END LOOP;
		 -- tail time
		if var_last_run_val = 'true' then
			available_runtime_in_sec := extract(epoch from var_end_time - var_last_time)+ available_runtime_in_sec;
		end if;
		
		raise notice 'capacity potential available_runtime_in_sec: %', available_runtime_in_sec;
		raise notice 'var_count_return: %', var_count_return; 
		raise notice 'var_idealrunrate: %', var_idealrunrate;
		
		if available_runtime_in_sec <= 0.0 then
			var_capacitypotential_return := 0.0;
		ELSEIF var_idealrunrate <= 0.0 then
			var_capacitypotential_return := 0.0;
		ELSE
			var_capacitypotential_return := 1.0 - ((var_count_return * 60 /available_runtime_in_sec) / var_idealrunrate);
		END IF;
	end if;
	
	
	STARTTIME := start_time_string;
	ENDTIME := end_time_string;
	MACHINEID := machine_id;
	AVAILABILITY := var_availability_return;
	THROUGHPUTCYCLES := var_throughputcycles_return;
	THROUGHPUT := var_throughput_return;
	CYCLESPERMINUTE := var_cyclesperminute_return;
	VACREACHED := var_vacreached_return;
	EFFICIENCY := var_efficiency_return;
	DEVIATION := var_deviation_return;
	CAPACITYPOTENTIAL := var_capacitypotential_return;

	RETURN NEXT;

end;

$function$
