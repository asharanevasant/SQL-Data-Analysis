use practise
go
/*
1- write a query to print top 5 cities with highest spends 
and their percentage contribution of total credit card spends 
*/

;WITH CTE_TOT_SPENDING
AS
(
	--retrieve total amount.
	SELECT 
		SUM(AMOUNT) TOTAL_SPENDING
	FROM credit_card_transcations_1
)
, CTE_CITY_SPENDING
AS
(
	--retrieve citywise total amount.
	SELECT 
		CITY, 
		SUM(AMOUNT) CITY_SPENDING
	FROM credit_card_transcations_1
	GROUP BY CITY
)
--top 5 cities with highest spends & their percentage contribution of total credit card spends
SELECT TOP 5 
	CITY, 
	CITY_SPENDING,
	ROUND( CITY_SPENDING * 100.00 / NULLIF(TOTAL_SPENDING,0) ,2) AS '%'
FROM CTE_CITY_SPENDING
JOIN CTE_TOT_SPENDING
ON  1=1
ORDER BY CITY_SPENDING DESC


--2- write a query to print highest spend month and amount spent in that month for each card type

;with cte1
as
(
	select 
		cast(year(transaction_date) as varchar) 
		+ ' ' + 
		cast(datename(month, transaction_date) as varchar) as highest_spend_month , 
		card_type,
		sum(amount) amount_spent 
	from credit_card_transcations_1
	group by year(transaction_date), datename(month, transaction_date), card_type
)
select *
from 
	(
		select 
			*, ROW_NUMBER() over(partition by card_type order by amount_spent desc) as rn
		from cte1
	) a
	where rn = 1

/*
	3- write a query to print the transaction details(all columns from the table) for each card type when
	it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
*/

;with cte
as
(
	select *,sum(amount) over(partition by card_type order by transaction_date,transaction_id) cumulative_total
	from credit_card_transcations_1

)
,cte2 
as
(
	select *, ROW_NUMBER() over(partition by card_type order by cumulative_total) rn
	from cte
	where cumulative_total >= 1000000
--order by card_type
) 
select *
from cte2
where rn =1


--4- write a query to find city which had lowest percentage spend for gold card type
;with cte_gold_tot_spend
as
(
	select sum(amount) gold_total_spend 
	from credit_card_transcations_1
	where card_type = 'gold'
)
,cte_city_wise_spend
as
(
	select city, sum(amount) city_wise_amount_spend
	from credit_card_transcations_1
	where card_type = 'gold'
	group by city

)
select top 1 city,(city_wise_amount_spend * 100.00 / nullif( gold_total_spend,0)) 'percentage_spent'
from cte_city_wise_spend
join cte_gold_tot_spend
on 1=1
order by percentage_spent 

--5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

;with cte
as
(select 
	city, 
	exp_type,
	sum(amount) amount
from credit_card_transcations_1
group by city,exp_type
)
,
cte2
as
(
	select 
	*, 
	dense_rank() over(partition by city order by amount desc) rn_desc,
	dense_rank() over(partition by city order by amount ) rn_asc
	from cte
)
select 
	city,
	max(case when rn_desc = 1 then exp_type end)  high_exp_type,
	min(case when rn_asc = 1 then exp_type end)  low_exp_type
from cte2
group by city

--6- write a query to find percentage contribution of spends by females for each expense type

;with cte_total_female_exp
as
(
	select exp_type, sum(amount) total_amount
	from credit_card_transcations_1
	--where gender = 'f'
	group by exp_type
)
,cte_exp_type_total
as
(
	select exp_type, sum(amount) exp_type_amount
	from credit_card_transcations_1
	where gender = 'f'
	group by exp_type 
)
select c.exp_type, exp_type_amount * 100.00 / nullif(total_amount,0) as 'percentage_contribution '
,cast(round( exp_type_amount * 100.00 / nullif(total_amount,0),2) as decimal(10,2))
from cte_exp_type_total c
join cte_total_female_exp fe
on 1=1
and c.exp_type = fe.exp_type
order by percentage_contribution desc

----or----

select exp_type,sum(case when gender='F' then amount else 0 end),sum(amount),
round(sum(case when gender='F' then amount else 0 end)*100.0/sum(amount),2) as percentage_female_contribution
from credit_card_transcations_1
group by exp_type
order by percentage_female_contribution desc;


--7- which card and expense type combination saw highest month over month growth in Jan-2014

;with c1
as
(
	select 
		card_type, exp_type,DATEPART(year,transaction_date) yt,
		DATEPART(month,transaction_date) mt,
		sum(amount) as total_spend
	from credit_card_transcations_1
	group by card_type, exp_type,DATEPART(year,transaction_date) ,
		DATEPART(month,transaction_date)
)
,c2
as
(
	select *, lag(total_spend) over(partition by card_type, exp_type  order by yt, mt) prev_mth_spend
	from c1 
)
select top 1 *,total_spend - prev_mth_spend as mon_growth
from c2 
where yt=2014 and mt=1
order by mon_growth desc

--9- during weekends which city has highest total spend to total no of transcations ratio 

SELECT TOP 1
    city,
    SUM(amount) AS total_spend,
    COUNT(*) AS total_transactions,
    CAST(
        SUM(amount) * 1.0 / COUNT(*)
        AS DECIMAL(18,2)
    ) AS spend_per_transaction
FROM credit_card_transcations_1
WHERE DATENAME(WEEKDAY, transaction_date) IN ('Saturday', 'Sunday')
GROUP BY city
ORDER BY spend_per_transaction DESC;


--10- which city took least number of days to reach its 500th transaction after the first transaction in that city

;with cte
as
(
	select *, ROW_NUMBER() over(partition by city order by transaction_date,transaction_id ) rn
	from credit_card_transcations_1
)
select 
	city, datediff(day,min(transaction_date), max(transaction_date)) datedifference_day
from cte
where rn=1 or rn= 500 
group by city
--check least no of days
having count(1) = 2
order by datedifference_day

