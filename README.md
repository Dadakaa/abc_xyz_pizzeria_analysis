# ABC-XYZ анализ продаж и ассортимента пиццерии

> **Дисклеймер:** проект выполнен на синтетических данных выдуманной компании в образовательных целях для демонстрации аналитических навыков.

## 1. Контекст и постановка задачи

Сеть «Тест-Пицца» стремится повысить прибыльность меню и эффективность управления ассортиментом. При большом количестве позиций часть пицц формирует основную долю выручки, тогда как другие продаются редко и могут создавать дополнительные издержки на закупку и хранение ингредиентов.

Цель исследования — определить наиболее ценные позиции меню, выявить продукты с низкой эффективностью и нестабильным спросом на основе ABC-XYZ анализа, а также разработать рекомендации по оптимизации ассортимента и управлению запасами.

<h4 align="center">Исходный датафрейм для осуществления анализа</h4>

|order_id|full_date|name|size|category|price|quantity|revenue|ingredients|
|--------|---------|----|----|--------|-----|--------|-------|-----------|
|1|2015-01-01 11:38:36|The Hawaiian Pizza|M|Classic|13.25|1|13.25|Sliced Ham, Pineapple, Mozzarella Cheese|
|2|2015-01-01 11:57:40|The Italian Supreme Pizza|L|Supreme|20.75|1|20.75|Calabrese Salami, Capocollo, Tomatoes, Red Onions, Green Olives, Garlic|
|2|2015-01-01 11:57:40|The Mexicana Pizza|M|Veggie|16.0|1|16.0|Tomatoes, Red Peppers, Jalapeno Peppers, Red Onions, Cilantro, Corn, Chipotle Sauce, Garlic|
|2|2015-01-01 11:57:40|The Five Cheese Pizza|L|Veggie|18.5|1|18.5|Mozzarella Cheese, Provolone Cheese, Smoked Gouda Cheese, Romano Cheese, Blue Cheese, Garlic|
|2|2015-01-01 11:57:40|The Classic Deluxe Pizza|M|Classic|16.0|1|16.0|Pepperoni, Mushrooms, Red Onions, Red Peppers, Bacon|


## 2. Проведение ABC анализа

### Параметры анализа:
#### 1. Анализ по количеству проданных единиц
**Метрика:** суммарное количество проданных единиц (quantity)
**<p>Пороги классификации:**
**<br>Категория A:** кумулятивная доля ≤ 80%
**<br>Категория B:** кумулятивная доля ≤ 95%
**<br>Категория C:** кумулятивная доля > 95%

#### 2. Анализ по выручке
**Метрика:** суммарная выручка (revenue)
**<p>Пороги классификации:**
**<br>Категория A:** кумулятивная доля ≤ 80%
**<br>Категория B:** кумулятивная доля ≤ 95%
**<br>Категория C:** кумулятивная доля > 95%

``` sql

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
```

|name|revenue|cumulative_revenue|total_revenue|pct_of_total_revenue|quantity|cumulative_quantity|total_quantity|pct_of_total_quantity|ingredients|category_revenue|category_quantity|abc_category|
|----|-------|------------------|-------------|--------------------|--------|-------------------|--------------|---------------------|-----------|----------------|-----------------|------------|
|The Thai Chicken Pizza|43434.25|43434.25|817860.05|5.31|2371|12096|49574|24.40|Chicken, Pineapple, Tomatoes, Red Peppers, Thai Sweet Chilli Sauce|A|A|AA|
|The Barbecue Chicken Pizza|42768.00|86202.25|817860.05|10.54|2432|4885|49574|9.85|Barbecued Chicken, Red Peppers, Green Peppers, Tomatoes, Red Onions, Barbecue Sauce|A|A|AA|
|The California Chicken Pizza|41409.50|127611.75|817860.05|15.60|2370|14466|49574|29.18|Chicken, Artichoke, Spinach, Garlic, Jalapeno Peppers, Fontina Cheese, Gouda Cheese|A|A|AA|
|The Classic Deluxe Pizza|38180.5|165792.25|817860.05|20.27|2453|2453|49574|4.95|Pepperoni, Mushrooms, Red Onions, Red Peppers, Bacon|A|A|AA|
|The Spicy Italian Pizza|34831.25|200623.50|817860.05|24.53|1924|18328|49574|36.97|Capocollo, Tomatoes, Goat Cheese, Artichokes, Peperoncini verdi, Garlic|A|A|AA|

``` sql
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
```

