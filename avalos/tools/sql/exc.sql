
create table exc ( 
	voter_id int unique not null, foreign key(voter_id) references vid(voter_id),
	e boolean default 't'
);

