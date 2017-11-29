CREATE OR REPLACE FUNCTION public.asset_kpi_bytime_shift(value_stream_name character varying, stream_name character varying, machine_id character varying, machine_type character varying, start_time_string character varying, end_time_string character varying, ideal_run_rate integer, shift_name character varying, dailyshiftid character varying)
 RETURNS TABLE(totalcount integer, rejectcount integer)
 LANGUAGE plpgsql
AS $function$
-- value_stream_name: this is the associated value stream on Thing general info page.
-- stream_name: this is the associated stream on Thing general info page.
-- machine_id: this is the Thing name in Thingworx
-- machine_type: Short Name of machine type (VPP, VR8600E, VR86001X, VS)
-- start_time_string: lower bound of time range with format: YYYYMMDDHH24MISS, for example:20170919235959
-- end_time_string: upper bound of time range with format: YYYYMMDDHH24MISS, for example:20170919235959. assume UTC timezone
-- ideal_run_rate: ideal run rate of asset 
-- shift: current shift name (Shift1, Shift2,...)
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
	
	var_count_last	integer;
	var_count_end	integer;
	var_count_return	integer;	-- return value
	var_count_return_e integer;
	var_count_return_1x integer;
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
	
	var_average_machinespeed_return real;
	
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
	
	var_machinespeed_average_return real; 
	var_pumpinvspeed_average_return real; 
	var_totalpackcount_average_return real;
	var_filmfeedlength_average_return real;
	var_centersealtime_average_return real;
	var_endsealtime_average_return real;
	var_centersealtemperature_average_return real;
	var_endsealtemperature_average_return real;
	var_endremtemppv_average_return real;
	
	var_sqlquery varchar;
	var_test_count integer;
	
	var_channels varchar[];
	var_channel_last varchar;
	var_current_channel varchar;
	channel_count integer;
	var_time_string varchar;
	var_channel_details_array varchar[];
	var_channel_details_string varchar;
	channel varchar;
	var_channel varchar;
	var_channel_start_time timestamptz;
	var_channel_end_time timestamptz;
	
	var_total_pack_count_channel real;
	var_reject_return_channel real;
	var_good_product_count_channel real;
	var_giveaway_return_channel real;
	var_sum_lastpackageweight_channel real;
	var_absdeviation_channel real;
	var_good_product_return_channel real;
	var_sdi_return_channel real;
	var_productaverage_return_channel real;
	
	var_ideal_run_rate_channel real;
	available_runtime_in_sec_channel real;
	var_performance_return_channel real;

	prerec_cycle record;
	prerec_param record;

	rec_cycle record;
	rec_param record;

	var_efficiency_count real;
	var_deviation_count real;
	var_counter real;
	

