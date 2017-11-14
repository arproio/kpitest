CREATE TABLE cognipro.shift_kpiresults (
	dailyshift_id varchar NOT NULL,
	shiftname varchar NULL,
	machine_id varchar NOT NULL,
	starttime timestamptz NULL,
	endtime timestamptz NULL,
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
	kpi_vacuumdeviation float4 NULL,
	kpi_throughputcycles float4 NULL,
	param_vacreached float4 NULL,
	param_machinespeed float4 NULL,
	param_centersealtemppv float4 NULL,
	param_endremtemppv float4 NULL,
	param_endsealtemppv float4 NULL,
	param_pumpinvspeed float4 NULL,
	param_totalpackcount float4 NULL,
	recipe_centersealtime float4 NULL,
	recipe_endsealtime float4 NULL,
	recipe_filmfeedlength float4 NULL,
	param_speedcpm float4 NULL,
	param_lifetimecycles float4 NULL,
	param_lifetimecycle float4 NULL,
	param_productcount float4 NULL,
	CONSTRAINT shift_kpiresults_pk PRIMARY KEY (dailyshift_id,machine_id)
)
WITH (
	OIDS=FALSE
) ;
