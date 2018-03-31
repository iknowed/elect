
drop index mvf_birth_date_ix ;
drop index mvf_party_ix ;
drop index mvf_fname_ix ;
drop index mvf_lname_ix ;
drop index mvf_street_ix ;
drop index mvf_hnum_ix ;
drop index mvf_supv_ix ;
drop index mvf_pct_ix ;
drop index mvf_aptnum_ix ;
drop index mvf_voter_id_ix ;

create index mvf_birth_date_ix on mvf(birth_date);
create index mvf_party_ix on mvf(party);
create index mvf_fname_ix on mvf(name_first);
create index mvf_lname_ix on mvf(name_last);
create index mvf_street_ix on mvf(street);
create index mvf_hnum_ix on mvf(house_number);
create index mvf_supv_ix on mvf(supv);
create index mvf_pct_ix on mvf(precinct);
create index mvf_aptnum_ix on mvf(apartment_number);
create index mvf_voter_id_ix on mvf(voter_id);
