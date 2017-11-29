CREATE OR REPLACE FUNCTION public.sp_cognipro_asset(par_lineid character varying, par_assetid character varying, par_deleteflag numeric)
 RETURNS void
 LANGUAGE plpgsql
AS $function$

DECLARE
    var_CountAsset NUMERIC(10, 0);
    var_CountNewLines NUMERIC(10, 0);
    var_ClientAssetId NUMERIC(10, 0);
    var_ShiftId NUMERIC(10, 0);
    var_ShiftCounter NUMERIC(10, 0) DEFAULT 1;
    var_WeekdayCounter NUMERIC(10, 0) DEFAULT 1;
    var_return_id NUMERIC(10, 0) DEFAULT 0;
BEGIN
    /*
    [7810 - Severity CRITICAL - PostgreSQL doesn't support the SET NOCOUNT. If need try another way to send message back to the client application.]
    SET NOCOUNT ON;
    */
    SELECT
        COUNT(asset_id)
        INTO var_CountAsset
        FROM public.see_clientassetmaster
        WHERE LOWER(lineid) = LOWER(par_LineID);
	raise notice 'var_CountAsset: %',var_CountAsset;
	raise notice 'par_LineID: %', par_LineID;
	raise notice 'par_AssetID: %', par_AssetID;
    IF par_DeleteFlag = 1 THEN
        IF var_CountAsset > 1 then
        		raise notice 'DELETE > 1';
            DELETE FROM public.see_clientassetmaster
                WHERE LOWER(lineid) = LOWER(par_LineID) AND LOWER(asset_id) = LOWER(par_AssetID);
        end if;

        IF var_CountAsset = 1 then
        		raise notice 'DELETE = 1';
            UPDATE public.see_clientassetmaster
            SET asset_id = '--', machinetype = '--'
                WHERE LOWER(lineid) = LOWER(par_LineID);
        END IF;
    ELSE
        SELECT
            COUNT(asset_id)
            INTO var_CountNewLines
            FROM public.see_clientassetmaster
            WHERE LOWER(asset_id) = LOWER('--') AND LOWER(lineid) = LOWER(par_LineID);

        IF var_CountNewLines > 0 THEN
            UPDATE public.see_clientassetmaster
            SET asset_id = par_AssetID
                WHERE LOWER(lineid) = LOWER(par_LineID) AND LOWER(asset_id) = LOWER('--');
        ELSE
            /*
            [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management in functions. Perform a manual conversion.]
            BEGIN TRANSACTION
            */
            INSERT INTO public.see_clientassetmaster (clientid, lineid, linename, asset_id, machinetype)
            SELECT
                clientid, lineid, linename, par_AssetID, machinetype
                FROM public.see_clientassetmaster
                WHERE LOWER(lineid) = LOWER(par_LineID)
                LIMIT 1
            RETURNING ID INTO var_return_id;
                    
            /*
            SELECT
                scope_identity()
                INTO var_ClientAssetId
            */    
            /*
            [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management in functions. Perform a manual conversion.]
            COMMIT TRANSACTION
            */
        END IF;
        raise notice '%', var_return_id;
    END IF;
END;

$function$
