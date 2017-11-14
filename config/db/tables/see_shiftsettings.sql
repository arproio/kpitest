CREATE TABLE public.see_shiftsettings (
	id numeric NOT NULL DEFAULT nextval('see_vrshiftsettings_seq'::regclass),
	shiftid numeric NOT NULL,
	shiftstarttime varchar(50) NULL,
	shiftendtime varchar(50) NULL,
	weekday numeric NULL,
	isactive varchar(50) NULL,
	shiftbreaktime numeric(10) NULL,
	lastmodifiedby varchar(50) NULL,
	update_date timestamp NULL,
	is1dayactive numeric(1) NULL,
	lineid varchar NOT NULL,
	CONSTRAINT see_vrshiftsettings_pkey PRIMARY KEY (id),
	CONSTRAINT see_vrshiftsettings_shiftid_fkey FOREIGN KEY (shiftid) REFERENCES public.see_shiftmaster(id)
)
WITH (
	OIDS=FALSE
) ;
