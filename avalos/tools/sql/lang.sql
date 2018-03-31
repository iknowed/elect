drop table langs cascade;
drop sequence langs_lid_seq;
create sequence langs_lid_seq;

create table langs ( 
	lid int primary key default nextval('langs_lid_seq') , 
	language varchar(20)
);

drop table lang cascade;
create table lang ( 
	voter_id int unique not null,
	lid  int, 
	foreign key(lid) references langs(lid)
);
insert into langs (language) values('English');
insert into langs (language) values('Mandarin');
insert into langs (language) values('Cantonese');
insert into langs (language) values('Spanish');
insert into langs (language) values('Tagalog');
insert into langs (language) values('Russian');
insert into langs (language) values('Japanese');
insert into langs (language) values('Vietnamese');
insert into langs (language) values('Arabic');
insert into langs (language) values('Farsi');