begin
	select into var_end_time (to_timestamp(end_time_string,'YYYYMMDDHH24MISS')::timestamp with time zone) ;
	select into var_start_time (to_timestamp(start_time_string,'YYYYMMDDHH24MISS')::timestamp with time zone) ;
	duration_in_sec := extract('epoch' from (var_end_time - var_start_time));
	
	

	IF duration_in_sec <=0 then
		RETURN;
	END IF;
	
	
	
	if machine_type = 'VPP' then
	
	
	
		------------------------- CHANNEL BASED ----------------------
			
			
		var_channel_last := 0;
		for prerec in 
		select field_values from stream 
		where entity_id=stream_name and source_id=machine_id
		and time <= var_start_time
		order by time desc limit 1
		LOOP
			--raise notice 'prerec: %', prerec.field_values;
			var_channel_last := prerec.field_values->>'recipe_channelnumber';
		END LOOP;
		
		
		var_last_time := var_start_time;
		channel_count := 1;
		
		-- get all channels in time range
		for rec in 
		select time, field_values from stream 
		where entity_id=stream_name and source_id=machine_id
		and time < var_end_time and time > var_start_time
		order by time
		LOOP
			var_current_channel := rec.field_values->>'recipe_channelnumber'; -- need string to real convertion?
			if var_current_channel <> var_channel_last then
				
				var_channels[channel_count] := ARRAY[var_channel_last,var_last_time::varchar, rec.time::varchar];
				var_last_time := rec.time;
				channel_count := channel_count + 1;
				
			end if;
			var_channel_last := var_current_channel;
			
		END LOOP;
		
		-- get last channel info
		var_channels[channel_count] := ARRAY[var_channel_last,var_last_time::varchar, var_end_time];
					
		channel_count := 1;
		
		foreach channel in 
			array var_channels
		LOOP
			var_channel_details_string := var_channels[channel_count];
			
			
			var_channel_details_array := string_to_array(substring(var_channel_details_string from 2 for (char_length(var_channel_details_string) -2)), ',');
			
			var_channel := var_channel_details_array[1];
			var_channel_start_time := var_channel_details_array[2]::timestamp with time zone;
			var_channel_end_time := var_channel_details_array[3]::timestamp with time zone;
			
			
			--Property Name: param_totalpackcount
			var_count_last := 0;
			for prerec in 
			select field_values from stream 
			where entity_id=stream_name and source_id=machine_id
			and time <= var_channel_start_time
			order by time desc limit 1
			LOOP
			var_count_last := prerec.field_values->>'param_totalpackcount';
			END LOOP;
		
			var_count_end := var_count_last;
			
			for rec in 
			select field_values from stream 
			where entity_id=stream_name and source_id=machine_id
			and time < var_channel_end_time and time > var_channel_start_time
			order by time desc limit 1
			LOOP
			var_count_end := rec.field_values->>'param_totalpackcount'; -- need string to real convertion?
			END LOOP;
			
			
			var_total_pack_count_channel := var_count_end - var_count_last;
	
			--default values
			var_reject_return_channel := 0.0;
			var_good_product_count_channel := 0.0;
			var_giveaway_return_channel := 0.0;
			var_sum_lastpackageweight_channel := 0.0;
			var_absdeviation_channel := 0.0;
			
			
			for rec in 
				select time,field_values from stream 
				where entity_id=stream_name and source_id=machine_id
				and time < var_channel_end_time and time > var_channel_start_time
				order by time
			LOOP
				
				-- Give Away
				if rec.field_values->>'state_machinerunning' = 'true' then
					var_current_giveaway := (rec.field_values->>'param_lastpackageweight')::real - (rec.field_values->>'recipe_producttargetweight')::real;
					if var_current_giveaway > 0 then
						var_giveaway_return_channel := var_giveaway_return_channel + var_current_giveaway;
					end if;
					
					raise notice 'rec.field_values->>param_reject: %', rec.field_values->>'param_reject';
					raise notice 'rec.field_values->>param_totalpackcount: %', rec.field_values->>'param_totalpackcount';
					--Reject
					if rec.field_values->>'param_reject' in ('1','2') then
							var_reject_return_channel := var_reject_return_channel + 1;
					end if;
					
					--Good Product
					if rec.field_values->>'param_reject' = '0' then
							var_good_product_count_channel := var_good_product_count_channel + 1;
					end if;
					
					--SDI
					var_absdeviation_channel := var_absdeviation_channel + abs((rec.field_values->>'param_lastpackageweight')::real - (rec.field_values->>'recipe_producttargetweight')::real);
		
					--Product Average
					var_sum_lastpackageweight_channel := var_sum_lastpackageweight_channel + (rec.field_values->>'param_lastpackageweight')::real;
		
				end if;
			
			END LOOP;
			
			
			if var_total_pack_count_channel > 0 then
				-- raise notice 'var_good_product_count: %', var_good_product_count_channel;
				--raise notice 'var_total_pack_count: %', var_total_pack_count;
				-- raise notice 'var_good_product_count / var_total_pack_count: %', var_good_product_count / var_total_pack_count;
				var_good_product_return_channel := var_good_product_count_channel / var_total_pack_count_channel * 100;
			 	var_sdi_return := var_absdeviation_channel / var_total_pack_count_channel;
			 	var_productaverage_return := var_sum_lastpackageweight_channel / var_total_pack_count_channel;
			else 	
				var_good_product_return_channel := 0;
		        var_sdi_return_channel := 0;
		        var_productaverage_return_channel := 0;
			end if;
			
			raise notice '------------------------------------------- CHANNEL % --------------------------------------', var_channel;
			raise notice 'var_total_pack_count_channel: %', var_total_pack_count_channel;
			raise notice 'var_good_product_return: %', var_good_product_return_channel;
			raise notice 'var_sdi_return: %', var_sdi_return_channel;
			raise notice 'var_productaverage_return: %', var_productaverage_return_channel;
			raise notice 'var_giveaway_return: %', var_giveaway_return_channel;
			raise notice 'var_reject_return: %', var_reject_return_channel;
		
		
			
		
			------------------------------ Performance ----------------------------------
			
			-- get ideal run rate
