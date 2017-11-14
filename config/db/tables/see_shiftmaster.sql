CREATE TABLE public.see_shiftmaster (
	id numeric(10) NOT NULL DEFAULT nextval('see_vrshiftmaster_seq'::regclass),
	clientassetid numeric(10) NOT NULL,
	shiftname varchar(100) NOT NULL,
	created_date timestamp NOT NULL,
	created_by varchar(100) NULL,
	lineid varchar NOT NULL,
	CONSTRAINT see_vrshiftmaster_pkey PRIMARY KEY (id),
	CONSTRAINT see_vrshiftmaster_clientassetid_fkey FOREIGN KEY (clientassetid) REFERENCES public.see_clientassetmaster(id)
)
WITH (
	OIDS=FALSE
) ;
