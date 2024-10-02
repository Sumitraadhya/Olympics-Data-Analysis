--Link to dataset:----
https://www.kaggle.com/datasets/heesoo37/120-years-of-olympic-history-athletes-and-results?resource=download


select * from OLYMPICS_HISTORY;
select * from OLYMPICS_HISTORY_NOC_REGIONS;

--1. How many olympics games have been held?
select Count(distinct games) as total_olympic_games
  from OLYMPICS_HISTORY;

--2. List down all Olympics games held so far.
select distinct year, season, city 
  from OLYMPICS_HISTORY
  order by year;

--3.Mention the total no of nations who participated in each olympics game?
with all_countries as
        (select games, nr.region
        from olympics_history oh
        join olympics_history_noc_regions nr ON nr.noc = oh.noc
        group by games, nr.region)
    select games, count(1) as total_countries
    from all_countries
    group by games
    order by games;

--4.Which year saw the highest and lowest no of countries participating in olympics?
with all_countries as
              (select games, nr.region as country
              from olympics_history oh
              join olympics_history_noc_regions nr ON nr.noc=oh.noc
              group by games, nr.region),
	   t1 as (
  select games, count(country) as total_country, 
  rank() OVER( order by count(country) desc ) as highest_cnt,
  rank() OVER(order by count(country) ) as lowest_cnt
    from all_countries
    group by games)
select 
max(case when  highest_cnt=1 then concat(games,' - ', total_country) end) as highest_country,
max(case when  lowest_cnt=1 then  concat(games,' - ', total_country) end) as lowest_country
 from t1
 where highest_cnt=1 or lowest_cnt=1;

--5. Which nation has participated in all of the olympic games?
with total_game as 
   (select count(distinct games) as total_games from OLYMPICS_HISTORY),
    countries as (
  select games , nr.region  as country
   from OLYMPICS_HISTORY as oh JOIN OLYMPICS_HISTORY_NOC_REGIONS as nr
   ON oh.noc=nr.NOC
  group by games,  nr.region),
  countries_participated as (
  select country, count(country) as total_participated_games
     from countries
      group by country)
 select  cp.*
   from countries_participated as cp JOIN total_game as tg
  ON cp.total_participated_games=tg.total_games;

--6.Identify the sport which was played in all summer olympics.
with t1 as 
  (select count(distinct games) as total_games from OLYMPICS_HISTORY  where season='Summer'),
  t2 as (
      select  distinct games, sport from OLYMPICS_HISTORY
       where season='Summer'),
  t3 as (
      select sport, count(sport) as sport_played from t2 group by sport)
  select t3.*
 from t3 JOIN   t1
ON t1.total_games=t3.sport_played;

---7.Which Sports were just played only once in the olympics?

with t1 as (
select games, sport
 from OLYMPICS_HISTORY
group by games, sport),
t2 as (
select  sport, count(*) as sport_count
	from t1 group by sport)
select t1.sport, sport_count from t1 JOIN t2
ON t1.sport=t2.sport
where sport_count=1
order by t1.sport;

---8.Fetch the total no of sports played in each olympic games.
  select distinct games, count(distinct sport) as sport_cnt
       from OLYMPICS_HISTORY
  group by distinct games;

---9.Fetch details of the oldest athletes to win a gold medal.
  with CTE as (
         select *, dense_rank() Over(order by age desc)  as rn
        from OLYMPICS_HISTORY
   where medal='Gold' and age NOT IN ('NA'))
 select * from CTE where rn=1;

---10.Find the Ratio of male and female athletes participated in all olympic games.
  with CTE as (
 select  
  sum(case when sex='M' then 1 end) as male_count,
  sum(case when sex='F' then 1 end) as female_count
       from OLYMPICS_HISTORY)
select concat('1 : ', round(male_count::numeric/female_count::numeric,2)) as ratio from CTE;

--11.Fetch the top 5 athletes who have won the most gold medals.
  with top_5 as (
      select name, count(medal) as total_gold_medal,
   Dense_rank() OVER( order by count(medal) desc) as drn
 from OLYMPICS_HISTORY
where medal='Gold'
group by name
)
select distinct top_5.name, team, total_gold_medal 
from top_5 left join OLYMPICS_HISTORY as oh
ON top_5.name=oh.name
where drn<=5
order by total_gold_medal  desc;

---12.Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
 with top_5 as (
      select name, count(medal) as total_medal,
         Dense_rank() OVER(order by count(medal) desc) as drn
    from OLYMPICS_HISTORY
  where medal IN ('Gold', 'Silver', 'Bronze')
 group by name
)
  select distinct top_5.name, team, total_medal 
 from top_5 left join OLYMPICS_HISTORY as oh
   ON top_5.name=oh.name
 where drn<=5
 order by total_medal  desc;

---13.Fetch the top 5 most successful countries in olympics. 
--Success is defined by no of medals won.
 with t1 as (
  select region, count(medal) as total_medal
   from OLYMPICS_HISTORY as oh JOIN OLYMPICS_HISTORY_NOC_REGIONS as reg
  ON oh.noc=reg.noc
 where medal <>'NA'
group by region),
  t2 as (
select region, total_medal, dense_rank() OVER(order by total_medal desc ) as drn
  from t1)
select * from t2
where drn<=5;

