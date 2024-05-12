SELECT * FROM CovidDeaths
ORDER BY 3, 5

SELECT * FROM CovidVaccinations
ORDER BY 3, 5

--SELECT data that we are going to use
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1, 2

--Total cases vs Total deaths
SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100, 3) AS DeathRates
FROM CovidDeaths
WHERE total_cases IS NOT NULL
AND total_deaths IS NOT NULL
ORDER BY 1,2

--Total cases vs Population
SELECT location, date, total_cases, population, ROUND((total_cases/population)*100, 3) AS InfectionRates
FROM CovidDeaths
WHERE total_cases IS NOT NULL
AND population IS NOT NULL
ORDER BY 1,2


--Countries with highest infection rates
SELECT location, population, MAX(CAST(total_cases AS INT)) AS HighestCaseCount, 
MAX(ROUND((total_cases/population)*100, 3)) AS InfectionRates
FROM CovidDeaths
WHERE total_cases IS NOT NULL
AND population IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC,1

--Death count over Population
--CAST(column_name AS data_type): cast a column to specific type
SELECT location, population, MAX(CAST(total_deaths AS int)) AS HighestDeathCount, MAX(ROUND((total_deaths/population)*100, 2)) AS DeathRateOverPopulation
FROM CovidDeaths
WHERE continent IS NOT NULL --When continent is NULL, location is the entire continent, we dont want to incl that
GROUP BY location, population
ORDER BY 4 DESC, 1

--Death count over Continent
SELECT location, MAX(CAST(total_deaths AS int)) AS HighestDeathCount, MAX(population) AS Population, MAX(ROUND((total_deaths/population)*100, 2)) AS DeathRateOverPopulation
FROM CovidDeaths
WHERE continent IS NULL
AND location NOT LIKE '%income'
GROUP BY location
ORDER BY 3 DESC, 1

--Global data by dates
SELECT date, SUM(new_cases), SUM(new_deaths)
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date

--Total population vs Vaccinations per day 
--Window function: aggregate_func OVER ()*
--(): Bring aggregated values to every row
--(PARTITION BY column_name): Calculate and bring aggregated values sectioned by column_names
--(PARTITION BY column_name1 ORDER BY column_name2): Calculate rolling count (sum) by order of column_name2
--Window function: RANK() OVER (ORDER BY column_name): Create a ranking system ordered by column_name
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingCount
FROM CovidDeaths dea
JOIN CovidVaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND vac.new_vaccinations IS NOT NULL
ORDER BY 2, 3

--CTE for selecting RollingCount to calculate vaccinated rate
WITH CTE_RollingCount (continent, location, date, population, new_vaccinations, RollingCount)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingCount
FROM CovidDeaths dea
JOIN CovidVaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND vac.new_vaccinations IS NOT NULL
)
SELECT *, ROUND((RollingCount/population)*100, 2) AS VaccinatedRate FROM CTE_RollingCount
ORDER BY 2, 3

--VIEWS: for later visualization

CREATE VIEW VaccinationRate AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingCount
FROM CovidDeaths dea
JOIN CovidVaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND vac.new_vaccinations IS NOT NULL

SELECT * FROM VaccinationRate ORDER BY 2, 3