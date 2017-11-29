CREATE OR REPLACE FUNCTION public.asset_kpi_bytime_vpp(value_stream_name character varying, machine_id character varying, start_time_string character varying, end_time_string character varying, shift_start_time character varying, ideal_run_rate integer, capacity_potential_window real, availability_window real)
 RETURNS TABLE(availability real, efficiency real, capacitypotential real, giveaway real, rejects real, goodproduct real, sdi real, productaverage real, faultrate real, performance real, plannedproductiontime real, machinespeed real, pumpspeed real, totalpackcount real, filmfeedlength real, centersealtime real, endsealtime real, centersealtemp real, endsealtemp real, endremainingtemp real, starttime character varying, endtime character varying, machineid character varying)
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
	var_shift_start_time timestamp with time zone;
	var_capacity_potential_start_time timestamp with time zone;
	var_availability_start_time timestamp with time zone;
	
	duration_in_sec integer;
	var_planned_production_time_in_sec integer;
	var_last_time timestamp with time zone;
	var_last_run_time timestamp with time zone;
	var_last_stop_time timestamp with time zone;

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
	
	var_faultrate_return real;
	available_faulttime_in_sec real;
	var_current_giveaway real;
	var_giveaway_return real;
	
	var_reject_return real;
	var_good_product_count real;
	var_sum_lastpackageweight real;
	var_absdeviation real;
	var_sdi_return real;
	var_productaverage_return real;
	var_total_pack_count integer;
	var_good_product_return real;
	var_performance_return real;
	var_capacity_potential_return real;
	
	var_machinespeed_last real;
	var_pumpinvspeed_last real;
	var_totalpackcount_last real;
	var_filmfeedlength_last real;
	var_centersealtime_last real;
	var_endsealtime_last real;
	var_centersealtemperature_last real;
	var_endsealtemperature_last real;
	var_endremtemppv_last real;
	
	var_machinespeed_total real;
	var_pumpinvspeed_total real;
	var_totalpackcount_total real;
	var_filmfeedlength_total real;
	var_centersealtime_total real;
	var_endsealtime_total real;
	var_centersealtemperature_total real;
	var_endsealtemperature_total real;
	var_endremtemppv_total real;
	
	-- RAISE NOTICE 'Final total:(%) and average:(%)', var_total_distince, var_total_distince / duration_in_sec;
	
	var_machinespeed_average_return real; 
	var_pumpinvspeed_average_return real; 
	var_totalpackcount_average_return real;
	var_filmfeedlength_average_return real;
	var_centersealtime_average_return real;
	var_endsealtime_average_return real;
	var_centersealtemperature_average_return real;
	var_endsealtemperature_average_return real;
	var_endremtemppv_average_return real;
	
	
	

