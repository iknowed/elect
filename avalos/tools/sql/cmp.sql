create sequence campaigns_cmpid_seq;
create table cmp ( 
	cmpid int primary key default nextval('campaigns_cmpid_seq') , 
	campaign varchar(20), 
	eleid int, 
	foreign key(eleid) references ele(eleid)
);
