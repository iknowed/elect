
create table ele ( 
	eleid int primary key default nextval('elect_ele_seq') , 
	edate date unique
);
