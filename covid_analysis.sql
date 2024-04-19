/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

USE covid_analysis;

SELECT * 
FROM covid_data.`covid-data-reduced`
WHERE continent<>'';

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location,date,total_cases,total_deaths,ROUND((total_deaths/total_cases*100),2) as Death_Percentage
FROM covid_data.`covid-data-reduced`
WHERE continent<>''
AND location='india';


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT location,date,population,total_cases,ROUND((total_cases/population*100),2) as PercentPopulationInfected
FROM covid_data.`covid-data-reduced`
WHERE continent<>''
AND location='india';

-- Countries with Highest Infection Rate compared to Population

SELECT location,population,SUM(new_cases) as cases,ROUND(SUM(new_cases)/population*100,2) as PercentPopulationInfected
FROM covid_data.`covid-data-reduced`
WHERE continent<>''
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Countries with Highest Death Count

SELECT location,population,SUM(new_deaths) as TotalDeathCount
FROM covid_data.`covid-data-reduced`
WHERE continent<>''
GROUP BY location, population
ORDER BY TotalDeathCount DESC;

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

SELECT continent,SUM(new_deaths) as TotalDeathCount
FROM covid_data.`covid-data-reduced`
WHERE continent<>''
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- Death Percentage Global
SELECT SUM(new_cases) as total_cases,SUM(new_deaths) as total_deaths,SUM(new_deaths)/SUM(new_cases)*100 as DeathPercent
FROM covid_data.`covid-data-reduced`
WHERE continent<>'';

SELECT location,SUM(new_cases) as total_cases,SUM(new_deaths) as total_deaths,SUM(new_deaths)/SUM(new_cases)*100 as DeathPercent
FROM covid_data.`covid-data-reduced`
WHERE continent<>''
GROUP BY location
ORDER BY DeathPercent DESC;

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccinated
FROM covid_data.`covid-data-reduced`as dea
JOIN covid_data.`covid_vaccine` as vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent<>'';

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac(continent,location,date,population,new_vaccinations,RollingVaccinated)
as
(
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccinated
FROM covid_data.`covid-data-reduced`as dea
JOIN covid_data.`covid_vaccine` as vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent<>''
)
SELECT *,(RollingVaccinated/population)*100 as VaccinatedPercent
FROM PopvsVac;

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE if exists PercentPopulationVaccinated; 
CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccincations text,
RollingVaccinated text
);
Insert into PercentPopulationVaccinated
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccinated
FROM covid_data.`covid-data-reduced`as dea
JOIN covid_data.`covid_vaccine` as vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent<>'';

SELECT *,(RollingVaccinated/population)*100 as VaccinePercent
FROM PercentPopulationVaccinated
-- WHERE location ='india'
;

-- Creating View to store data for later visualizations

-- Top 10 countries with highest cases

CREATE VIEW TopTenCountriesByCases as
SELECT location,SUM(new_cases) as no_of_cases
FROM covid_data.`covid-data-reduced`
WHERE continent<>''
GROUP BY location
ORDER BY no_of_cases DESC
LIMIT 10;

SELECT * FROM TopTenCountriesByCases;

-- Top 10 countries with highest deaths

CREATE VIEW TopTenCountriesByDeaths as
SELECT location,SUM(new_deaths) as no_of_deaths
FROM covid_data.`covid-data-reduced`
WHERE continent<>''
GROUP BY location
ORDER BY no_of_deaths DESC
LIMIT 10;

-- Death Rate by continent

CREATE VIEW DeathRateByContinent as
SELECT continent,SUM(new_cases) as TotalCases,SUM(new_deaths) as TotalDeathCount,ROUND(SUM(new_deaths)/SUM(new_cases)*100,2) as DeathRate
FROM covid_data.`covid-data-reduced`
WHERE continent<>''
GROUP BY continent
ORDER BY DeathRate DESC;
