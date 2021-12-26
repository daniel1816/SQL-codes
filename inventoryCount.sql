/*quetions:We want to generate an inventory age report which would show the distribution of remaining inventory across the length of time the inventory has been sitting at the warehouse. We are trying to classify the inventory on hand across the below 4 buckets to denote the time the inventory has been lying the warehouse.

0-90 days old 
91-180 days old
181-270 days old
271 – 365 days old
*/

--create db, table and insert data
drop table warehouse;
create table warehouse
(
	ID						varchar(10),
	OnHandQuantity			int,
	OnHandQuantityDelta		int,
	event_type				varchar(10),
	event_datetime			datetime
);

insert into warehouse values ('SH0013', 278,   99 ,   'OutBound', convert(DATETIME,'2020-05-25 0:25'));
insert into warehouse values ('SH0012', 377,   31 ,   'InBound',  convert(DATETIME,'2020-05-24 22:00'));
insert into warehouse values ('SH0011', 346,   1  ,   'OutBound', convert(DATETIME,'2020-05-24 15:01'));
insert into warehouse values ('SH0010', 346,   1  ,   'OutBound', convert(DATETIME,'2020-05-23 5:00'));
insert into warehouse values ('SH009',  348,   102,   'InBound',  convert(DATETIME,'2020-04-25 18:00'));
insert into warehouse values ('SH008',  246,   43 ,   'InBound',  convert(DATETIME,'2020-04-25 2:00'));
insert into warehouse values ('SH007',  203,   2  ,   'OutBound', convert(DATETIME,'2020-02-25 9:00'));
insert into warehouse values ('SH006',  205,   129,   'OutBound', convert(DATETIME,'2020-02-18 7:00'));
insert into warehouse values ('SH005',  334,   1  ,   'OutBound', convert(DATETIME,'2020-02-18 8:00'));
insert into warehouse values ('SH004',  335,   27 ,   'OutBound', convert(DATETIME,'2020-01-29 5:00'));
insert into warehouse values ('SH003',  362,   120,   'InBound',  convert(DATETIME,'2019-12-31 2:00'));
insert into warehouse values ('SH002',  242,   8  ,   'OutBound', convert(DATETIME,'2019-05-22 0:50'));
insert into warehouse values ('SH001',  250,   250,   'InBound',  convert(DATETIME,'2019-05-20 0:45'));

--step 1: declare variables: current date and current qty
 declare @current smalldatetime;
  set @current =(
  select max(event_datetime)
  from warehouse);

  declare @curQty int;
  set @curQty = (
  select OnHandQuantity
  from warehouse
  where event_datetime = @current);

--step 2.2: create temp table with current inventory before substrcting the outbound
  with temp1 as(
  select t.inventory_days,
	sum(t.OnHandQuantityDelta) as qty 
  from(
  select *,
	case when datediff(day, event_datetime, @current) <= 90 then 'day_90'
		when datediff(day, event_datetime, @current) <= 180 then 'day_180'
		when datediff(day, event_datetime, @current) <= 270 then 'day_270'
		when datediff(day, event_datetime, @current) <=365 then 'day_365'
		when datediff(day, event_datetime, @current) >365 then 'over_365'
	end as inventory_days
  from warehouse) t
  where event_type = 'InBound'
  group by inventory_days),
--step 2.2: pivot the temp talbe and replace the null values with 0;
temp2 as (
select coalesce(t.[day_90],0) as day_90,
  coalesce(t.[day_180],0) as day_180,
  coalesce(t.[day_270],0) as day_270,
  coalesce(t.[day_365],0) as day_365
  from(
  select * from temp1	
  pivot(sum(qty)
  for inventory_days IN([day_90],[day_180],[day_270],[day_365]))
  as ptable) t)
 --step 3: use case when to get the final table
 select
	case when t.day_90>@curQty then @curQty
	else t.day_90 end as '0-90 days old',
	case when @curQty>(t.day_90+t.day_180) then t.day_180
		when @curQty<t.day_90 then 0
		when @curQty>t.day_90 AND @curQty<(t.day_180+t.day_90) then @curQty-t.day_90
		end as '91-180 days old',
	case when @curQty>(t.day_90+t.day_180+t.day_270) then t.day_270
		when @curQty<t.day_90+t.day_180 then 0
		when @curQty>(t.day_90+t.day_180) AND @curQty<(t.day_180+t.day_90+t.day_270) then @curQty-t.day_90-t.day_180 
		end as '181-270 days old',
	case when @curQty>(t.day_90+t.day_180+t.day_270+t.day_365) then t.day_365
		when @curQty<t.day_90+t.day_180+ t.day_365 then 0
		when @curQty>(t.day_90+t.day_180+t.day_365) AND @curQty<(t.day_180+t.day_90+t.day_270+t.day_365) then @curQty-t.day_90-t.day_180 -t.day_270
		end as '271-365 days old'
 from temp2 t




  