--			select idealrunrate
--			into var_ideal_run_rate_channel
--			from public.irrconfig
--			where asset_id = machine_id; 
			
			var_ideal_run_rate_channel := ideal_run_rate;
			
			--	    -- Property_Name: state_machinerunning
			var_last_value := '0'; -- setup default value.
			for prerec in
				select field_values from stream 
				where entity_id=stream_name and source_id=machine_id
				and time <= var_channel_start_time
				order by time desc limit 1
			LOOP
				var_last_value := prerec.field_values->>'state_machinerunning';
			END LOOP;
			var_last_time := var_channel_start_time;	-- setup start time in loop.
		
			available_runtime_in_sec_channel = 0.0;
			
			for rec in 
				select time,field_values from stream 
				where entity_id=stream_name and source_id=machine_id
				and time < var_channel_end_time and time > var_channel_start_time
				order by time
			LOOP
				-- -- raise notice '%:% - %:%', var_last_time, var_last_value, rec.time, rec.property_value;
				if var_last_value = 'true' then
					available_runtime_in_sec_channel := extract(epoch from rec.time - var_last_time)+ available_runtime_in_sec_channel;
				END IF;
				var_last_time := rec.time;
				var_last_value := rec.field_values->>'state_machinerunning';
			END LOOP;
			-- add tail time.
			if var_last_value = '1' then
				available_runtime_in_sec_channel := extract(epoch from var_end_time - var_last_time)+ available_runtime_in_sec_channel;
			END IF;
			
			
			if available_runtime_in_sec_channel <= 0.0 then
				var_performance_return_channel := 0.0;
			ELSEIF var_ideal_run_rate_channel <= 0.0 then
				var_performance_return_channel := 0.0;
			ELSE
				var_performance_return_channel := ((var_total_pack_count_channel * 60 /available_runtime_in_sec_channel) / var_ideal_run_rate_channel) * 100;
			END IF;
			
			raise notice 'var_performance_return_channel: %', var_performance_return_channel;
		
		
		
			var_sqlquery := 'insert into cognipro.channel_kpiresults(dailyshift_id,
																	shiftname,
																	machine_id,
																	channel,
																	starttime,
																	endtime,
																	kpi_giveaway,
																	kpi_reject,
																	kpi_goodproduct,
																	kpi_sdi,
																	kpi_productaverage,
																	kpi_performance) 
													values(''' || dailyshiftid ||''', 
														   ''' || shift_name||''',
														   ''' || machine_id||''',
															 ' || var_channel::int||',
														   ''' || var_channel_start_time || ''',
														   ''' || var_channel_end_time || ''',
															 ' || var_giveaway_return_channel || ',
															 ' || var_reject_return_channel ||', 
															 ' || var_good_product_return_channel || ', 
															 ' || var_sdi_return_channel || ', 
															 ' || var_productaverage_return_channel ||',
														     ' || var_performance_return_channel || ');';
		---- raise notice 'var_sqlquery: %', var_sqlquery;
		perform dblink_exec('ExternalConnection', var_sqlquery);
		
		
		
			channel_count := channel_count + 1;
	
		
		end loop;
	
		-------------------------------- SHIFT CALCS ----------------------------------------------------
		
		
		----------------------------- Efficiency -------------------------------------
	
	    -- Property_Name: state_machinerunning
		var_last_value := '0'; -- setup default value.
		for prerec in
			select field_values from stream 
			where entity_id=stream_name and source_id=machine_id
			and time <= var_start_time
			order by time desc limit 1
		LOOP
			var_last_value := prerec.field_values->>'state_machinerunning';
		END LOOP;
		var_last_time := var_start_time;	-- setup start time in loop.
	
		available_runtime_in_sec = 0.0;
		
		for rec in 
			select time,field_values from stream 
			where entity_id=stream_name and source_id=machine_id
			and time < var_end_time and time > var_start_time
			order by time
		LOOP
			-- -- raise notice '%:% - %:%', var_last_time, var_last_value, rec.time, rec.property_value;
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
		-- -- raise notice 'End at:%', now();
		var_efficiency_return := available_runtime_in_sec / duration_in_sec;
		
		-- raise notice 'var_efficiency_return: %', var_efficiency_return;
		------------------------------ Availability ---------------------------------
		
		var_last_stop_val := '0';
		
		select field_values->>'state_machinestopped' from stream 
		into var_last_stop_val
		where entity_id=stream_name and source_id=machine_id
		and time <= var_start_time
		order by time desc limit 1;
		
		
		var_last_time := var_start_time;	-- setup start time in loop.
		available_stoptime_in_sec = 0.0;
		for rec in 
			select time,field_values from stream 
			where entity_id=stream_name and source_id=machine_id
			and time < var_end_time and time > var_start_time
			order by time
		LOOP
			
			if var_last_stop_val = 'true' then
				available_stoptime_in_sec := extract(epoch from rec.time - var_last_time)+ available_stoptime_in_sec;
			end if;
			
			
			var_last_time := rec.time;
			var_last_run_val := rec.field_values->>'state_machinestopped';
		
		END LOOP;
		
		-- add tail time.
		if var_last_stop_val = 'true' then
			available_stoptime_in_sec := extract(epoch from rec.time - var_last_time)+ available_stoptime_in_sec;
		end if;
	
		-- -- raise notice 'End at:%', now();
		var_availability_return := (available_runtime_in_sec + available_stoptime_in_sec) / duration_in_sec;
		
		-- raise notice 'var_availability_return: %', var_availability_return;
		------------------------Cycle Dependent KPIs----------------------------

		
		--Property Name: param_totalpackcount
		var_count_last := 0;
		for prerec in 
		select field_values from stream 
		where entity_id=stream_name and source_id=machine_id
		and time <= var_start_time
		order by time desc limit 1
		LOOP
		var_count_last := prerec.field_values->>'param_totalpackcount';
		END LOOP;
	
		var_count_end := var_count_last;
		
		for rec in 
		select field_values from stream 
		where entity_id=stream_name and source_id=machine_id
		and time < var_end_time and time > var_start_time
		order by time desc limit 1
		LOOP
		var_count_end := rec.field_values->>'param_totalpackcount'; -- need string to real convertion?
		END LOOP;
		
		
		var_total_pack_count := var_count_end - var_count_last;

		raise notice 'var_total_pack_count: %', var_total_pack_count;
		--default values
		var_reject_return := 0.0;
		var_good_product_count := 0.0;
		var_giveaway_return := 0.0;
		var_sum_lastpackageweight := 0.0;
		var_absdeviation := 0.0;
		var_test_count := 0;
		for rec in 
			select time,field_values from stream 
			where entity_id=stream_name and source_id=machine_id
			and time < var_end_time and time > var_start_time
			order by time
		LOOP
			
			-- Give Away
			if rec.field_values->>'state_machinerunning' = 'true' then
				var_test_count := var_test_count + 1;
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
		raise notice 'var_test_count: %', var_test_count;
		if var_total_pack_count > 0 then
			-- raise notice 'var_good_product_count: %', var_good_product_count;
			-- raise notice 'var_total_pack_count: %', var_total_pack_count;
			-- raise notice 'var_good_product_count / var_total_pack_count: %', var_good_product_count / var_total_pack_count;
			var_good_product_return := var_good_product_count / var_total_pack_count * 100;
		 	var_sdi_return := var_absdeviation / var_total_pack_count;
		 	var_productaverage_return := var_sum_lastpackageweight / var_total_pack_count;
		else 	
			var_good_product_return := 0;
	        var_sdi_return := 0;
	        var_productaverage_return := 0;
		end if;
		
		-- raise notice 'var_good_product_return: %', var_good_product_return;
		-- raise notice 'var_sdi_return: %', var_sdi_return;
		-- raise notice 'var_productaverage_return: %', var_productaverage_return;
		-- raise notice 'var_giveaway_return: %', var_giveaway_return;
		-- raise notice 'var_reject_return: %', var_reject_return;
		
		------------------------------ Fault Rate ---------------------------------
		-- NEED TO DETERMINE IF GRANULARITY CALC OR REALTIME TO DETERMINE START TIME
		var_last_value := '0'; -- setup default value.
		for prerec in
			select time,field_values from stream 
			where entity_id=stream_name and source_id=machine_id
			and time <= var_start_time
			order by time desc limit 1
		LOOP
			var_last_value := prerec.field_values->>'state_machinefaulted';
		END LOOP;
		var_last_time := var_start_time;	-- setup start time in loop.
	
		available_faulttime_in_sec = 0.0;
		
		for rec in 
			select time,field_values from stream 
			where entity_id=stream_name and source_id=machine_id
			and time < var_end_time and time > var_start_time
			order by time
		LOOP
			-- -- raise notice '%:% - %:%', var_last_time, var_last_value, rec.time, rec.property_value;
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
		-- -- raise notice 'End at:%', now();
		var_faultrate_return := available_faulttime_in_sec / duration_in_sec;
		
		-- raise notice 'var_faultrate_return: %', var_faultrate_return;
		
		------------------------------ Performance ----------------------------------
		
		for rec in
		select field_values from stream 
		where entity_id=stream_name and source_id=machine_id
		and time < var_end_time
		order by time desc limit 1
		LOOP
			--raise notice 'prerec: %', prerec.field_values;
			var_channel_last := prerec.field_values->>'recipe_channelnumber';
		END LOOP;
		
