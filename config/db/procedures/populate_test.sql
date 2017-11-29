CREATE OR REPLACE FUNCTION public.populate_test()
 RETURNS void
 LANGUAGE plpgsql
AS $function$

declare
	
	rec record;
	var_count integer;
begin
	
	for rec in 
	select id,shiftname,lineid from public.see_shiftmaster
	LOOP
		raise notice 'rec: %', rec;
		
		if rec.shiftname = 'Shift 1' then
			var_count := 1;
			while var_count < 8 loop
				insert into public.see_shiftsettings(shiftid, shiftstarttime,shiftendtime,weekday,update_date,lineid)
				values(rec.id,'00:00:00', '08:00:00',var_count,now(), rec.lineid);
				
				var_count := var_count + 1;
			end loop;
		end if;
		
		if rec.shiftname = 'Shift 2' then
			var_count := 1;
			while var_count < 8 loop
				insert into public.see_shiftsettings(shiftid, shiftstarttime,shiftendtime,weekday,update_date,lineid)
				values(rec.id,'08:00:00', '16:00:00',var_count,now(), rec.lineid);
				
				var_count := var_count + 1;
			end loop;
		end if;
		
		if rec.shiftname = 'Shift 3' then
			var_count := 1;
			while var_count < 8 loop
				insert into public.see_shiftsettings(shiftid, shiftstarttime,shiftendtime,weekday,update_date,lineid)
				values(rec.id,'16:00:00', '00:00:00',var_count,now(), rec.lineid);
				
				var_count := var_count + 1;
			end loop;
		end if;
		
	
	
	end LOOP;

end;

$function$
