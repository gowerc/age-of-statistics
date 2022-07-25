





select a.match_id, leaderboard_id, started,
    started - 1657713600 as time
from match_meta a
where 
    leaderboard_id = 4 and
    started > 1657713600
order by time
limit 10;



1657670400
13 July 2022 00:00:00

1657756799
13 July 2022 23:59:59


1657669200  
12 July 2022 23:40:00
\dt

\list
