CREATE TABLE cognipro.alarm_state_timesum_shift (
	shiftname varchar NOT NULL,
	machine_id varchar NOT NULL,
	starttime timestamptz NULL,
	endtime timestamptz NULL,
	update_date timestamptz NULL,
	date_string varchar NOT NULL,
	property_name varchar NOT NULL,
	property_sum float4 NULL,
	CONSTRAINT alarm_state_timesum_shift_pk PRIMARY KEY (shiftname,machine_id,date_string,property_name)
)
WITH (
	OIDS=FALSE
) ;
