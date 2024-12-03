# music_league
This repository shows the cleaning, exploratory data analysis, and visualization of the data from a personal game of Music League.

Music League is a competition where players must submit a song that fits the prompt for each round. After submissions, each player votes on which songs fit the prompt the most (or just what songs they liked the most), and may also vote on which songs they like the least. Each "upvote" awards a point to a player's total, and each downvote subtracts a point from a player's total. After the round, the player with the most points wins the round.

Data from each round was collected by an external program, and then aggregated, cleaned, and verified against the data on the site by me. I have altered the names to protect anonymity. 

visualizations - https://public.tableau.com/views/music_league_17327373344570/Totals?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link

## Field Definitions by Table
### **ml_votes**

*round_id* - round number

*song_title* - name of the song submitted by the Submitter

*submitter_id* - ID of the player that submitted the song

*voter_id* - ID of the player voting on the song

*vote_type* - type of vote placed by the Voter; upvote, downvote, or mid(no reaction)

### **player_names**

*player_id* - ID of each player

*player_name* - name of each player

### **round_names**

*round_id* - round number

*round_name* - name of round

### **vote_values**

*vote_type* - type of vote placed by the Voter; upvote, downvote, or mid (no reaction)

*point_value* the point value of each type of vote


Play your own League on https://musicleague.com/