--		select idealrunrate
--		into var_idealrunrate
--		from public.irrconfig
--		where asset_id = machine_id
--		and channelnumber = var_channel_last::real;
		
		var_idealrunrate := ideal_run_rate;
		
		if available_runtime_in_sec <= 0.0 then
			var_performance_return := 0.0;
		ELSEIF var_idealrunrate <= 0.0 then
			var_performance_return := 0.0;
		ELSE
			var_performance_return := ((var_total_pack_count * 60 /available_runtime_in_sec) / var_idealrunrate) * 100;
		END IF;
		
		-- raise notice 'var_performance_return: %', var_performance_return;
		---------------------Capaciy Potential----------------------------------
		var_capacity_potential_return := 100 - var_performance_return;
		
		-- raise notice 'var_capacity_potential_return: %', var_capacity_potential_return;
		
		--------------------------- Averages -------------------------------------
		var_machinespeed_last := 0.0;
		var_pumpinvspeed_last := 0.0;
		var_filmfeedlength_last := 0.0;
		var_centersealtime_last := 0.0;
		var_endsealtime_last := 0.0;
		var_centersealtemperature_last := 0.0;
		var_endsealtemperature_last := 0.0;
		var_endremtemppv_last := 0.0;
		
		for prerec in 
		select time,field_values from stream 
		where entity_id=stream_name and source_id=machine_id
		and time <= var_start_time
		order by time desc limit 1
		LOOP
			var_machinespeed_last := prerec.field_values->>'param_machinespeed';
			var_pumpinvspeed_last := prerec.field_values->>'param_pumpinvspeed';
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
		var_filmfeedlength_total := 0.0;
		var_centersealtime_total := 0.0;
		var_endsealtime_total := 0.0;
		var_centersealtemperature_total := 0.0;
		var_endsealtemperature_total := 0.0;
		var_endremtemppv_total := 0.0;
		
		for rec in 
		select time,field_values from stream 
		where entity_id=stream_name and source_id=machine_id
		and time < var_end_time and time > var_start_time
		order by time
		LOOP
			var_time_gap := extract(epoch from rec.time - var_last_time);
			
			var_machinespeed_total := var_time_gap * var_machinespeed_last + var_machinespeed_total;
			var_pumpinvspeed_total := var_time_gap * var_pumpinvspeed_last + var_pumpinvspeed_total;
			var_filmfeedlength_total := var_time_gap * var_filmfeedlength_last + var_filmfeedlength_total;
			var_centersealtime_total := var_time_gap * var_centersealtime_last + var_centersealtime_total;
			var_endsealtime_total := var_time_gap * var_endsealtime_last + var_endsealtime_total;
			var_centersealtemperature_total := var_time_gap * var_centersealtemperature_last + var_centersealtemperature_total;
			var_endsealtemperature_total := var_time_gap * var_endsealtemperature_last + var_endsealtemperature_total;
			var_endremtemppv_total := var_time_gap * var_endremtemppv_last + var_endremtemppv_total;
			
		
			var_last_time := rec.time;
			
			var_machinespeed_last := rec.field_values->>'param_machinespeed';
			var_pumpinvspeed_last := rec.field_values->>'param_pumpinvspeed';
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
		var_filmfeedlength_total := var_time_gap * var_filmfeedlength_last + var_filmfeedlength_total;
		var_centersealtime_total := var_time_gap * var_centersealtime_last + var_centersealtime_total;
		var_endsealtime_total := var_time_gap * var_endsealtime_last + var_endsealtime_total;
		var_centersealtemperature_total := var_time_gap * var_centersealtemperature_last + var_centersealtemperature_total;
		var_endsealtemperature_total := var_time_gap * var_endsealtemperature_last + var_endsealtemperature_total;
		var_endremtemppv_total := var_time_gap * var_endremtemppv_last + var_endremtemppv_total;
		
		-- -- raise notice 'Final total:(%) and average:(%)', var_total_distince, var_total_distince / duration_in_sec;
		
		var_machinespeed_average_return := var_machinespeed_total / duration_in_sec; 
		var_pumpinvspeed_average_return := var_pumpinvspeed_total / duration_in_sec; 
		var_filmfeedlength_average_return := var_filmfeedlength_total / duration_in_sec;
		var_centersealtime_average_return := var_centersealtime_total / duration_in_sec;
		var_endsealtime_average_return := var_endsealtime_total / duration_in_sec;
		var_centersealtemperature_average_return := var_centersealtemperature_total / duration_in_sec;
		var_endsealtemperature_average_return := var_endsealtemperature_total / duration_in_sec;
		var_endremtemppv_average_return := var_endremtemppv_total / duration_in_sec;
		
		
		-- raise notice 'var_machinespeed_average_return: %',var_machinespeed_average_return;
		-- raise notice 'var_pumpinvspeed_average_return: %', var_pumpinvspeed_average_return;
		-- raise notice 'var_filmfeedlength_average_return: %',var_filmfeedlength_average_return;
		-- raise notice 'var_centersealtime_average_return: %', var_centersealtime_average_return;
		-- raise notice 'var_endsealtime_average_return: %', var_endsealtime_average_return;
		-- raise notice 'var_centersealtemperature_average_return: %',var_centersealtemperature_average_return;
		-- raise notice 'var_endsealtemperature_average_return: %', var_endsealtemperature_average_return;
		-- raise notice 'var_endremtemppv_average_return: %', var_endremtemppv_average_return;
		
		
		
		-------------------------------------- Insert Values into Table --------------------------------
		
		var_sqlquery := 'insert into cognipro.shift_kpiresults(machine_id,
															starttime,
															endtime,
															shiftname,
															dailyshift_id,
															kpi_efficiency,
															kpi_availability,
															kpi_giveaway,
															kpi_reject,
															kpi_goodproduct,
															kpi_sdi,
															kpi_productaverage,
															kpi_faultrate,
															kpi_performance,
															kpi_capacitypotential,
															kpi_throughput,
															kpi_vacuumdeviation,
															kpi_throughputcycles,
															param_vacreached,
															param_machinespeed,
															param_centersealtemppv,
															param_endremtemppv,
															param_endsealtemppv,
															param_pumpinvspeed,
															param_totalpackcount,
															recipe_centersealtime,
															recipe_endsealtime,
															recipe_filmfeedlength,
															param_speedcpm,
															param_lifetimecycles,
															param_lifetimecycle,
															param_productcount,
															kpi_planprodtime) 
													values(''' || machine_id ||''', 
														   ''' || var_start_time||''',
														   ''' || var_end_time||''',
														   ''' || shift_name || ''',
														   ''' || dailyshiftid || ''',
															 ' || var_efficiency_return ||',
															 ' || var_availability_return ||',
															 ' || var_giveaway_return ||',
															 ' || var_reject_return ||',
															 ' || var_good_product_return ||',
															 ' || var_sdi_return || ',
															 ' || var_productaverage_return ||',
															 ' || var_faultrate_return ||',
															 ' || var_performance_return ||',
															 ' || var_capacity_potential_return ||',
															 0,0,0,0,
															 ' || var_machinespeed_average_return ||',
															 ' || var_centersealtemperature_average_return ||',
															 ' || var_endremtemppv_average_return ||',
															 ' || var_endsealtemperature_average_return ||',
															 ' || var_pumpinvspeed_average_return ||',
															 ' || var_total_pack_count ||',
															 ' || var_centersealtime_average_return ||',
															 ' || var_endsealtime_average_return ||',
														     ' || var_filmfeedlength_average_return ||',0,0,0,0,0);';
		---- raise notice 'var_sqlquery: %', var_sqlquery;
		perform dblink_exec('ExternalConnection', var_sqlquery);
		
		TOTALCOUNT := var_total_pack_count;
		REJECTCOUNT := var_reject_return;
		
		
		
	elseif machine_type = 'VR8600E' or machine_type = 'VR86001X' then
	
		----------------------------    Average Param_speedcpm Calculation ---------------
		raise notice 'machine_id: %', machine_id;
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
	
		var_average_machinespeed_return := var_total / duration_in_sec;
	
		---------------------------------------------- Cycle Count --------------------------------------------
		var_count_return_e := 0;
		var_count_return_1x := 0;
		
		if machine_type = 'VR8600E' then
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
			var_count_return_e = var_count_end - var_count_last;
	
		elseif machine_type = 'VR86001X' then
			-- Property_Name: param_lifetimecycles
			var_count_last := 0;
			for prerec in 
			select time, property_value from value_stream
			where entity_id=value_stream_name and source_id = machine_id and property_name='param_lifetimecycles'
			and time <= var_start_time
			order by time desc limit 1
			LOOP
				var_count_last := prerec.property_value;
			END LOOP;
		
			var_count_end := var_count_last;
			for rec in 
			select time, property_value from value_stream
			where entity_id=value_stream_name and source_id = machine_id and property_name='param_lifetimecycles'
			and time < var_end_time and time > var_start_time
			order by time desc limit 1
			LOOP
				var_count_end := rec.property_value; -- need string to real convertion?
			END LOOP;
			var_count_return_1x = var_count_end - var_count_last;
		end if;
		
		----------------------------- Product Count --------------------------------------

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
	
		----------------------------- Throughput -------------------------------------
		-- Property_Name: param_productcount
		var_throughput_return := var_productcount_return * 60 / duration_in_sec;
		
	
		------------------------------------- Availability ---------------------------------------

		var_last_value := '0'; -- setup default value.
		for prerec in
			select time, property_value from value_stream 
			where entity_id=value_stream_name and source_id=machine_id and property_name='state_all'
			and time <= var_start_time
			order by time desc limit 1
		LOOP
			var_last_value := prerec.property_value;
		END LOOP;
		var_last_time := var_start_time;	-- setup start time in loop.
	
		available_runtime_in_sec = 0.0;
		available_stoptime_in_sec = 0.0;
		for rec in 
			select time, property_value from value_stream 
			where entity_id=value_stream_name and source_id=machine_id and property_name='state_all'
			and time < var_end_time and time > var_start_time
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
		var_availability_return := (available_runtime_in_sec+available_stoptime_in_sec)/duration_in_sec;
		
		
		
		------------------------------------------ Capacity Potential ------------------------------------------------------------

