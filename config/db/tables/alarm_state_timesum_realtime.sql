CREATE TABLE cognipro.alarm_state_timesum_realtime (
	shiftname varchar NULL,
	machine_id varchar NOT NULL,
	starttime timestamptz NULL,
	endtime timestamptz NULL,
	update_date timestamptz NOT NULL,
	date_string varchar NULL,
	property_name varchar NOT NULL,
	property_sum float4 NULL,
	CONSTRAINT alarm_state_timesum_realtime_pk PRIMARY KEY (machine_id,update_date,property_name)
)
WITH (
	OIDS=FALSE
) ;
