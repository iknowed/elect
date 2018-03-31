create table bplaces ( 
	bplace varchar(32),
	code	char(3),
	foreign key(lid) references langs(lid)
);
