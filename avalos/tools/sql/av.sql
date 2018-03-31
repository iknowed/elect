

create table av ( 

	voter_id int unique not null,
	affidavit char(13), 
	Name varchar(64),
	CareOf varchar(64),
	address1 varchar(64),
	address2 varchar(64),
	District int,
	Precinct int,
	PolParty char(6),
	date_issued date,
	date_returned  date,
	category varchar(10),
	source varchar(10),
	return_source varchar(10)
);