--		select idealrunrate
--		into var_idealrunrate
--		from public.irrconfig
--		where asset_id = machine_id
--		and channelnumber = 1;
		
		var_idealrunrate := ideal_run_rate;
		
		if available_runtime_in_sec <= 0.0 then
			var_capacity_potential_return := 0.0;
		ELSEIF var_idealrunrate <= 0.0 then
			var_capacity_potential_return := 0.0;
		ELSE
			var_capacity_potential_return := 1.0 - ((var_productcount_return * 60 /available_runtime_in_sec) / var_idealrunrate);
		END IF;
		
		
		
		----------------------------- Efficiency -------------------------------------

		if machine_type = 'VR8600E' then
		
			if var_count_return_e > 0 then
				var_efficiency_return := var_productcount_return * 1.0 / var_count_return_e;
			ELSE
				var_efficiency_return := 0.0;
			END IF;
			
		elseif machine_type = 'VR86001X' then
		
			if var_count_return_1x > 0 then
				var_efficiency_return := var_productcount_return * 1.0 / var_count_return_1x;
			ELSE
				var_efficiency_return := 0.0;
			END IF;
		
		end if;
		
		
		---------------------------------------- Insert Into Kpi Table--------------------------------------
	
		var_sqlquery := 'insert into cognipro.shift_kpiresults(machine_id,
															starttime,
															endtime,
															shiftname,
															dailyshift_id,
															kpi_efficiency,
															kpi_availability,
															kpi_giveaway,
															kpi_reject,
															kpi_goodproduct,
															kpi_sdi,
															kpi_productaverage,
															kpi_faultrate,
															kpi_performance,
															kpi_capacitypotential,
															kpi_throughput,
															kpi_vacuumdeviation,
															kpi_throughputcycles,
															param_vacreached,
															param_machinespeed,
															param_centersealtemppv,
															param_endremtemppv,
															param_endsealtemppv,
															param_pumpinvspeed,
															param_totalpackcount,
															recipe_centersealtime,
															recipe_endsealtime,
															recipe_filmfeedlength,
															param_speedcpm,
															param_lifetimecycles,
															param_lifetimecycle,
															param_productcount,
															kpi_planprodtime) 
													values(''' || machine_id ||''',
														   ''' || var_start_time||''',
														   ''' || var_end_time||''',
														   ''' || shift_name || ''',
														   ''' || dailyshiftid || ''',
															 ' || var_efficiency_return ||',
															 ' || var_availability_return ||',
															 0,0,0,0,0,0,0,
															 ' || var_capacity_potential_return ||',
															 ' || var_throughput_return || ',
															 0,0,0,0,0,0,0,0,0,0,0,0,
															 ' || var_average_machinespeed_return ||',
															 ' || var_count_return_1x || ', 
															 ' || var_count_return_e || ',
														     ' || var_productcount_return ||',0);';
		
														     
