CREATE OR REPLACE FUNCTION public.sp_cognipro_asset_channel_irr(par_assetid character varying, par_channelnumber numeric, par_idealrunrate numeric)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    var_RecordExists NUMERIC(10, 0);
BEGIN
    /*
    [7810 - Severity CRITICAL - PostgreSQL doesn't support the SET NOCOUNT. If need try another way to send message back to the client application.]
    SET NOCOUNT ON;
    */
    SELECT
        COUNT(*)
        INTO var_RecordExists
        FROM public.irrconfig
        WHERE LOWER(asset_id) = LOWER(par_AssetID) AND channelnumber = par_ChannelNumber;

    IF var_RecordExists = 0 THEN
        INSERT INTO public.irrconfig (asset_id, channelnumber, idealrunrate)
        VALUES (par_AssetID, par_ChannelNumber, par_IdealRunRate);
    ELSE
        UPDATE public.irrconfig
        SET idealrunrate = par_IdealRunRate
            WHERE LOWER(asset_id) = LOWER(par_AssetID) AND channelnumber = par_ChannelNumber;
    END IF;
END;
$function$
