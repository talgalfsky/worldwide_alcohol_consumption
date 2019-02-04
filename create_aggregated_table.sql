
DROP TABLE IF EXISTS alc_dev CASCADE;
CREATE TABLE alc_dev (
country TEXT,
grams_male FLOAT,
grams_female FLOAT,
grams_both FLOAT,
beer_percent NUMERIC,
wine_percent NUMERIC,
spirits_percent NUMERIC,
other_percent NUMERIC,
beers NUMERIC,
wine NUMERIC,
spirit NUMERIC,
other NUMERIC,
beer_price_500ml NUMERIC, -- in USD
wine_price_750ml NUMERIC,
spirits_price_500ml NUMERIC,
beer_expanse_year NUMERIC,
wine_expanse_year NUMERIC,
spirits_expanse_year NUMERIC
);




-- insert data about consumption in grams and drinks percentage
INSERT INTO alc_dev(
      country,
			grams_male,
			grams_female,
			grams_both,
      beer_percent,
      wine_percent,
      spirits_percent,
      other_percent
)
SELECT
      t1.country,
      substring(t1.male from '^(.*?)\s\[')::FLOAT,  --get everything before [
      substring(t1.female from '^(.*?)\s\[')::FLOAT,
      substring(t1.both_sexes from '^(.*?)\s\[')::FLOAT,
      t2.beer,
      t2.wine,
      t2.spirits,
      t2.other

FROM average_daily_intake_in_grams_of_alcohol_by_country as t1
INNER JOIN consumption_by_type_of_alcoholic_beverages_by_country as t2
ON t1.country = t2.country;


-- Update weekly consumption in terms of beer cans, wine glasses, and shots
UPDATE alc_dev
    SET
       beer = 7*beer_percent*grams_both/14/100, --how many beers per week
       wine = 7*wine_percent*grams_both/14/100, --how many wine glass per week
       spirit = 7*spirits_percent*grams_both/14/100, --how many shots per week
       other = 7*other_percent*grams_both/14/100 --how many units of other beverages per week
        ;



-- add beverage prices --
UPDATE alc_dev
    SET
       beer_price_500ml = t2.price
    FROM avg_beer_price as t2
    WHERE alc_dev.country = t2.country;


UPDATE alc_dev
    SET
       wine_price_750ml = t2.price
    FROM avg_wine_price as t2
    WHERE alc_dev.country = t2.country;

UPDATE alc_dev
    SET
       spirits_price_500ml = t2.price
    FROM avg_spirits_price as t2
    WHERE alc_dev.country = t2.country;




-- calculate yearly expanses --
UPDATE alc_dev
    SET
       -- 1 beer can = 355ml . Ratio to 500 ml = 355/500 = 0.71
       beer_expanse_year = 0.71*365*beers*beer_price_500ml/7,
       -- 1 wine glass = 150ml . Ratio to 750 ml = 150/750 = 0.2
       wine_expanse_year = 0.2*365*wine*wine_price_750ml/7,
       -- 1 shot glass = 45ml . Ratio to 500 ml = 45/500 = 0.09
       spirits_expanse_year = 0.09*365*spirit*spirits_price_500ml/7
;


SELECT country,
       beer_expanse_year,
       wine_expanse_year,
       spirits_expanse_year,
       coalesce(beer_expanse_year, 0)+
       coalesce(wine_expanse_year, 0)+
       coalesce(spirits_expanse_year, 0) AS total
FROM alc_dev
ORDER BY total DESC;


ALTER TABLE alc_dev
ADD COLUMN year_total NUMERIC;

UPDATE alc_dev
    SET year_total = coalesce(beer_expanse_year, 0)+
       coalesce(wine_expanse_year, 0)+
       coalesce(spirits_expanse_year, 0);


-- add data for divorce rates --
INSERT INTO alc_dev(

SELECT
      a.country,
      a.grams_male/a.grams_female as ratio,
      b.d_m_ratio
FROM alc_dev as a
INNER JOIN global_divorce_rates as b
ON a.country = b.country
ORDER BY ratio desc;






-- leftovers

SELECT
      country,
      substring(male from '^(.*?)\s\[')::FLOAT,  --get everything before [
      substring(female from '^(.*?)\s\[')::FLOAT,
      substring(both_sexes from '^(.*?)\s\[')::FLOAT
FROM average_daily_intake_in_grams_of_alcohol_by_country;