
drop table canv;
create table canv ( 
	voter_id int not null, foreign key(voter_id) references mvf(voter_id),
	sup	int,
	sgn	int,
	vol	int,
	msg	int,
	na		int,
	bak	int,
	bldg	int,
	hpty	int,
	cmpid	int,
	foreign key(cmpid) references cmp(cmpid),
	usr	varchar(32),
	ip		char(15),
	stamp	timestamp,
	notes	varchar(128)
);

