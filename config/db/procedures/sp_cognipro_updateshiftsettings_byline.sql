CREATE OR REPLACE FUNCTION public.sp_cognipro_updateshiftsettings_byline(par_shiftid character varying, par_shiftstarttime character varying, par_shiftendtime character varying, par_lineid character varying, par_weekday numeric)
 RETURNS void
 LANGUAGE plpgsql
AS $function$

declare
    /*var_shiftexists numeric(10, 0) default 0;
*/
begin
    /* set nocount on added to prevent extra result sets from cognipro.*/
    /* interfering with select statements. */
    /*
    [7810 - severity critical - postgresql doesn't support the set nocount. if need try another way to send message back to the client application.]
    set nocount on;
    */
    /*
    [*7811 - severity critical - postgresql doesn't support the convert function. create a user-defined function., 7811 - severity critical - postgresql doesn't support the convert function. create a user-defined function.]
    update see_vrshiftsettings
    	set shiftstarttime = convert(varchar,par_shiftstarttime,108),
    	shiftendtime = convert(varchar,par_shiftendtime,108)
    	where
    	weekday=par_weekday and
    	shiftid in
    	(select  shiftid from cognipro.cognipro.see_vrshiftmaster a,cognipro.see_vrshiftsettings b
    				where a.id = b.shiftid
    				and b.weekday=par_weekday
    				and a.clientassetid
    				in (select id from cognipro.see_clientassetmaster where
    				asset_id in (select asset_id from cognipro.see_clientassetmaster where lineid = par_lineid))
    				and shiftname='shift '+convert(varchar,par_shiftid))
    */
	update public.see_shiftsettings
    	set shiftstarttime = par_shiftstarttime::varchar(255),
    	shiftendtime = par_shiftendtime::varchar(255)
    	where
    	weekday=par_weekday and
    	shiftid = 
    		(select b.shiftid 
    		from public.see_shiftmaster as a, public.see_shiftsettings as b
    		where a.id = b.shiftid
    		and b.weekday = par_weekday
    		and a.lineid = par_lineid
    		and a.shiftname='Shift '::varchar(50)||par_shiftid);
    	
    	
    	
    	
    	
--    	
--    	(select b.shiftid from cognipro.see_vrshiftmaster a,cognipro.see_vrshiftsettings b
--    				where a.id = b.shiftid
--    				and b.weekday=par_weekday
--    				and a.lineid = par_lineid 
--    				and a.shiftname='Shift '::varchar(50)||par_shiftid);	
	
    				
    				
    				
	
--    update cognipro.see_vrshiftsettings
--	set 
--		shiftstarttime = par_shiftstarttime::varchar(255),
--    	shiftendtime = par_shiftendtime::varchar(255)
--	where
--    	weekday = par_weekday::varchar(50) and
--    	shiftid = par_shiftid;
    	
    
    	
    	
    	
    	
    	
    	
    	
    	
--    	in
--    	(select  shiftid from cognipro.see_vrshiftmaster a,cognipro.see_vrshiftsettings b
--    				where a.id::varchar = b.shiftid
--    				and b.weekday=par_weekday::varchar(50)
--    				and a.clientassetid
--    				in (select id from cognipro.see_clientassetmaster where
--    				asset_id in (select asset_id from cognipro.see_clientassetmaster where lineid = par_lineid))
--    				and shiftname='Shift '::varchar(50) || par_shiftid );

    /*
    update see_vrshiftsettings
    set shiftstarttime = convert(varchar,par_shiftstarttime,108),
    shiftendtime = convert(varchar,par_shiftendtime,108)
    where
    weekday=par_weekday and
    shiftid in
    (select  shiftid from cognipro.see_vrshiftmaster a,cognipro.see_vrshiftsettings b
    			where a.id = b.shiftid
    			and b.weekday=par_weekday
    			and a.clientassetid
    			in (select id from cognipro.see_clientassetmaster where
    			asset_id in (select asset_id from cognipro.see_clientassetmaster where lineid = par_lineid))
    			and shiftname='shift '+convert(varchar,par_shiftid))

    begin
    end;
    */
end;
/* ============================================= */
/* author:		<satish> */
/* create date: <march 30 2017> */
/* description:	<cognipro> */
/* ============================================= */

$function$