--		raise notice 'machine_id: %', machine_id;												     
--		raise notice 'var_start_time: %', var_start_time;												     
--		raise notice 'var_end_time: %', var_end_time;												     
--		raise notice 'shift_name: %', shift_name;												     
--		raise notice 'var_efficiency_return: %', var_efficiency_return;												     
--		raise notice 'var_availability_return: %', var_availability_return;
--		raise notice 'var_capacity_potential_return: %', var_capacity_potential_return;												     
--		raise notice 'var_throughput_return: %', var_throughput_return;												     
--		raise notice 'var_average_machinespeed_return: %', var_average_machinespeed_return;												     
--		raise notice 'var_count_return_1x: %', var_count_return_1x;												     
--		raise notice 'var_count_return_e: %', var_count_return_e;												     
--		raise notice 'var_productcount_return: %', var_productcount_return;												     
--
--
--     	raise notice 'var_sqlquery: %', var_sqlquery;
		perform dblink_exec('ExternalConnection', var_sqlquery);
		
		TOTALCOUNT := var_productcount_return;
		REJECTCOUNT := 0;
		
		
		
		
		
		
		
		
		
		
	elseif machine_type = 'VS' then
		
		---------------------------------------------- Cycle Count --------------------------------------------

		-- Property_Name: param_lifetimecycles
		var_count_last := 0;
		for prerec in 
		select time, property_value from value_stream
		where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_VacComplete'
		and time <= var_start_time
		order by time desc limit 1
		LOOP
		var_count_last := prerec.property_value::json->'rows'->0->>'param_lifetimecycles';
		END LOOP;
	
		var_count_end := var_count_last;
		for rec in 
		select time, property_value from value_stream
		where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_VacComplete'
		and time < var_end_time and time > var_start_time
		order by time desc limit 1
		LOOP
		var_count_end := rec.property_value::json->'rows'->0->>'param_lifetimecycles'; -- need string to real convertion?
		END LOOP;
		var_count_return = var_count_end - var_count_last;
	
		
		----------------------------- Throughput -------------------------------------

		-- Property_Name: param_lifetimecycles
		var_throughput_return := var_count_return::real * 60 / duration_in_sec;
	
		var_throughputcycles_return := var_count_return::real * 60 / duration_in_sec;
		
		
		------------------------------------- Availability ---------------------------------------

		var_last_run_val := '0'; -- setup default value.
		var_last_stop_val := '0';
		var_last_alarm_val := '0';
	
		select property_value from value_stream
		into var_last_run_val
		where entity_id=value_stream_name and source_id=machine_id and property_name='state_run'
		and time <= var_start_time
		order by time desc limit 1;
		
		select property_value from value_stream
		into var_last_stop_val
		where entity_id=value_stream_name and source_id=machine_id and property_name='state_stop'
		and time <= var_start_time
		order by time desc limit 1;
		
		select property_value from value_stream
		into var_last_alarm_val
		where entity_id=value_stream_name and source_id=machine_id and property_name='state_alarm'
		and time <= var_start_time
		order by time desc limit 1;
		
		var_last_run_time := var_start_time;	-- setup start time in loop.
		var_last_stop_time := var_start_time;	-- setup start time in loop.
		var_last_alarm_time := var_start_time;	-- setup start time in loop.

	
		available_runtime_in_sec = 0.0;
		available_stoptime_in_sec = 0.0;
		available_alarmtime_in_sec = 0.0;
	
		for rec in 
			select time, property_value from value_stream 
			where entity_id=value_stream_name and source_id=machine_id and property_name='state_run'
			and time < var_end_time and time > var_start_time
			order by time
		LOOP
			
			-- RAISE NOTICE '%:% - %:%', var_last_time, var_last_value, rec.time, rec.property_value;
			if var_last_run_val = 'true' then
				available_runtime_in_sec := extract(epoch from rec.time - var_last_run_time)+ available_runtime_in_sec;
			end if;
			
			var_last_run_time := rec.time;
			var_last_run_val := rec.property_value;
		
		END LOOP;
		
		for rec in 
			select time, property_value from value_stream 
			where entity_id=value_stream_name and source_id=machine_id and property_name='state_stop'
			and time < var_end_time and time > var_start_time
			order by time
		LOOP
			
			if var_last_stop_val = 'true' then
				available_stoptime_in_sec := extract(epoch from rec.time - var_last_stop_time)+ available_stoptime_in_sec;
			end if;
			
			
			var_last_stop_time := rec.time;
			var_last_stop_val := rec.property_value;
		
		END LOOP;
		
		for rec in 
			select time, property_value from value_stream 
			where entity_id=value_stream_name and source_id=machine_id and property_name='state_alarm'
			and time < var_end_time and time > var_start_time
			order by time
		LOOP
			
			if var_last_alarm_val = 'true' then
				available_alarmtime_in_sec := extract(epoch from rec.time - var_last_alarm_time) + available_alarmtime_in_sec;
			end if;
			
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
		-- raise notice 'End at:%', now();
		var_availability_return := (available_runtime_in_sec + available_stoptime_in_sec - available_alarmtime_in_sec)/duration_in_sec;
	

		
		------------------------------------------ Capacity Potential ------------------------------------------------------------

