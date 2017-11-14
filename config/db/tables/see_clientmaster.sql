CREATE TABLE public.see_clientmaster (
	id numeric(10) NOT NULL DEFAULT nextval('see_clientmaster_seq'::regclass),
	"name" varchar(100) NOT NULL
)
WITH (
	OIDS=FALSE
) ;