|abc_category|number_of_pizzas|revenue|total_revenue|pct_of_total_revenue|quantity|total_quantity|pct_of_total_quantity|
|------------|----------------|-------|-------------|--------------------|--------|--------------|---------------------|
|AA|21|645265.80|817860.05|78.90|39035|49574|78.74|
|BB|6|100477.50|817860.05|12.29|6231|49574|12.57|
|BC|1|15934.25|817860.05|1.95|937|49574|1.89|
|CB|1|13955.75|817860.05|1.71|997|49574|2.01|
|CC|3|42226.75|817860.05|5.16|2374|49574|4.79|

По результатам ABC-анализа основную часть продаж формируют позиции категории AA: **21 пицца из 32 (65.6% ассортимента) обеспечивают 78.9% общей выручки и 78.7% всех продаж**. Данные позиции являются ключевыми для бизнеса и формируют основу спроса со стороны клиентов.

Категория BB включает **6 пицц (18.8% ассортимента), которые обеспечивают 12.3% выручки и 12.6% продаж**. Эти позиции обладают средним вкладом в финансовые результаты и могут рассматриваться как потенциальные кандидаты для дополнительного продвижения и маркетинговых экспериментов.

Категории BC, CB и CC суммарно содержат **5 пицц (15.6% ассортимента), однако формируют лишь 8.8% общей выручки**. Для данных позиций рекомендуется проведение дополнительного анализа с точки зрения прибыльности, востребованности и целесообразности сохранения в ассортименте.

**При этом анализ не выявил ярко выраженных лидеров или аутсайдеров.** Показатели выручки и объёма продаж среди наиболее популярных пицц распределены относительно равномерно, а среди наименее востребованных позиций отсутствуют продукты, которые существенно отставали бы от остальных. **Это свидетельствует о достаточно сбалансированной структуре ассортимента и отсутствии критической зависимости бизнеса от отдельных позиций меню.**


## 3. Проведение XYZ анализа

### Параметры анализа:

#### Анализ по стабильности спроса

**Метрика:** коэффициент вариации (CV)

**<p>Пороги классификации:**
**<br>Категория X:** коэффициент вариации ≤ 0.10
**<br>Категория Y:** 0.10 < коэффициент вариации ≤ 0.12
**<br>Категория Z:** коэффициент вариации > 0.12

**<p> Ключевые статистические показатели:**
**<br>Среднее значение (avg_sales):** среднемесячное количество продаж пиццы
**<br>Стандартное отклонение (stddev):** показатель разброса месячных продаж относительно среднего значения
**<br>Коэффициент вариации (cv):** относительная мера изменчивости спроса, рассчитываемая как отношение стандартного отклонения к среднему значению продаж

**<p>Интерпретация категорий:**
**<br>Категория X:** стабильный и прогнозируемый спрос
**<br>Категория Y:** умеренные колебания спроса
**<br>Категория Z:** нестабильный спрос с высокой изменчивостью продаж

``` sql
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
```

|name|avg_sales|stddev|cv|xyz_category|
|----|---------|------|--|------------|
|The Barbecue Chicken Pizza|197.67|19.70|9.97|X|
|The Big Meat Pizza|150.92|14.27|9.46|X|
|The Brie Carre Pizza|40.00|5.32|13.30|Z|
|The Calabrese Pizza|77.25|10.13|13.11|Z|
|The California Chicken Pizza|191.83|18.83|9.82|X|


``` sql
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
  *
from abc_xyz_analysis_pizza
limit 5
```
|name|ingredients|revenue|quantity|abc_revenue_quantity|xyz_category|abc_xyz_rev_quant_cv|
|----|-----------|-------|--------|--------------------|------------|--------------------|
|The Thai Chicken Pizza|Chicken, Pineapple, Tomatoes, Red Peppers, Thai Sweet Chilli Sauce|43434.25|2371|AA|X|AAX|
|The Barbecue Chicken Pizza|Barbecued Chicken, Red Peppers, Green Peppers, Tomatoes, Red Onions, Barbecue Sauce|42768.00|2432|AA|X|AAX|
|The California Chicken Pizza|Chicken, Artichoke, Spinach, Garlic, Jalapeno Peppers, Fontina Cheese, Gouda Cheese|41409.50|2370|AA|X|AAX|
|The Classic Deluxe Pizza|Pepperoni, Mushrooms, Red Onions, Red Peppers, Bacon|38180.5|2453|AA|X|AAX|
|The Spicy Italian Pizza|Capocollo, Tomatoes, Goat Cheese, Artichokes, Peperoncini verdi, Garlic|34831.25|1924|AA|Y|AAY|

## 4. Интерпретация результатов и бизнес-рекомендации



