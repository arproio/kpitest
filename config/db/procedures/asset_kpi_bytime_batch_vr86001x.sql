CREATE OR REPLACE FUNCTION public.asset_kpi_bytime_batch_vr86001x(value_stream_name character varying, machine_ids character varying[], start_time_string character varying, end_time_string character varying, shift_start_time character varying, ideal_run_rate integer, capacity_potential_window real, throughput_window real, efficiency_window real, availability_window real)
 RETURNS TABLE(average real, cyclecount integer, productcount integer, throughput real, availability real, capacitypotential real, efficiency real, starttime character varying, endtime character varying, machineid character varying)
 LANGUAGE plpgsql
 STABLE
AS $function$
declare
	myindex integer;
	machine_id character varying;
	one_machine RECORD;
	myAVERAGE real;
	myCYCLECOUNT integer;
	myPRODUCTCOUNT integer;
	myTHROUGHPUT  real;
	myAVAILABILITY  real;
	myCAPACITYPOTENTIAL  real;
	myEFFICIENCY  real;
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

		for myAVERAGE,myCYCLECOUNT,myPRODUCTCOUNT,myTHROUGHPUT,myAVAILABILITY,myCAPACITYPOTENTIAL,myEFFICIENCY,mySTARTTIME,myENDTIME,myMACHINEID in
			select onemachine.AVERAGE, onemachine.CYCLECOUNT, onemachine.PRODUCTCOUNT,onemachine.THROUGHPUT,onemachine.AVAILABILITY, 
			onemachine.CAPACITYPOTENTIAL,onemachine.EFFICIENCY, onemachine.STARTTIME,onemachine.ENDTIME, onemachine.MACHINEID
			from asset_kpi_bytime_vr86001x(value_stream_name,machine_id,start_time_string,end_time_string, shift_start_time, ideal_run_rate, capacity_potential_window, throughput_window, efficiency_window, availability_window) onemachine
		LOOP

			AVERAGE := myAVERAGE;
			CYCLECOUNT := myCYCLECOUNT;
			PRODUCTCOUNT := myPRODUCTCOUNT;
			THROUGHPUT := myTHROUGHPUT;
			AVAILABILITY := myAVAILABILITY;
			CAPACITYPOTENTIAL := myCAPACITYPOTENTIAL;
			EFFICIENCY := myEFFICIENCY;
			STARTTIME := mySTARTTIME;
			ENDTIME := myENDTIME;
			MACHINEID := myMACHINEID;
			
			RETURN NEXT;
		END LOOP;
	END LOOP;

	RETURN;

END;
$function$