begin
	select into var_end_time (to_timestamp(end_time_string,'YYYYMMDDHH24MISS')::timestamp with time zone) ;
	select into var_start_time (to_timestamp(start_time_string,'YYYYMMDDHH24MISS')::timestamp with time zone) ;
	select into var_shift_start_time (to_timestamp(start_time_string,'YYYYMMDDHH24MISS')::timestamp with time zone) ;

	duration_in_sec := extract('epoch' from (var_end_time - var_start_time));
	var_planned_production_time_in_sec := extract('epoch' from (var_end_time - var_start_time));
	

	IF duration_in_sec <=0 then
		AVAILABILITY := 0.0;
		EFFICIENCY := 0.0;
 		CAPACITYPOTENTIAL := 0.0;
		GIVEAWAY := 0.0;
		REJECTS := 0.0;
		GOODPRODUCT := 0.0;
		SDI := 0.0;
		PRODUCTAVERAGE := 0.0;
		FAULTRATE := 0.0;
		PERFORMANCE := 0.0;
		PLANNEDPRODUCTIONTIME := 0.0;
		MACHINESPEED := 0.0;
		PUMPSPEED := 0.0;
		TOTALPACKCOUNT := 0.0;
		FILMFEEDLENGTH := 0.0;
		CENTERSEALTIME := 0.0;
		ENDSEALTIME := 0.0;
		CENTERSEALTEMP := 0.0;
		ENDSEALTEMP := 0.0;
		ENDREMAININGTEMP := 0.0;
		STARTTIME := start_time_string;
		ENDTIME := end_time_string;
		MACHINEID := machine_id;
		RETURN NEXT;

		RETURN;
	END IF;
	
	----------------------------- Set up Windows --------------------------------
		
	select var_end_time - INTERVAL '1 second' * capacity_potential_window
    into var_capacity_potential_start_time;
    
    select var_end_time - INTERVAL '1 second' * availability_window
    into var_availability_start_time;
	
    
	raise notice 'var_capacity_potential_start_time: %', var_capacity_potential_start_time;
	raise notice 'var_availability_start_time: %', var_availability_start_time;
	
	-- raise notice 'Start from:%', now();
	-- Caution1:    all entered time must be UTC time.
	-- Caution2:    all msc will be cut off, 000 will be the default.
	-- Caution3:    in all query, end_time will be included, start_time will NOT be included.
	-- raise notice 'end time:%', var_end_time;
	-- raise notice 'start time:%', var_start_time;

    ----------------------------- Efficiency -------------------------------------

    -- Property_Name: state_machinerunning
	var_last_value := '0'; -- setup default value.
	for prerec in
		select field_values from stream 
		where entity_id=value_stream_name and source_id=machine_id
		and time <= var_start_time
		order by time desc limit 1
	LOOP
		var_last_value := prerec.field_values->>'state_machinerunning';
	END LOOP;
	var_last_time := var_start_time;	-- setup start time in loop.

	available_runtime_in_sec = 0.0;
	
	for rec in 
		select time,field_values from stream 
		where entity_id=value_stream_name and source_id=machine_id
		and time < var_end_time and time > var_start_time
		order by time
	LOOP
		if var_last_value = 'true' then
			available_runtime_in_sec := extract(epoch from rec.time - var_last_time)+ available_runtime_in_sec;
		END IF;
		var_last_time := rec.time;
		var_last_value := rec.field_values->>'state_machinerunning';
	END LOOP;
	-- add tail time.
	if var_last_value = '1' then
		available_runtime_in_sec := extract(epoch from var_end_time - var_last_time)+ available_runtime_in_sec;
	END IF;
	-- raise notice 'End at:%', now();
	var_efficiency_return := available_runtime_in_sec / duration_in_sec;
	
	raise notice 'var_efficiency_return: %', var_efficiency_return;
	------------------------------ Availability ---------------------------------
	if availability_window <= 0.0 then
		var_availability_return := 0.0;
	else
		var_last_run_val := '0'; -- setup default value.
		var_last_stop_val := '0';
		var_last_alarm_val := '0';
	
		select field_values->>'state_machinerunning' from stream 
		into var_last_run_val
		where entity_id=value_stream_name and source_id=machine_id
		and time <= var_availability_start_time
		order by time desc limit 1;
		
		select field_values->>'state_machinestopped' from stream 
		into var_last_stop_val
		where entity_id=value_stream_name and source_id=machine_id
		and time <= var_availability_start_time
		order by time desc limit 1;
		
		
		var_last_run_time := var_availability_start_time;	-- setup start time in loop.
		var_last_stop_time := var_availability_start_time;
		
		available_runtime_in_sec = 0.0;
		available_stoptime_in_sec = 0.0;
	
		for rec in 
			select time,field_values from stream 
			where entity_id=value_stream_name and source_id=machine_id
			and time < var_end_time and time > var_availability_start_time
			order by time
		LOOP
			
			-- RAISE NOTICE '%:% - %:%', var_last_time, var_last_value, rec.time, rec.property_value;
			if var_last_run_val = 'true' then
				available_runtime_in_sec := extract(epoch from rec.time - var_last_run_time)+ available_runtime_in_sec;
			end if;
			
			var_last_run_time := rec.time;
			var_last_run_val := rec.field_values->>'state_machinerunning';
		
		END LOOP;
		
		for rec in 
			select time,field_values from stream 
			where entity_id=value_stream_name and source_id=machine_id
			and time < var_end_time and time > var_availability_start_time
			order by time
		LOOP
			
			if var_last_stop_val = 'true' then
				available_stoptime_in_sec := extract(epoch from rec.time - var_last_stop_time)+ available_stoptime_in_sec;
			end if;
			
			
			var_last_stop_time := rec.time;
			var_last_stop_val := rec.field_values->>'state_machinestopped';
		
		END LOOP;
		
		-- add tail time.
		if var_last_run_val = 'true' then
			available_runtime_in_sec := extract(epoch from var_end_time - var_last_run_time)+ available_runtime_in_sec;
		end if;
		if var_last_stop_val = 'true' then
			available_stoptime_in_sec := extract(epoch from var_end_time - var_last_stop_time)+ available_stoptime_in_sec;
		end if;
	
		-- raise notice 'End at:%', now();
		var_availability_return := (available_runtime_in_sec + available_stoptime_in_sec) / availability_window;
		
		raise notice 'var_availability_return: %', var_availability_return;
	end if;
	------------------------Cycle Dependent KPIs----------------------------
	--Property Name: param_totalpackcount
	var_count_last := 0;
	for prerec in 
	select field_values from stream 
	where entity_id=value_stream_name and source_id=machine_id
	and time <= var_start_time
	order by time desc limit 1
	LOOP
	var_count_last := prerec.field_values->>'param_totalpackcount';
	END LOOP;

	var_count_end := var_count_last;
	
	for rec in 
	select field_values from stream 
	where entity_id=value_stream_name and source_id=machine_id
	and time < var_end_time and time > var_start_time
	order by time desc limit 1
	LOOP
	var_count_end := rec.field_values->>'param_totalpackcount'; -- need string to real convertion?
	END LOOP;
	
	
	var_total_pack_count := var_count_end - var_count_last;