--		select idealrunrate
--		into var_idealrunrate
--		from public.irrconfig
--		where asset_id = machine_id
--		and channelnumber = 1;
		
		var_idealrunrate := ideal_run_rate;
		
		if available_runtime_in_sec <= 0.0 then
			var_capacity_potential_return := 0.0;
		ELSEIF var_idealrunrate <= 0.0 then
			var_capacity_potential_return := 0.0;
		ELSE
			var_capacity_potential_return := 1.0 - ((var_count_return * 60 /available_runtime_in_sec) / var_idealrunrate);
		END IF;
		
		
		-------------------------------------- Efficiency -------------------------------------

		-- Property_Name: param_utillizationtotal --- Cycle Based Strict Average
		
		var_efficiency_count := 0;
		var_utillizationtotal_last := 0.0;

		for prerec_cycle in 
		select time, property_value from value_stream
		where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_VacComplete'
		and time <= var_start_time
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
		and time < var_end_time and time > var_start_time
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



















--Weighted Average
--		var_utillizationtotal_last := 0.0;
--		
--		for prerec in 
--		select time, property_value from value_stream
--		where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_ProductLoadDone' and property_value::json->'rows'->0->>'param_utillizationtotal' <> '999'
--		and time <= var_start_time
--		order by time desc limit 1
--		LOOP
--			raise notice 'time: %', prerec.time;
--			var_utillizationtotal_last := prerec.property_value::json->'rows'->0->>'param_utillizationtotal';
--		END LOOP;
--		raise notice 'var_utillizationtotal_last: %', var_utillizationtotal_last;
--		
--		var_last_time := var_start_time;
--		var_total := 0.0;
--		
--		raise notice 'var_end_time: %', var_end_time;
--		
--		for rec in 
--		select time, property_value from value_stream
--		where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_ProductLoadDone' and property_value::json->'rows'->0->>'param_utillizationtotal' <> '999'
--		and time < var_end_time and time > var_start_time
--		order by time
--		LOOP
--			raise notice 'param_utillizationtotal: %', rec.property_value::json->'rows'->0->>'param_utillizationtotal';
--			var_time_gap := extract(epoch from rec.time - var_last_time);
--			var_total := var_time_gap * var_utillizationtotal_last + var_total;
--		
--			var_last_time := rec.time;
--			var_utillizationtotal_last := rec.property_value::json->'rows'->0->>'param_utillizationtotal'; -- need string to real convertion?
--		END LOOP;
--	
--		var_total := extract(epoch from var_end_time - var_last_time) * var_utillizationtotal_last + var_total;
-- RAISE NOTICE 'Final total:(%) and average:(%)', var_total_distince, var_total_distince / duration_in_sec;
--		
--		var_efficiency_return := var_total / duration_in_sec;	
--		
--		raise notice 'var_efficiency_return!!!: %', var_efficiency_return;
		
		
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
		
		
		
		---------------------------- Vacuum Reached ----------------------------

		-- Cycle Based Strict Average		

		var_vacreached_last := 0.0;
		for prerec in 
		select time, property_value from value_stream
		where entity_id=value_stream_name and source_id = machine_id and property_name='infotable_VacComplete'
		and time <= var_start_time
		order by time desc limit 1
		LOOP
			var_vacreached_last := prerec.property_value::json->'rows'->0->>'param_vacreached';
		END LOOP;
	
	
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
		-- RAISE NOTICE 'Final total:(%) and average:(%)', var_total_distince, var_total_distince / duration_in_sec;
	
		var_cyclesperminute_return := var_total / duration_in_sec;
		
		
		---------------------------------------- Insert Into Kpi Table ---------------------------------------------------
		
		
		var_sqlquery := 'insert into cognipro.shift_kpiresults(machine_id,
															starttime,
															endtime,
															shiftname,
															dailyshift_id,
															kpi_efficiency,
															kpi_availability,
															kpi_giveaway,
															kpi_reject,
															kpi_goodproduct,
															kpi_sdi,
															kpi_productaverage,
															kpi_faultrate,
															kpi_performance,
															kpi_capacitypotential,
															kpi_throughput,
															kpi_vacuumdeviation,
															kpi_throughputcycles,
															param_vacreached,
															param_machinespeed,
															param_centersealtemppv,
															param_endremtemppv,
															param_endsealtemppv,
															param_pumpinvspeed,
															param_totalpackcount,
															recipe_centersealtime,
															recipe_endsealtime,
															recipe_filmfeedlength,
															param_speedcpm,
															param_lifetimecycles,
															param_lifetimecycle,
															param_productcount,
															kpi_planprodtime) 
													values(''' || machine_id ||''', 
														   ''' || var_start_time||''',
														   ''' || var_end_time||''',
														   ''' || shift_name || ''',
														   ''' || dailyshiftid || ''',
															 ' || var_efficiency_return ||',
															 ' || var_availability_return ||',
															 0,0,0,0,0,0,0,
															 ' || var_capacity_potential_return ||',
															 ' || var_throughput_return || ',
															 ' || var_deviation_return ||',
															 ' || var_throughputcycles_return ||', 
															 ' || var_vacreached_return ||',
															 0,0,0,0,0,0,0,0,0,
															 ' || var_cyclesperminute_return ||',
															 0,0,0,0);';
		
					
--		raise notice 'machine_id: %', machine_id;												     
--		raise notice 'var_start_time: %', var_start_time;												     
--		raise notice 'var_end_time: %', var_end_time;												     
--		raise notice 'shift_name: %', shift_name;												     
--		raise notice 'var_efficiency_return: %', var_efficiency_return;												     
--		raise notice 'var_availability_return: %', var_availability_return;
--		raise notice 'var_capacity_potential_return: %', var_capacity_potential_return;												     
--		raise notice 'var_throughput_return: %', var_throughput_return;												     
--		raise notice 'var_deviation_return: %', var_deviation_return;												     
--		raise notice 'var_throughputcycles_return: %', var_throughputcycles_return;												     
--		raise notice 'var_vacreached_return: %', var_vacreached_return;												     
--		raise notice 'var_cyclesperminute_return: %', var_cyclesperminute_return;			
--     	raise notice 'var_sqlquery: %', var_sqlquery;
		perform dblink_exec('ExternalConnection', var_sqlquery);
		
		TOTALCOUNT := var_count_return;
		REJECTCOUNT := 0;
		
	end if;

	return next;
end;

$function$
