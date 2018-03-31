create function islatino(mvf) returns integer as '
DECLARE
	data_r	RECORD;
	lname	varchar;
	bplace	varchar;
	pct	integer;
	eth_r	RECORD;
	eth	varchar;
	lang_r	RECORD;
	lang_t	varchar;
	lang	varchar
	avg_r	RECORD;
	a_hisp	real;
	pct_r	RECORD;
	p_hisp	real;
	hisp_c	real;
	n_lang	integer;
	b_state	integer;
	spanish integer;

	b_state = 0;
	n_lang  = 0;
	spanish = 0;
	select into data_r name_last,birth_place,precinct from mvf where voter_id=mvf.f61;
	lname	:=data_r.name_last;
	bplace	:=data_r.birth_place;
	pct	:=data_r.precinct;

	if bplace = ''CA'' or bplace = ''AZ'' or bplace = ''NM'' or bplace = ''TX'' then
		b_state := 1;
	end if

	select into eth_r ethnicity from ethnicities,snames where (surname=lname and snames.eid=ethnicities.eid);

	eth 	:= ethr.ethnicity;

	for lang_r in select language from bplaces,langs where bplace=bplace and (bplaces.lid=langs.lid) loop;

		lang_t	:= lang_r.language;
		if lang_t = ''Spanish'' then
			n_lang := n_lang + 1;
			spanish := 1;			
		end if
	end loop

	select into avg_r avg(p_hisp) from pct;

	a_hisp	:= avg_r.f1;

	select into pct_r p_hisp from pct where pct=$precinct

	p_hisp	:= pct_r.f1;

' language plpgsql;