--	select field_values->>'state_machinerunning' from stream 
--	into var_last_run_val
--	where entity_id=value_stream_name and source_id=machine_id
--	and time <= var_availability_start_time
--	order by time desc limit 1;
--	
--	var_last_time := var_start_time;

	--default values
	var_reject_return := 0.0;
	var_good_product_count := 0.0;
	var_giveaway_return := 0.0;
	var_sum_lastpackageweight := 0.0;
	var_absdeviation := 0.0;
	
	for rec in 
		select time,field_values from stream 
		where entity_id=value_stream_name and source_id=machine_id
		and time < var_end_time and time > var_start_time
		order by time
	LOOP
		
		-- Give Away
		if rec.field_values->>'state_machinerunning' = 'true' then
			var_current_giveaway := (rec.field_values->>'param_lastpackageweight')::real - (rec.field_values->>'recipe_producttargetweight')::real;
			if var_current_giveaway > 0 then
				var_giveaway_return := var_giveaway_return + var_current_giveaway;
			end if;
			
		
			--Reject
			if rec.field_values->>'param_reject' in ('1','2') then
					var_reject_return := var_reject_return + 1;
			end if;
			
			--Good Product
			if rec.field_values->>'param_reject' = '0' then
					var_good_product_count := var_good_product_count + 1;
			end if;
			
			--SDI
			var_absdeviation := var_absdeviation + abs((rec.field_values->>'param_lastpackageweight')::real - (rec.field_values->>'recipe_producttargetweight')::real);

			--Product Average
			var_sum_lastpackageweight := var_sum_lastpackageweight + (rec.field_values->>'param_lastpackageweight')::real;

		end if;

		
		
		
