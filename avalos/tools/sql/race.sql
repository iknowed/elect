create table race ( 
	rid int primary key default nextval('race_rid_seq') , 
	eleid int, 
	foreign key(eleid) references ele(eleid), 
	edate date, 
	ofcid int, 
	foreign key(ofcid) references ofc(ofcid),
	dist int
);
