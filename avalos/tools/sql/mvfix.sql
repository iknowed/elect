
drop index mvf_party_ix;
create index mvf_party_ix on mvf(party);
drop index mvf_fname_ix;
create index mvf_fname_ix on mvf(name_first);
drop index mvf_lname_ix;
create index mvf_lname_ix on mvf(name_last);
drop index mvf_street_ix;
create index mvf_street_ix on mvf(street);
drop index mvf_hnum_ix;
create index mvf_hnum_ix on mvf(house_number);
drop index mvf_supv_ix;
create index mvf_supv_ix on mvf(supv);
drop index mvf_pct_ix;
create index mvf_pct_ix on mvf(precinct);
drop index mvf_aptnum_ix;
create index mvf_aptnum_ix on mvf(voter_id);
drop index mvf_voterid_ix;
create index mvf_voterid_ix on mvf(voter_id);