--		var_last_time := rec.time;
--		var_last_run_val := rec.field_values->>'state_machinerunning';
	
	END LOOP;
	
	if var_total_pack_count > 0 then	
		var_good_product_return := var_good_product_count / var_total_pack_count * 100;
	 	var_sdi_return := var_absdeviation / var_total_pack_count;
	 	var_productaverage_return := var_sum_lastpackageweight / var_total_pack_count;
	else 	
		var_good_product_return := 0;
        var_sdi_return := 0;
        var_productaverage_return := 0;
	end if;
	
	raise notice 'var_good_product_return: %', var_good_product_return;
	raise notice 'var_sdi_return: %', var_sdi_return;
	raise notice 'var_productaverage_return: %', var_productaverage_return;
	raise notice 'var_giveaway_return: %', var_giveaway_return;
	raise notice 'var_reject_return: %', var_reject_return;
	
	------------------------------ Fault Rate ---------------------------------
	-- NEED TO DETERMINE IF GRANULARITY CALC OR REALTIME TO DETERMINE START TIME
	var_last_value := '0'; -- setup default value.
	for prerec in
		select time,field_values from stream 
		where entity_id=value_stream_name and source_id=machine_id
		and time <= var_start_time
		order by time desc limit 1
	LOOP
		var_last_value := prerec.field_values->>'state_machinefaulted';
	END LOOP;
	var_last_time := var_start_time;	-- setup start time in loop.

	available_faulttime_in_sec = 0.0;
	
	for rec in 
		select time,field_values from stream 
		where entity_id=value_stream_name and source_id=machine_id
		and time < var_end_time and time > var_start_time
		order by time
	LOOP
		if var_last_value = 'true' then
			available_faulttime_in_sec := extract(epoch from rec.time - var_last_time)+ available_faulttime_in_sec;
		END IF;
		var_last_time := rec.time;
		var_last_value := rec.field_values->>'state_machinefaulted';
	END LOOP;
	-- add tail time.
	if var_last_value = 'true' then
		available_faulttime_in_sec := extract(epoch from var_end_time - var_last_time)+ available_faulttime_in_sec;
	END IF;
	-- raise notice 'End at:%', now();
	var_faultrate_return := available_faulttime_in_sec / duration_in_sec;
	
	raise notice 'var_faultrate_return: %', var_faultrate_return;
	
	------------------------------ Performance ----------------------------------
	if capacity_potential_window <= 0.0 then
	
		var_performance_return := 0.0;
	else
		--Property Name: param_totalpackcount
		var_count_last := 0;
		for prerec in 
		select field_values from stream 
		where entity_id=value_stream_name and source_id=machine_id
		and time <= var_capacity_potential_start_time
		order by time desc limit 1
		LOOP
		var_count_last := prerec.field_values->>'param_totalpackcount';
		END LOOP;
	
		var_count_end := var_count_last;
		
		for rec in 
		select field_values from stream 
		where entity_id=value_stream_name and source_id=machine_id
		and time < var_end_time and time > var_capacity_potential_start_time
		order by time desc limit 1
		LOOP
		var_count_end := rec.field_values->>'param_totalpackcount'; -- need string to real convertion?
		END LOOP;
		
		
		var_total_pack_count := var_count_end - var_count_last;
		
		
		
		var_last_value := '0'; -- setup default value.
		for prerec in
			select time,field_values from stream 
			where entity_id=value_stream_name and source_id=machine_id
			and time <= var_capacity_potential_start_time
			order by time desc limit 1
		LOOP
			var_last_value := prerec.field_values->>'state_machinerunning';
		END LOOP;
		var_last_time := var_capacity_potential_start_time;	-- setup start time in loop.
	
		available_runtime_in_sec = 0.0;
		
		for rec in 
			select time,field_values from stream 
			where entity_id=value_stream_name and source_id=machine_id
			and time < var_end_time and time > var_capacity_potential_start_time
			order by time
		LOOP
			-- RAISE NOTICE '%:% - %:%', var_last_time, var_last_value, rec.time, rec.property_value;
			if var_last_value = 'true' then
				available_runtime_in_sec := extract(epoch from rec.time - var_last_time)+ available_runtime_in_sec;
			END IF;
			var_last_time := rec.time;
			var_last_value := rec.field_values->>'state_machinefaulted';
		END LOOP;
		-- add tail time.
		if var_last_value = 'true' then
			available_runtime_in_sec := extract(epoch from var_end_time - var_last_time)+ available_runtime_in_sec;
		END IF;
		
		-- Need to get channel from db
		
		
		if available_runtime_in_sec <= 0.0 then
			var_performance_return := 0.0;
		ELSEIF ideal_run_rate <= 0.0 then
			var_performance_return := 0.0;
		ELSE
			var_performance_return := ((var_total_pack_count * 60 /available_runtime_in_sec) / ideal_run_rate) * 100;
		END IF;
		raise notice 'var_performance_return: %', var_performance_return;
		---------------------Capaciy Potential----------------------------------
		
		
		var_capacity_potential_return := 100 - var_performance_return;
		
		raise notice 'var_capacity_potential_return: %', var_capacity_potential_return;
	end if;

	--------------------------- Averages -------------------------------------
	var_machinespeed_last := 0.0;
	var_pumpinvspeed_last := 0.0;
	var_totalpackcount_last := 0.0;
	var_filmfeedlength_last := 0.0;
	var_centersealtime_last := 0.0;
	var_endsealtime_last := 0.0;
	var_centersealtemperature_last := 0.0;
	var_endsealtemperature_last := 0.0;
	var_endremtemppv_last := 0.0;
	
	for prerec in 
	select time,field_values from stream 
	where entity_id=value_stream_name and source_id=machine_id
	and time <= var_start_time
	order by time desc limit 1
	LOOP
		var_machinespeed_last := prerec.field_values->>'param_machinespeed';
		var_pumpinvspeed_last := prerec.field_values->>'param_pumpinvspeed';
		var_totalpackcount_last := prerec.field_values->>'param_totalpackcount';
		var_filmfeedlength_last := prerec.field_values->>'recipe_filmfeedlength';
		var_centersealtime_last := prerec.field_values->>'recipe_centersealtime';
		var_endsealtime_last := prerec.field_values->>'recipe_endsealtime';
		var_centersealtemperature_last := prerec.field_values->>'recipe_centersealtemperature';
		var_endsealtemperature_last := prerec.field_values->>'recipe_endsealtemperature';
		var_endremtemppv_last := prerec.field_values->>'param_endremtemppv';
	END LOOP;

	var_last_time := var_start_time;
	
	var_machinespeed_total := 0.0;
	var_pumpinvspeed_total := 0.0;
	var_totalpackcount_total := 0.0;
	var_filmfeedlength_total := 0.0;
	var_centersealtime_total := 0.0;
	var_endsealtime_total := 0.0;
	var_centersealtemperature_total := 0.0;
	var_endsealtemperature_total := 0.0;
	var_endremtemppv_total := 0.0;
	
	for rec in 
	select time,field_values from stream 
	where entity_id=value_stream_name and source_id=machine_id
	and time < var_end_time and time > var_start_time
	order by time
	LOOP
		var_time_gap := extract(epoch from rec.time - var_last_time);
		
		var_machinespeed_total := var_time_gap * var_machinespeed_last + var_machinespeed_total;
		var_pumpinvspeed_total := var_time_gap * var_pumpinvspeed_last + var_pumpinvspeed_total;
		var_totalpackcount_total := var_time_gap * var_totalpackcount_last + var_totalpackcount_total;
		var_filmfeedlength_total := var_time_gap * var_filmfeedlength_last + var_filmfeedlength_total;
		var_centersealtime_total := var_time_gap * var_centersealtime_last + var_centersealtime_total;
		var_endsealtime_total := var_time_gap * var_endsealtime_last + var_endsealtime_total;
		var_centersealtemperature_total := var_time_gap * var_centersealtemperature_last + var_centersealtemperature_total;
		var_endsealtemperature_total := var_time_gap * var_endsealtemperature_last + var_endsealtemperature_total;
		var_endremtemppv_total := var_time_gap * var_endremtemppv_last + var_endremtemppv_total;
		
	
		var_last_time := rec.time;
		
		var_machinespeed_last := rec.field_values->>'param_machinespeed';
		var_pumpinvspeed_last := rec.field_values->>'param_pumpinvspeed';
		var_totalpackcount_last := rec.field_values->>'param_totalpackcount';
		var_filmfeedlength_last := rec.field_values->>'recipe_filmfeedlength';
		var_centersealtime_last := rec.field_values->>'recipe_centersealtime';
		var_endsealtime_last := rec.field_values->>'recipe_endsealtime';
		var_centersealtemperature_last := rec.field_values->>'recipe_centersealtemperature';
		var_endsealtemperature_last := rec.field_values->>'recipe_endsealtemperature';
		var_endremtemppv_last := rec.field_values->>'param_endremtemppv';
	END LOOP;

	var_time_gap := extract(epoch from var_end_time - var_last_time);
	
	var_machinespeed_total := var_time_gap * var_machinespeed_last + var_machinespeed_total;
	var_pumpinvspeed_total := var_time_gap * var_pumpinvspeed_last + var_pumpinvspeed_total;
	var_totalpackcount_total := var_time_gap * var_totalpackcount_last + var_totalpackcount_total;
	var_filmfeedlength_total := var_time_gap * var_filmfeedlength_last + var_filmfeedlength_total;
	var_centersealtime_total := var_time_gap * var_centersealtime_last + var_centersealtime_total;
	var_endsealtime_total := var_time_gap * var_endsealtime_last + var_endsealtime_total;
	var_centersealtemperature_total := var_time_gap * var_centersealtemperature_last + var_centersealtemperature_total;
	var_endsealtemperature_total := var_time_gap * var_endsealtemperature_last + var_endsealtemperature_total;
	var_endremtemppv_total := var_time_gap * var_endremtemppv_last + var_endremtemppv_total;
	
	-- RAISE NOTICE 'Final total:(%) and average:(%)', var_total_distince, var_total_distince / duration_in_sec;
	
	var_machinespeed_average_return := var_machinespeed_total / duration_in_sec; 
	var_pumpinvspeed_average_return := var_pumpinvspeed_total / duration_in_sec; 
	var_totalpackcount_average_return := var_totalpackcount_total / duration_in_sec;
	var_filmfeedlength_average_return := var_filmfeedlength_total / duration_in_sec;
	var_centersealtime_average_return := var_centersealtime_total / duration_in_sec;
	var_endsealtime_average_return := var_endsealtime_total / duration_in_sec;
	var_centersealtemperature_average_return := var_centersealtemperature_total / duration_in_sec;
	var_endsealtemperature_average_return := var_endsealtemperature_total / duration_in_sec;
	var_endremtemppv_average_return := var_endremtemppv_total / duration_in_sec;
	
	
	raise notice 'var_machinespeed_average_return: %',var_machinespeed_average_return;
	raise notice 'var_pumpinvspeed_average_return: %', var_pumpinvspeed_average_return;
	raise notice 'var_totalpackcount_average_return: %', var_totalpackcount_average_return;
	raise notice 'var_filmfeedlength_average_return: %',var_filmfeedlength_average_return;
	raise notice 'var_centersealtime_average_return: %', var_centersealtime_average_return;
	raise notice 'var_endsealtime_average_return: %', var_endsealtime_average_return;
	raise notice 'var_centersealtemperature_average_return: %',var_centersealtemperature_average_return;
	raise notice 'var_endsealtemperature_average_return: %', var_endsealtemperature_average_return;
	raise notice 'var_endremtemppv_average_return: %', var_endremtemppv_average_return;
	
	
	
	AVAILABILITY := var_availability_return;
	EFFICIENCY := var_efficiency_return;
	CAPACITYPOTENTIAL := var_availability_return;
	GIVEAWAY := var_giveaway_return;
	REJECTS := var_reject_return;
	GOODPRODUCT := var_good_product_return;
	SDI := var_sdi_return;
	PRODUCTAVERAGE := var_productaverage_return;
	FAULTRATE := var_faultrate_return;
	PERFORMANCE := var_performance_return;
	PLANNEDPRODUCTIONTIME := var_planned_production_time_in_sec;
	MACHINESPEED := var_machinespeed_average_return;
	PUMPSPEED := var_pumpinvspeed_average_return;
	TOTALPACKCOUNT := var_totalpackcount_average_return;
	FILMFEEDLENGTH := var_filmfeedlength_average_return;
	CENTERSEALTIME := var_centersealtime_average_return;
	ENDSEALTIME := var_endsealtime_average_return;
	CENTERSEALTEMP := var_centersealtemperature_average_return;
	ENDSEALTEMP := var_endsealtemperature_average_return;
	ENDREMAININGTEMP := var_endremtemppv_average_return;
	STARTTIME := start_time_string;
	ENDTIME := end_time_string;
	MACHINEID := machine_id;
	RETURN NEXT;
	
end;

$function$
