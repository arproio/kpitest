CREATE OR REPLACE FUNCTION public.sp_cognipro_line(par_lineid character varying, par_linename character varying, par_customername character varying, par_deleteflag numeric)
 RETURNS void
 LANGUAGE plpgsql
AS $function$

DECLARE
    var_ClientId VARCHAR(100);
    var_CountLine NUMERIC(10, 0);
    var_ClientAssetId NUMERIC(10, 0);
    var_ShiftId NUMERIC(10, 0);
    var_ShiftCounter NUMERIC(10, 0) DEFAULT 1;
    var_WeekdayCounter NUMERIC(10, 0) DEFAULT 1;
BEGIN
    /*
    [7810 - Severity CRITICAL - PostgreSQL doesn't support the SET NOCOUNT. If need try another way to send message back to the client application.]
    SET NOCOUNT ON;
    */
    SELECT
        id
        INTO var_ClientId
        FROM public.see_clientmaster
        WHERE LOWER(name) = LOWER(par_CustomerName);

    IF var_ClientId IS NULL THEN
        INSERT INTO public.see_clientmaster (name)
        VALUES (par_CustomerName);
        SELECT
            id
            INTO var_ClientId
            FROM public.see_clientmaster
            WHERE LOWER(name) = LOWER(par_CustomerName);
    END IF;
    SELECT
        COUNT(linename)
        INTO var_CountLine
        FROM public.see_clientassetmaster
        WHERE clientid = var_ClientId::NUMERIC AND LOWER(lineid) = LOWER(par_LineID);

    IF par_DeleteFlag = 1 then
    		delete from public.see_shiftsettings
    		where lineid = par_LineID;
    		
    		delete from public.see_shiftmaster
    		where lineid = par_LineID;
    		
    		
        DELETE FROM public.see_clientassetmaster
            WHERE clientid = var_ClientId::NUMERIC AND LOWER(lineid) = LOWER(par_LineID)
        /* Delete from SEE_CogniPro_VPP_IRRConfig where LineID=@LineID */;
    ELSE
        IF var_CountLine > 0 THEN
            UPDATE public.see_clientassetmaster
            SET linename = par_LineName
                WHERE clientid = var_ClientId::NUMERIC AND LOWER(lineid) = LOWER(par_LineID);
        ELSE
            /*
            [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management in functions. Perform a manual conversion.]
            BEGIN TRANSACTION
            */
            INSERT INTO public.see_clientassetmaster (clientid, lineid, linename, asset_id, machinetype)
            VALUES (var_ClientId::NUMERIC, par_LineID, par_LineName, '--', '--') RETURNING id INTO var_ClientAssetId;
            raise notice 'inserted into see_clientassetmaster %', var_ClientAssetId;
            /*SELECT
                scope_identity()
                INTO var_ClientAssetId*/
            /*
            [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management in functions. Perform a manual conversion.]
            COMMIT TRANSACTION
            */
            /* ****** */
            /* select @ClientAssetId = Id from SEE_ClientAssetMaster where Asset_ID=@AssetID and LineID=@LineID */
            var_ShiftCounter := 1;

            WHILE var_ShiftCounter < 10 LOOP
                /*
                [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management in functions. Perform a manual conversion.]
                BEGIN TRANSACTION
                */
                INSERT INTO public.see_shiftmaster (lineid, clientassetid, shiftname, created_date, created_by)
                VALUES (par_LineID, var_ClientAssetId, 'Shift ' || CAST (var_ShiftCounter AS VARCHAR(1)), CLOCK_TIMESTAMP(), 'TW_SP') RETURNING id INTO var_ShiftId;
                /*SELECT
                    scope_identity()
                    INTO var_ShiftId*/
                /*
                [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management in functions. Perform a manual conversion.]
                COMMIT TRANSACTION
                */

                WHILE var_WeekdayCounter <= 7 LOOP
                    INSERT INTO public.see_shiftsettings (lineid, shiftid, weekday, lastmodifiedby, is1dayactive)
                    VALUES (par_LineID, var_ShiftId, var_WeekdayCounter, 'TW_SP', 0);
                    var_WeekdayCounter := (var_WeekdayCounter + 1)::INT;
                END LOOP;
                var_ShiftCounter := (var_ShiftCounter + 1)::INT;
                var_WeekdayCounter := 1;
            END LOOP
            /* ****** */;
        END IF;
    END IF;
END;

$function$
