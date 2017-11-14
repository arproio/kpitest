CREATE TABLE cognipro.channel_kpiresults (
	dailyshift_id varchar NOT NULL,
	shiftname varchar NULL,
	machine_id varchar NOT NULL,
	starttime timestamptz NULL,
	endtime timestamptz NULL,
	kpi_giveaway float4 NULL,
	kpi_reject float4 NULL,
	kpi_goodproduct float4 NULL,
	kpi_sdi float4 NULL,
	kpi_productaverage float4 NULL,
	kpi_performance float4 NULL
)
WITH (
	OIDS=FALSE
) ;
