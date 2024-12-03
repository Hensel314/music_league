-- this series of queries is to compile, clean, and refine the round data into one table to prepare for exploratory data analysis
-- STEP 1: combine all 10 tables

create table ml_raw_comp (
SELECT * FROM r1_covers 
UNION SELECT  * FROM r2_shower_performers 
UNION SELECT  * FROM r3_grrrl_power 
UNION SELECT * FROM r4_awesome_obscurity 
UNION SELECT * FROM r5_one_word_title 
UNION SELECT * FROM r6_in_memoriam 
UNION SELECT * FROM r7_name_check 
UNION SELECT * FROM r8_instrumentals 
UNION SELECT * FROM r9_duets 
UNION SELECT * FROM r10_guilty_pleasures);

select *
from ml_raw_comp; # checking if the table formatted correctly

-- STEP 2: create duplicate table so we can keep a version of the raw data
create table ml_stage 
like ml_raw_comp
;

insert ml_stage
select*
from ml_raw_comp;

select *
from ml_stage;

-- STEP 3: standardizing column names
alter table ml_stage
rename column `Round` to round_name;

alter table ml_stage
rename column `title` to song_title;

alter table ml_stage
rename column `Point Value` to point_value;

-- STEP 4: check for duplicates
with duplicate_count as (
select *, 
	row_number() over(partition by round_name, song_title, submitter_name, voter_name, point_value) as entry_num
from ml_stage)
select * 
from duplicate_count
where entry_num > 1; 
#zero duplicates found

-- STEP 5: standardizing data
#5a : trim any leading or following spaces
update ml_stage
set round_name = trim(round_name), 
	song_title = trim(song_title),
    submitter_name = trim(submitter_name),
    voter_name = trim(voter_name),
    point_value = trim(point_value);
;

#5b: check for potential misspellings in different entries
select distinct round_name
from ml_stage;

select distinct song_title
from ml_stage;

select distinct submitter_name
from ml_stage;

select distinct voter_name
from ml_stage;

select distinct point_value
from ml_stage;

# all entries in the table have distinct spellings

-- STEP 6: check if any of the voters voted on themselves
select *
from ml_stage
where submitter_name = voter_name;
#these entries are errors from the data scraping program and need to be removed

delete from ml_stage
where submitter_name = voter_name;

-- STEP 7: check for nulls or empty spaces
select *
from ml_stage
where round_name = "" or round_name is null;

select *
from ml_stage
where song_title = "" or song_title is null;

select *
from ml_stage
where submitter_name = "" or submitter_name is null;

select *
from ml_stage
where voter_name = "" or voter_name is null;

select *
from ml_stage
where point_value = "" or point_value is null; #zeros have been returned, but this data is accurate
#zero nulls have been found

-- STEP 8: creating ID columns
#8a the round_names column already has a definite order, so we'll start with that first
alter table ml_stage
add round_id INTEGER(2);

update ml_stage
set round_id = 1
where round_name = "Covers" ;

update ml_stage
set round_id = 2
where round_name = "Shower Performers" ;

update ml_stage
set round_id = 3
where round_name = "Grrrl Power" ;

update ml_stage
set round_id = 4
where round_name = "Awesome Obscurity" ;

update ml_stage
set round_id = 5
where round_name = "One Word Title" ;

update ml_stage
set round_id = 6
where round_name = "In Memoriam" ;

update ml_stage
set round_id = 7
where round_name = "Name Check" ;

update ml_stage
set round_id = 8
where round_name = "Instrumentals" ;

update ml_stage
set round_id = 9
where round_name = "Duets" ;

update ml_stage
set round_id = 10
where round_name = "Guilty Pleasures" ;

select *
from ml_stage;

#8b assigning ID numbers to participants, and creating voter_id and submitter_id columns
alter table ml_stage
add submitter_id integer;

alter table ml_stage
add voter_id integer;

with player_ids as(
select distinct dense_rank() over(order by submitter_name) player_id, submitter_name player_name
from ml_stage)
select round_id,round_name, song_title, ids.player_id as submitter_id, submitter_name, vids.player_id as voter_id, voter_name
from ml_stage ms
join player_ids ids on ms.submitter_name = ids.player_name
join player_ids vids on ms.voter_name = vids.player_name
order by round_id, submitter_id
;

# filling the submitter_id column
with player_ids as(
select distinct dense_rank() over(order by submitter_name) player_id, submitter_name player_name
from ml_stage)
UPDATE ml_stage ms
    JOIN player_ids ids ON ms.submitter_name = ids.player_name
    SET ms.submitter_id = ids.player_id
    where ms.submitter_name = ids.player_name
;

#filling the voter_id column
with player_ids as(
select distinct dense_rank() over(order by submitter_name) player_id, submitter_name player_name
from ml_stage)
UPDATE ml_stage ms
    JOIN player_ids ids ON ms.voter_name = ids.player_name
    SET ms.voter_id = ids.player_id
    where ms.voter_name = ids.player_name
;

-- STEP 9: adding a "vote_type" column next to the "vote_value" column
alter table ml_stage
add vote_type varchar(10);

update ml_stage
set vote_type = "upvote"
where point_value = 1;

update ml_stage
set vote_type = "mid"
where point_value = 0;

update ml_stage
set vote_type = "downvote"
where point_value = -1;

select round_id, round_name, song_title, submitter_id, submitter_name, voter_id, voter_name, vote_type, point_value
from ml_stage; #checking the table in a proper column order

-- STEP 10: splitting the clean table into smaller specific tables to compartmentalize data
#"round_names" table
create table round_names (
	select distinct round_id, round_name
	from ml_stage);

#"player_names" table
create table player_names (
	select distinct submitter_id player_id, submitter_name player_name
	from ml_stage
	order by player_id);

#vote_value table 
create table vote_values (
	select distinct vote_type, point_value
	from ml_stage);

-- Now that there are seperate dependent tables, we can drop columns from the original table to make a clean, compact table
CREATE TABLE ml_votes (SELECT round_id, song_title, submitter_id, voter_id, vote_type FROM
    ml_stage);

