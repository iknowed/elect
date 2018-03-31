create table outreachtypes ( 
	ortid int primary key default nextval('outreachtypes_ortid_seq') , 
	type varchar(20), 
	feedback boolean
);

create table outreach ( 
	orid int primary key default nextval('outreach_orid_seq') , 
	outreach varchar(20), 
	ortid int, 
	foreign key(ortid) references outreachtypes(ortid), 
	cmpid int, 
	foreign key(cmpid) references cmp(cmpid)
);

create table out ( 
	voter_id int unique not null, foreign key(voter_id) references vid(voter_id)
	tstamp timestamp, 
	affidavit char(13), 
	orid int, 
	foreign key(orid) references outreach(orid)
);
