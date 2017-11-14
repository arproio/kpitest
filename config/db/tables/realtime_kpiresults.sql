CREATE TABLE cognipro.realtime_kpiresults (
	machine_id varchar NOT NULL,
	dailyshift_id varchar NOT NULL,
	shiftname varchar NOT NULL,
	update_date timestamptz NOT NULL,
	kpi_efficiency float4 NULL,
	kpi_availability float4 NULL,
	kpi_giveaway float4 NULL,
	kpi_reject float4 NULL,
	kpi_goodproduct float4 NULL,
	kpi_sdi float4 NULL,
	kpi_productaverage float4 NULL,
	kpi_faultrate float4 NULL,
	kpi_performance float4 NULL,
	kpi_planprodtime float4 NULL,
	kpi_capacitypotential float4 NULL,
	kpi_throughput float4 NULL,
	kpi_throughputcycles float4 NULL
)
WITH (
	OIDS=FALSE
) ;
create
    index realtime_kpiresults_update_date_idx on
    cognipro.realtime_kpiresults
        using btree(update_date) ;
create
    index realtime_linekpiresults_update_date_idx on
    cognipro.realtime_kpiresults
        using btree(update_date) ;
create
    index shift_linekpiresults_update_date_idx on
    cognipro.realtime_kpiresults
        using btree(update_date) ;
