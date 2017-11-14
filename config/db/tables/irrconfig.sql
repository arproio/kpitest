CREATE TABLE public.irrconfig (
	asset_id varchar(100) NOT NULL,
	channelnumber numeric(10) NOT NULL,
	idealrunrate float4 NOT NULL
)
WITH (
	OIDS=FALSE
) ;
