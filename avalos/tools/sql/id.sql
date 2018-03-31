
create table idtypes ( 
	idtid int primary key default nextval('idtypes_idtid_seq') , 
	type varchar(5) unique
);

create table ids ( 
	voter_id int unique not null, foreign key(voter_id) references vid(voter_id),
	tstamp timestamp, 
	affidavit char(13), 
	idtid int, 
	foreign key(idtid) references idtypes(idtid),
	cmpid int,	
	foreign key(cmpid) references cmp(cmpid)
);

insert into idtypes (type) values ('SUP');
insert into idtypes (type) values ('AGN');
insert into idtypes (type) values ('UND');
insert into idtypes (type) values ('DNC');
insert into idtypes (type) values ('BAD');

