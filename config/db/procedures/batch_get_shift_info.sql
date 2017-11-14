CREATE OR REPLACE FUNCTION public.batch_get_shift_info(line_names character varying[], par_timestamp character varying)
 RETURNS TABLE(shiftinstanceid integer, shiftid integer, linename character varying, shiftname character varying, starttime character varying, endtime character varying, weekday character varying)
 LANGUAGE plpgsql
 STABLE
AS $function$
declare
	myindex integer;
	line_name character varying;
	oneline RECORD;
	
	mySHIFTINSTANCEID integer;
	mySHIFTID integer;
	myLINENAME character varying;
	mySHIFTNAME character varying;
	mySTARTTIME character varying;
	myENDTIME character varying;
	myWEEKDAY character varying;
	
BEGIN
	--RAISE NOTICE 'INPUT ARRAY IS:%', machine_ids;
	myindex := 0;
	foreach line_name in 
		array line_names 
	LOOP
		for mySHIFTINSTANCEID, mySHIFTID, myLINENAME, mySHIFTNAME, mySTARTTIME, myENDTIME, myWEEKDAY in
			select *
			from get_shift_info(line_name, par_timestamp)
		LOOP
			

			SHIFTINSTANCEID := mySHIFTINSTANCEID;
			SHIFTID := mySHIFTID;
			LINENAME := myLINENAME;
			SHIFTNAME := mySHIFTNAME;
			STARTTIME := mySTARTTIME;
			ENDTIME := myENDTIME;
			WEEKDAY := myWEEKDAY;
			
			RETURN NEXT;
		END LOOP;
	END LOOP;

	RETURN;

END;
$function$
