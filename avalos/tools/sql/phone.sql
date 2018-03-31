drop sequence phoneseq_phid_seq;
drop sequence pstat_type_seq;
create sequence phoneseq_phid_seq;
create sequence pstat_type_seq;

drop table phone cascade;
create table phone ( 
	phid int primary key default nextval('phoneseq_phid_seq') , 
	phonelist varchar(16) not null,  
	title varchar (80) not null,
	cmpid int not null,
	generated int,
	tbl varchar(32),
	unique(phonelist,title,cmpid),
	foreign key(cmpid) references cmp(cmpid), 
	query varchar(4096)
);


drop table pstat cascade;
create table pstat ( 
	pstatid int primary key default nextval('pstat_type_seq') , 
	type varchar(5) unique
);
insert into pstat(type) values ('LOK');
insert into pstat(type) values ('UNL');
insert into pstat(type) values ('FIN');