---14.List down total gold, silver and broze medals won by each country.
with CTE as(
select region as country , medal
from OLYMPICS_HISTORY as oh JOIN OLYMPICS_HISTORY_NOC_REGIONS as reg
ON oh.noc=reg.noc
where medal <>'NA')
select country,
SUM(case when medal='Gold' then 1 else 0 end) as Gold,
SUM(case when medal='Silver' then 1 else 0 end) as Silver,
SUM(case when medal='Bronze' then 1 else 0 end) as Bronze
from CTE
group by country
order by gold desc;

----15.List down total gold, silver and broze medals won by each country
--corresponding to each olympic games.
with CTE as(
select games, region as country , medal
from OLYMPICS_HISTORY as oh JOIN OLYMPICS_HISTORY_NOC_REGIONS as reg
ON oh.noc=reg.noc
where medal <>'NA')
select games, country,
SUM(case when medal='Gold' then 1 else 0 end) as Gold,
SUM(case when medal='Silver' then 1 else 0 end) as Silver,
SUM(case when medal='Bronze' then 1 else 0 end) as Bronze
from CTE
group by games, country
order by games;

---16.Identify which country won the most gold, most silver and
--most bronze medals in each olympic games.
with t1 as(
select games, region as country , medal
from OLYMPICS_HISTORY as oh JOIN OLYMPICS_HISTORY_NOC_REGIONS as reg
ON oh.noc=reg.noc
where medal <>'NA'),
t2 as(
select games, country,
SUM(case when medal='Gold' then 1 else 0 end) as Gold,
SUM(case when medal='Silver' then 1 else 0 end) as Silver,
SUM(case when medal='Bronze' then 1 else 0 end) as Bronze
from t1
group by games, country), 
t3 as (
select games, country, Gold, Silver, Bronze,
dense_rank() OVER(Partition BY games order by gold desc) as max_gold,
dense_rank() OVER(Partition BY games order by silver desc) as max_silver,
dense_rank() OVER(Partition BY games order by bronze desc) as max_bronze
from t2 )
select games, 
max(case when max_gold=1 then concat(country, '-', gold) end) as max_gold_country, 
max(case when max_silver=1 then concat(country, '-', silver) end) as max_silver_country,
max(case when max_bronze=1 then concat(country, '-', bronze) end) as max_bronze_country
from t3
where max_gold=1 or  max_silver=1 or max_bronze=1
group by games;

----17.Identify which country won the most gold, most silver, most bronze medals and 
--the most medals in each olympic games.

with t1 as(
select games, region as country , medal
from OLYMPICS_HISTORY as oh JOIN OLYMPICS_HISTORY_NOC_REGIONS as reg
ON oh.noc=reg.noc
where medal <>'NA'),
t2 as(
select games, country,
SUM(case when medal IN ('Gold', 'Silver', 'Bronze') then 1 else 0 end) as total_medal,  	
SUM(case when medal='Gold' then 1 else 0 end) as Gold,
SUM(case when medal='Silver' then 1 else 0 end) as Silver,
SUM(case when medal='Bronze' then 1 else 0 end) as Bronze
from t1
group by games, country), 
t3 as (
select games, country, Gold, Silver, Bronze, total_medal,
dense_rank() OVER(Partition BY games order by total_medal desc) as max_medal, 
dense_rank() OVER(Partition BY games order by gold desc) as max_gold,
dense_rank() OVER(Partition BY games order by silver desc) as max_silver,
dense_rank() OVER(Partition BY games order by bronze desc) as max_bronze
from t2 )
select games,  
max(case when max_gold=1 then concat(country, '-', gold) end) as max_gold_country, 
max(case when max_silver=1 then concat(country, '-', silver) end) as max_silver_country,
max(case when max_bronze=1 then concat(country, '-', bronze) end) as max_bronze_country,
max(case when max_medal=1 then concat(country, '-', total_medal) end) as max_medal_country
from t3
where max_gold=1 or  max_silver=1 or max_bronze=1 or max_medal=1
group by games;


----18.Which countries have never won gold medal but have won silver/bronze medals?
with t1 as(
select  region as country , medal
from OLYMPICS_HISTORY as oh JOIN OLYMPICS_HISTORY_NOC_REGIONS as reg
ON oh.noc=reg.noc
where medal <> 'NA' ),
t2 as(
select country,	
SUM(case when medal='Gold' then 1 else 0 end) as Gold,
SUM(case when medal='Silver' then 1 else 0 end) as Silver,
SUM(case when medal='Bronze' then 1 else 0 end) as Bronze
from t1
group by country)
select * 
from t2
where Gold=0
order by Silver desc;

---19.In which Sport/event, India has won highest medals.
with t1 as(
    select  sport, count(medal)  as total_medal,
  dense_rank() OVER(order by count(medal) desc) as drn
 from OLYMPICS_HISTORY as oh JOIN OLYMPICS_HISTORY_NOC_REGIONS as reg
        ON oh.noc=reg.noc
  where medal <> 'NA'  and  region='India'
 group by sport)
select sport, total_medal 
from t1 
where drn=1;

---20.Break down all olympic games where india won medal for Hockey and 
--how many medals in each olympic games.
select  team, sport, games, count(medal)  as total_medal
from OLYMPICS_HISTORY 
where medal <> 'NA'  and  team='India' and sport='Hockey'
group by games, team, sport
order by total_medal desc



















