CREATE OR REPLACE FUNCTION public.asset_kpi_bytime_batch_vs(value_stream_name character varying, machine_ids character varying[], start_time_string character varying, end_time_string character varying, shift_start_time character varying, ideal_run_rate integer, capacity_potential_window real, throughput_window real, efficiency_window real, availability_window real)
 RETURNS TABLE(availability real, throughputcycles real, throughput real, cyclesperminute real, vacreached real, efficiency real, deviation real, capacitypotential real, starttime character varying, endtime character varying, machineid character varying)
 LANGUAGE plpgsql
 STABLE
AS $function$
declare
	myindex integer;
	machine_id character varying;
	one_machine RECORD;
	myAVAILABILITY real;
	myTHROUGHPUTCYCLES real;
	myTHROUGHPUT real;
	myCYCLESPERMINUTE real;
	myVACREACHED real;
	myEFFICIENCY real;
	myDEVIATION real;
	myCAPACITYPOTENTIAL real;
	mySTARTTIME  character varying;
	myENDTIME  character varying;
	myMACHINEID  character varying;
BEGIN
	--RAISE NOTICE 'INPUT ARRAY IS:%', machine_ids;
	
	myindex := 0;
	foreach machine_id in 
		array machine_ids 
	LOOP
		--RAISE NOTICE 'CURRENT MACHINE IS:%', machine_id;

	for myAVAILABILITY, myTHROUGHPUTCYCLES, myTHROUGHPUT, myCYCLESPERMINUTE, myVACREACHED, myEFFICIENCY, myDEVIATION, myCAPACITYPOTENTIAL, mySTARTTIME, myENDTIME, myMACHINEID in
			select onemachine.AVAILABILITY, onemachine.THROUGHPUTCYCLES, onemachine.THROUGHPUT, onemachine.CYCLESPERMINUTE, onemachine.VACREACHED, onemachine.EFFICIENCY, 
			onemachine.DEVIATION, onemachine.CAPACITYPOTENTIAL, onemachine.STARTTIME,onemachine.ENDTIME, onemachine.MACHINEID
			from asset_kpi_bytime_vs(value_stream_name,machine_id,start_time_string,end_time_string, shift_start_time, ideal_run_rate, capacity_potential_window, throughput_window, efficiency_window, availability_window) onemachine
		LOOP

			AVAILABILITY := myAVAILABILITY;
			THROUGHPUTCYCLES := myTHROUGHPUTCYCLES;
			THROUGHPUT := myTHROUGHPUT;
			CYCLESPERMINUTE := myCYCLESPERMINUTE;
			VACREACHED := myVACREACHED;
			EFFICIENCY := myEFFICIENCY;
			DEVIATION := myDEVIATION;
			CAPACITYPOTENTIAL := myCAPACITYPOTENTIAL;
			STARTTIME := mySTARTTIME;
			ENDTIME := myENDTIME;
			MACHINEID := myMACHINEID;
			
			RETURN NEXT;
		END LOOP;
	END LOOP;

	RETURN;

END;
    $function$
