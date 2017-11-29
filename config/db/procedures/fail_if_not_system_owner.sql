CREATE OR REPLACE FUNCTION public.fail_if_not_system_owner(system_ownership_id integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (
            SELECT id 
            FROM system_ownership 
            WHERE id IN (SELECT id FROM system_ownership ORDER BY took_ownership DESC LIMIT 1)
            AND id = system_ownership_id )
    THEN
        -- '28SOA' is a combination of the '28000' error code mask (i.e. 
        -- 'invalid_authorization_specification'), plus 'SOA' for (S)ystem 
        -- (O)wnership (A)uthorization.
        RAISE EXCEPTION SQLSTATE '28SOA' USING MESSAGE = 'Database access prohibited because System Ownership has been lost.';
    END IF;    
END;
$function$
