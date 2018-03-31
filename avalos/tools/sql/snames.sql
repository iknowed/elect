create table snames ( 
	surname varchar(20),
	eid  int, 
	foreign key(eid) references ethnicities(eid)
);
