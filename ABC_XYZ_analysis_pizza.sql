select 
	* 
from pizza_sales
order by order_id
limit 5

/*==================================================
  VIEW: abc_analysis_pizza
  Описание: ABC-анализ по выручке и количеству
==================================================*/

create or replace view abc_analysis_pizza as
with pre_data as (
	select
		name,
		sum(revenue) revenue,
		sum(sum(revenue)) over(order by sum(revenue) desc) cumulative_revenue,
		sum(sum(revenue)) over() total_revenue,
		round(sum(sum(revenue)) over(order by sum(revenue) desc) * 100.0 / sum(sum(revenue)) over(), 2) pct_of_total_revenue,
		sum(quantity) quantity,
		sum(sum(quantity)) over(order by sum(quantity) desc) cumulative_quantity,
		sum(sum(quantity)) over() total_quantity,
		round(sum(sum(quantity)) over(order by sum(quantity) desc) * 100.0 / sum(sum(quantity)) over(), 2) pct_of_total_quantity,
		ingredients 
	from pizza_sales
	group by name, ingredients 
), pre_data_2 as (
select
	*,
	case
		when pct_of_total_revenue <= 80 then 'A'
		when pct_of_total_revenue <= 95 then 'B'
		when pct_of_total_revenue <= 100 then 'C'
	end category_revenue,
	case
		when pct_of_total_quantity <= 80 then 'A'
		when pct_of_total_quantity <= 95 then 'B'
		when pct_of_total_quantity <= 100 then 'C'
	end category_quantity
from pre_data
)

select
	*,
	concat(category_revenue, category_quantity) abc_category
from pre_data_2;

/*==================================================
ABC-анализ по выручке и количеству
==================================================*/

select 
	* 
from abc_analysis_pizza
limit 5

/*==================================================
  Анализ количества проданной и выручки по каждой из категорий
==================================================*/

select
	abc_category,
	count(name) as number_of_pizzas,
	sum(revenue) revenue,
	total_revenue,
	round(sum(revenue) * 100.0 / total_revenue, 2) pct_of_total_revenue,
	sum(quantity) quantity,
	total_quantity,
	round(sum(quantity) * 100.0 / total_quantity, 2) pct_of_total_quantity
from abc_analysis_pizza
group by abc_category, total_revenue, total_quantity
order by abc_category


/*==================================================
  VIEW: xyz_analysis_pizza
  Описание: XYZ-анализ по выручке и количеству
==================================================*/

create or replace view xyz_analysis_pizza as
with pre_data as (
	select
		name,
		date_trunc('month', full_date)::date as date,
		count(quantity) quantity,
		round(avg(count(quantity)) over(partition by name), 2) as avg_sales,
		round(stddev_pop(count(quantity)) over(partition by name), 2) as stddev,
		round(round(stddev_pop(count(quantity)) over(partition by name), 2) * 100.0
		/ round(avg(count(quantity)) over(partition by name), 2), 2) as CV
		
	from pizza_sales
	group by name, date_trunc('month', full_date)::date
	order by name, date_trunc('month', full_date)::date
), pre_data_2 as (
	select 
		distinct name,
		avg_sales,
		stddev,
		cv,
		case
			when cv <= 10 then 'X'
			when cv <= 12 then 'Y'
			else 'Z'
		end xyz_category
	from pre_data
)

select 
	* 
from pre_data_2

/*==================================================
  Анализ пиццы по XYZ
==================================================*/

select
	*
from xyz_analysis_pizza
limit 5

/*==================================================
  Создание view с объединением ABC и XYZ анализов в 1 таблицу
==================================================*/

create view abc_xyz_analysis_pizza as
select
	a.name,
	a.ingredients,
	a.revenue,
	a.quantity,
	a.abc_category as abc_revenue_quantity,
	x.xyz_category,
	concat(a.abc_category, x.xyz_category) as abc_xyz_rev_quant_cv
	
from abc_analysis_pizza a
	join xyz_analysis_pizza x on a.name = x.name
order by a.revenue desc, a.quantity desc


/*==================================================
  Анализ пиццы по ABC-XYZ
==================================================*/
select 
	name,
	revenue,
	quantity,
	abc_revenue_quantity,
	xyz_category,
	abc_xyz_rev_quant_cv
from abc_xyz_analysis_pizza
order by revenue, quantity
limit 5
	
select *
from (
    select 
	    name,
		revenue,
		quantity,
		abc_revenue_quantity,
		xyz_category,
		abc_xyz_rev_quant_cv
	    from abc_xyz_analysis_pizza
	    order by revenue asc, quantity asc
	    limit 5
)
order by revenue desc

select
	*
from abc_xyz_analysis_pizza
where abc_xyz_rev_quant_cv = 'BBZ' or abc_xyz_rev_quant_cv like 'BC%' or abc_xyz_rev_quant_cv like 'CB%' or abc_xyz_rev_quant_cv like 'CC%'
order by revenue desc
