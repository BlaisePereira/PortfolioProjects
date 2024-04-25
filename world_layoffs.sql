-- Data Cleaning


-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null value or blank values
-- 4. Remove columns that are not required


USE layoffs;

Select *
From layoffs;

-- Creating staging data so that no changes are made to the raw data

CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs.layoffs_staging
SELECT *
FROM layoffs;

Select *
from layoffs_staging;

SELECT COUNT(*)
from layoffs_staging;

-- 1. REMOVING DUPLICATES

-- using row number to indentify duplicates across the data


SELECT *, 
row_number() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, country, funds_raised_millions) as row_num
FROM layoffs_staging;

-- Creating CTE
With check_dupe as
(
SELECT *, 
row_number() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, country, funds_raised_millions) as row_num
FROM layoffs_staging
)
SELECT * FROM check_dupe
WHERE row_num>1;

-- Creating staging table
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *, 
row_number() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, country, funds_raised_millions) as row_num
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2
WHERE row_num>1;

-- Deleting duplicate rows
SET SQL_SAFE_UPDATES = 0;
DELETE 
FROM layoffs_staging2
WHERE row_num>1;
SET SQL_SAFE_UPDATES = 1;


ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- 2. Standardize the Data

-- checking for anomalies in the column company
SELECT distinct company
FROM layoffs_staging2
ORDER BY company;

-- Updating the column company with extra spaced removed
UPDATE layoffs_staging2
SET company = TRIM(company);

-- checking for anomalies in the column industry
SELECT distinct industry
FROM layoffs_staging2
ORDER BY industry;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE '%Crypto%'
ORDER BY industry;

-- standardizing the industry column by fixing anomolies. Changing 'Crypto Currency' and 'CryptoCurrency' to Crypto
UPDATE layoffs_staging2
SET industry='Crypto'
WHERE industry LIKE '%Crypto%'; 

SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY location;

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY country;

SELECT DISTINCT country, TRIM(TRAILING ',' FROM country)
FROM layoffs_staging2
ORDER BY country;

-- Fixing location anomoly. Changing 'United States.' to 'United States'
UPDATE layoffs_staging2
SET country='United States'
WHERE country Like 'United States%'; 

-- Changing the date column from string into date format for future analysis
SELECT date, str_to_date(date,'%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET date = str_to_date(date,'%m/%d/%Y');

SELECT date
FROM layoffs_staging2;

-- Changiing column type to date
ALTER TABLE layoffs_staging2
MODIFY COLUMN date DATE;

-- 3. Null value or blank values

SELECT *
FROM layoffs_staging2
WHERE total_laid_off is null
AND percentage_laid_off is null;

SELECT DISTINCT industry
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE industry is null 
OR industry = '';

SELECT *
FROM layoffs_staging2
WHERE company ='Airbnb';

UPDATE layoffs_staging2
SET industry=null
WHERE industry='';

SELECT *
FROM layoffs_staging2 as t1
JOIN layoffs_staging2 as t2
 ON t1.company=t2.company
 AND t1.location=t2.location
WHERE (t1.industry = '' OR t1.industry is null)
AND t2.industry is not null;

-- Updating blank values where we have information available in the dataset to fill the blank values
UPDATE layoffs_staging2 as t1
JOIN layoffs_staging2 as t2
 ON t1.company=t2.company
SET t1.industry=t2.industry
WHERE t1.industry is null
AND t2.industry is not null;

-- 4. Remove columns and rows that are not needed

SELECT * 
FROM layoffs_staging2
WHERE total_laid_off is NULL 
and percentage_laid_off is null;

DELETE 
FROM layoffs_staging2
WHERE total_laid_off is NULL 
and percentage_laid_off is null;

SELECT *
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
