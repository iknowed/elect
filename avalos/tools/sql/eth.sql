create table	ethnicities (
 eid        integer unique not null default nextval('ethnicities_eid_seq'),
 ethnicity  varchar(20)  
);

create table	eth (
 voter_id   integer,
 affidavit  char(13),
 eid        integer,
 FOREIGN KEY (eid) REFERENCES ethnicities(eid)
);


insert into ethnicities (ethnicity) values ('Filipino');
insert into ethnicities (ethnicity) values ('Chinese');
insert into ethnicities (ethnicity) values ('Russian');
insert into ethnicities (ethnicity) values ('Samoan');
insert into ethnicities (ethnicity) values ('Iranian');
insert into ethnicities (ethnicity) values ('Arab');
insert into ethnicities (ethnicity) values ('Korean');
insert into ethnicities (ethnicity) values ('Vietnamese');
insert into ethnicities (ethnicity) values ('Jewish');
insert into ethnicities (ethnicity) values ('Hispanic');
insert into ethnicities (ethnicity) values ('Japanese');

