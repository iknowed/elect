drop table ext;
create table ext ( 
	voter_id int not null, foreign key(voter_id) references mvf(voter_id),
	bad			int,
	dnc			int,
	ded			int,
	lid			int,	
	mad			int,	
	mov			int,	
	foreign key(lid) references langs(lid),
	usr	varchar(32),
	ip		char(15),
	stamp	timestamp,
	notes	varchar(128)
);

