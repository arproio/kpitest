CREATE OR REPLACE FUNCTION public.get_all_shifts_byline(line_name character varying)
 RETURNS TABLE(shiftinstanceid integer, shiftid integer, linename character varying, shiftname character varying, starttime character varying, endtime character varying, weekday character varying)
 LANGUAGE plpgsql
 STABLE
AS $function$


declare
	rec record;
begin

	for rec in 
    select b.shiftstarttime, b.shiftendtime, b.weekday, b.shiftid, b.id, a.shiftname
    from public.see_shiftmaster a,public.see_shiftsettings b, public.see_clientassetmaster c
    where a.id = b.shiftid 
    	and a.lineid = c.lineid
	and c.linename = line_name
	order by b.weekday, shiftname
	LOOP
		SHIFTINSTANCEID := rec.id;
		SHIFTID := rec.shiftid;
		LINENAME := line_name;
		SHIFTNAME := rec.shiftname;
		STARTTIME := rec.shiftstarttime;
		ENDTIME := rec.shiftendtime;
		WEEKDAY := rec.weekday;
		
		RETURN NEXT;
	end LOOP;
	
	return;

end;

$function$
