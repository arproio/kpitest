CREATE TABLE cognipro.shift_linekpiresults (
	linename varchar NOT NULL,
	dailyshift_id varchar NOT NULL,
	shiftname varchar NOT NULL,
	starttime timestamptz NULL,
	endtime timestamptz NULL,
	update_date timestamptz NOT NULL,
	kpi_totalcount float4 NULL,
	kpi_rejectcount float4 NULL,
	kpi_goodcount float4 NULL,
	kpi_planprodtime float4 NULL,
	kpi_runtime float4 NULL,
	kpi_unplanneddowntime float4 NULL,
	kpi_planneddowntime float4 NULL,
	kpi_performanceoee float4 NULL,
	kpi_availabilityoee float4 NULL,
	kpi_qualityoee float4 NULL,
	kpi_oee float4 NULL
)
WITH (
	OIDS=FALSE
) ;
