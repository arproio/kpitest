CREATE TABLE public.see_clientassetmaster (
	id numeric(10) NOT NULL DEFAULT nextval('see_clientassetmaster_seq'::regclass),
	clientid numeric(10) NOT NULL,
	asset_id varchar(100) NOT NULL,
	lineid varchar(100) NOT NULL,
	linename varchar(100) NOT NULL,
	clientunits varchar(20) NULL,
	machinetype varchar(50) NULL,
	timezone varchar(50) NULL,
	CONSTRAINT see_clientassetmaster_pkey PRIMARY KEY (id),
	CONSTRAINT see_clientassetmaster_un UNIQUE (asset_id,lineid)
)
WITH (
	OIDS=FALSE
) ;
