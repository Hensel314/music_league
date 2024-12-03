-- Music League Exploratory Data Analysis
/* Goals:
1) Create Tables to show how many votes of each type everyone recieved, and their overall point total.
2) Create tables to show rolling upvotes, mids, downvotes, and totals for each player by by round.
4) Create a table showing each player's "upvote rate":
	the the percentage of upvotes they recieved vs. the total upvotes they could have recieved
2) Find Average round totals for each player.

3) Answer the following questions:
	a) Whose point total was the highest? Did they also have the most upvotes?
    b) Whose point total was the lowest? Did they also have the most downvotes?
    c) Which players had the most round wins?
    d) Which players came in last the most each round?
*/

-- Total Votes 
#Creating a temporary table to attach player names to values
create temporary table name_votes (
	select pn.player_name, mv.vote_type
	from ml_votes mv
	join player_names pn on submitter_id = player_id)
; 

# Total Votes: Upvotes
select distinct player_name, count(*) upvote_count
from name_votes
where vote_type = "upvote"
group by player_name
order by 2 desc
; #Envy recieved the the most upvotes, and Shaan recieved the fewest

# Total Votes: Mids
select distinct player_name, count(*) mid_count
from name_votes
where vote_type = "mid"
group by player_name
order by 2 desc
; # Michael recieved the most mids, and Shaan recieved the fewest mids

# Total Votes: Downvotes
select distinct player_name, count(*) downvote_count
from name_votes
where vote_type = "downvote"
group by player_name
order by 2 desc
; # Farhan recieved the most downvotes, while Shaan recieved the fewest.

# Total Votes: Totals. This will need to be more complex because point vaues need to be aggregated
select distinct player_name, sum(point_value) total_points
from name_votes nv
join vote_values vv on nv.vote_type = vv.vote_type
group by player_name
order by 2 desc
; #Envy won the league with the most total points, Farhan lost with a net total of 0 points.

-- Rolling Tables
# Temp Table
create temporary table round_votes(
	select round_id, player_name, vote_type
	from ml_votes mv
	join player_names on submitter_id = player_id)
;

#Rolling Upvotes
select distinct round_id, player_name, count(vote_type) over(partition by player_name order by round_id) rolling_upvotes
from round_votes
where vote_type = "upvote"
;

#Rolling Mids
select distinct round_id, player_name, count(vote_type) over(partition by player_name order by round_id) rolling_mids
from round_votes
where vote_type = "mid"
;

#Rolling Downvotes
select distinct round_id, player_name, count(vote_type) over(partition by player_name order by round_id) rolling_downvotes
from round_votes
where vote_type = "downvote"
;

#Rolling Totals
select distinct round_id, player_name, sum(point_value) over(partition by player_name order by round_id) rolling_total
from round_votes rv
join vote_values pv on rv.vote_type = pv.vote_type
order by player_name, round_id
;

-- Upvote Rate
With upvotes as (
	select player_name, count(*) upvotes
	from ml_votes
	join player_names on submitter_id = player_id
	where vote_type = 'upvote'
	group by player_name
),
total_votes as (
	select distinct player_name, count(*) total_votes
	from ml_votes
	join player_names on submitter_id = player_id
	group by player_name
)
select up.player_name, (upvotes/total_votes) upvote_rate
from upvotes up
join total_votes tv
	on up.player_name = tv.player_name
order by upvote_rate desc
;

-- Average Round Score 
with round_scores as (
	select round_id, player_name, sum(point_value) round_score
	from ml_votes mv
    join player_names pn
		on submitter_id = player_id
	join vote_values vv
		on mv.vote_type = vv.vote_type
	group by round_id, player_name
)
select player_name, avg(round_score) avg_round_score
from round_scores
group by player_name
order by avg_round_score desc
;

-- Which player had the most round wins?
with round_ranks as(
select round_id, player_name, sum(point_value) round_points, 
	rank() over(partition by round_id order by sum(point_value) desc) round_rank
from ml_votes mv
join player_names pn on mv.submitter_id = pn.player_id
join vote_values vv on mv.vote_type = vv.vote_type
group by round_id, player_name
)
select player_name, count(round_rank) win_count
from round_ranks
where round_rank = 1
group by player_name
order by win_count desc
; 
# Envy won the most rounds, winning 3 times

-- Which Player had the most round losses?
with round_ranks as(
select round_id, player_name, sum(point_value) round_points, 
	rank() over(partition by round_id order by sum(point_value)) round_rank
from ml_votes mv
join player_names pn on mv.submitter_id = pn.player_id
join vote_values vv on mv.vote_type = vv.vote_type
group by round_id, player_name
)
select player_name, count(round_rank) loss_count
from round_ranks
where round_rank = 1
group by player_name
order by loss_count desc
;
# Farhan loss the most rounds