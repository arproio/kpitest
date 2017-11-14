CREATE OR REPLACE FUNCTION public.asset_kpi_bytime_batch_vpp(value_stream_name character varying, machine_ids character varying[], start_time_string character varying, end_time_string character varying, shift_start_time character varying, ideal_run_rate integer, capacity_potential_window real, availability_window real)
 RETURNS TABLE(availability real, efficiency real, capacitypotential real, giveaway real, rejects real, goodproduct real, sdi real, productaverage real, faultrate real, performance real, plannedproductiontime real, machinespeed real, pumpspeed real, totalpackcount real, filmfeedlength real, centersealtime real, endsealtime real, centersealtemp real, endsealtemp real, endremainingtemp real, starttime character varying, endtime character varying, machineid character varying)
 LANGUAGE plpgsql
 STABLE
AS $function$
declare
	myindex integer;
	machine_id character varying;
	one_machine RECORD;
	myAVAILABILITY real;
	myEFFICIENCY real;
	myCAPACITYPOTENTIAL real;
	myGIVEAWAY real;
	myREJECTS real;
	myGOODPRODUCT real;
	mySDI real;
	myPRODUCTAVERAGE real;
	myFAULTRATE real;
	myPERFORMANCE real;
	myPLANNEDPRODUCTIONTIME real;
	myMACHINESPEED real;
	myPUMPSPEED real;
	myTOTALPACKCOUNT real;
	myFILMFEEDLENGTH real;
	myCENTERSEALTIME real;
	myENDSEALTIME real;
	myCENTERSEALTEMP real;
	myENDSEALTEMP real;
	myENDREMAININGTEMP real;
	mySTARTTIME character varying;
	myENDTIME character varying;
	myMACHINEID character varying;
BEGIN
	--RAISE NOTICE 'INPUT ARRAY IS:%', machine_ids;
	
	myindex := 0;
	foreach machine_id in 
		array machine_ids 
	LOOP
		--RAISE NOTICE 'CURRENT MACHINE IS:%', machine_id;

for 
	myAVAILABILITY, myEFFICIENCY, myCAPACITYPOTENTIAL, myGIVEAWAY, myREJECTS, myGOODPRODUCT, mySDI, 
	myPRODUCTAVERAGE, myFAULTRATE, myPERFORMANCE, myPLANNEDPRODUCTIONTIME, myMACHINESPEED, myPUMPSPEED, 
	myTOTALPACKCOUNT, myFILMFEEDLENGTH, myCENTERSEALTIME, myENDSEALTIME, myCENTERSEALTEMP, 
	myENDSEALTEMP, myENDREMAININGTEMP, mySTARTTIME, myENDTIME, myMACHINEID in
		select 
			onemachine.AVAILABILITY, onemachine.EFFICIENCY, onemachine.CAPACITYPOTENTIAL, onemachine.GIVEAWAY, onemachine.REJECTS, onemachine.GOODPRODUCT, onemachine.SDI, 
			onemachine.PRODUCTAVERAGE, onemachine.FAULTRATE, onemachine.PERFORMANCE, onemachine.PLANNEDPRODUCTIONTIME, onemachine.MACHINESPEED, onemachine.PUMPSPEED, 
			onemachine.TOTALPACKCOUNT, onemachine.FILMFEEDLENGTH, onemachine.CENTERSEALTIME, onemachine.ENDSEALTIME, onemachine.CENTERSEALTEMP, onemachine.ENDSEALTEMP, 
			onemachine.ENDREMAININGTEMP, onemachine.STARTTIME,onemachine.ENDTIME, onemachine.MACHINEID
		from asset_kpi_bytime_vpp(value_stream_name,machine_id,start_time_string,end_time_string, shift_start_time, ideal_run_rate, capacity_potential_window, availability_window) onemachine
		LOOP

			AVAILABILITY := myAVAILABILITY; 
			EFFICIENCY := myEFFICIENCY;
			CAPACITYPOTENTIAL := myCAPACITYPOTENTIAL; 
			GIVEAWAY := myGIVEAWAY;
			REJECTS := myREJECTS;
			GOODPRODUCT := myGOODPRODUCT;
			SDI := mySDI;
			PRODUCTAVERAGE := myPRODUCTAVERAGE;
			FAULTRATE := myFAULTRATE;
			PERFORMANCE := myPERFORMANCE;
			PLANNEDPRODUCTIONTIME := myPLANNEDPRODUCTIONTIME;
			MACHINESPEED := myMACHINESPEED;
			PUMPSPEED := myPUMPSPEED;
			TOTALPACKCOUNT := myTOTALPACKCOUNT;
			FILMFEEDLENGTH := myFILMFEEDLENGTH; 
			CENTERSEALTIME := myCENTERSEALTIME;
			ENDSEALTIME := myENDSEALTIME;
			CENTERSEALTEMP := myCENTERSEALTEMP;
			ENDSEALTEMP := myENDSEALTEMP;
			ENDREMAININGTEMP := myENDREMAININGTEMP;
			STARTTIME := mySTARTTIME;
			ENDTIME := myENDTIME;
			MACHINEID := myMACHINEID;
			
			RETURN NEXT;
		END LOOP;
	END LOOP;

	RETURN;

END;
    $function$
