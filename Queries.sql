--Requirement 1: Top 2 Categories
--For each customer, we need to identify the top 2 categories for each customer based off their past rental history. 
--These top categories will drive marketing creative images as seen in the travel and sci-fi examples in the draft email.


--First created a complete_joint_dataset which joins multiple tables together after analysing the relationships between 
--each table to confirm if there was a one-to-many, many-to-one or a many-to-many relationship for each of the join columns.
--Also included the rental_date column to help us split ties for rankings which had the same count of rentals at a customer 
--level - this helps us prioritise film categories which were more recently viewed.

DROP TABLE IF EXISTS complete_joint_dataset;
CREATE TEMP TABLE complete_joint_dataset AS
SELECT
  rental.customer_id,
  inventory.film_id,
  film.title,
  rental.rental_date,
  category.name AS category_name
FROM dvd_rentals.rental
INNER JOIN dvd_rentals.inventory
  ON rental.inventory_id = inventory.inventory_id
INNER JOIN dvd_rentals.film
  ON inventory.film_id = film.film_id
INNER JOIN dvd_rentals.film_category
  ON film.film_id = film_category.film_id
INNER JOIN dvd_rentals.category
  ON film_category.category_id = category.category_id;

SELECT * FROM complete_joint_dataset limit 10;

--Creating Category Counts
--Created a follow-up table which uses the complete_joint_dataset to aggregate  data and 
--generate a rental_count and the latest rental_date for our ranking purposes downstream.

DROP TABLE IF EXISTS category_counts;
CREATE TEMP TABLE category_counts AS
SELECT
  customer_id,
  category_name,
  COUNT(*) AS rental_count,
  MAX(rental_date) AS latest_rental_date
FROM complete_joint_dataset
GROUP BY
  customer_id,
  category_name;
  
SELECT *
FROM category_counts
--WHERE customer_id = 1
ORDER BY
    customer_id,
    rental_count DESC,
    latest_rental_date DESC;
    

-- Creating Top 2 Categories using a DENSE_RANK window function.
--To split ties ,recent lastest_rental_date value generated in category_counts. To further prevent any ties - 
--sort by the category_name in alphabetical (ascending) order.


DROP TABLE IF EXISTS top_categories;
CREATE TEMP TABLE top_categories AS
WITH ranked_cte AS (
  SELECT
    customer_id,
    category_name,
    rental_count,
    DENSE_RANK() OVER (
      PARTITION BY customer_id
      ORDER BY
        rental_count DESC,
        latest_rental_date DESC,
        category_name
    ) AS category_rank
  FROM category_counts
)
SELECT * FROM ranked_cte
WHERE category_rank <= 2;

SELECT *
FROM top_categories;


--Creating Total Counts table:category_counts table to generate total_counts table.

DROP TABLE IF EXISTS total_counts;
CREATE TEMP TABLE total_counts AS
SELECT
  customer_id,
  SUM(rental_count) AS total_count
FROM category_counts
GROUP BY
  customer_id;

SELECT *
FROM total_counts
LIMIT 5;