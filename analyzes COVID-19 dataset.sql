-- SQL Portfolio Project for Data Analyst
-- Author: Ali Jahangir
-- Date: 2024-10-07
-- This script analyzes COVID-19 data, calculating key statistics such as death rates, infection rates, and vaccination coverage for various countries.

-- Death Rate (% of deaths among total cases) for countries with 'Iran' in the name
SELECT 
    location,
    date, 
    population,
    new_cases,
    total_deaths,
    total_cases,
    ROUND(CASE 
            WHEN ISNULL(total_cases, 0) = 0 THEN 0
            ELSE (CAST(ISNULL(total_deaths, 0) AS FLOAT) / CAST(ISNULL(total_cases, 0) AS FLOAT)) * 100
        END, 3) AS DeathPercentageOfCases
FROM CovidDeaths
WHERE location LIKE '%Iran%' AND continent IS NOT NULL
ORDER BY location, date DESC;

-- Infection Rate (% of population with COVID-19) for countries with 'Iran' in the name
SELECT 
    location,
    date, 
    total_cases,
    population,
    ROUND(CASE 
            WHEN ISNULL(population, 0) = 0 THEN 0
            ELSE (CAST(ISNULL(total_cases, 0) AS FLOAT) / CAST(ISNULL(population, 0) AS FLOAT)) * 100
        END, 3) AS CasesPercentageOfPopulation
FROM CovidDeaths
WHERE location LIKE '%Iran%' AND continent IS NOT NULL
ORDER BY location, date DESC;

-- Max reported deaths, cases, and average death/infection rates for each country
SELECT 
    location,
    TRY_CAST(ISNULL(population, 0) AS BIGINT) AS population,
    MAX(CAST(ISNULL(total_deaths, 0) AS BIGINT)) AS TotalDeaths,
    MAX(CAST(ISNULL(total_cases, 0) AS BIGINT)) AS TotalCases,
    ROUND(AVG(CASE 
            WHEN ISNULL(total_cases, 0) = 0 THEN 0
            ELSE (CAST(ISNULL(total_deaths, 0) AS FLOAT) / CAST(ISNULL(total_cases, 0) AS FLOAT)) * 100
        END), 3) AS AverageDeathPercentageOfCases,
    ROUND(AVG(CASE 
            WHEN ISNULL(TRY_CAST(population AS BIGINT), 0) = 0 THEN 0
            ELSE (CAST(ISNULL(total_cases, 0) AS FLOAT) / TRY_CAST(ISNULL(population, 0) AS BIGINT)) * 100
        END), 3) AS AverageCasesPercentageOfPopulation
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeaths DESC, TotalCases DESC;

-- Max death rate and infection rate for each country
SELECT 
    location,
    population,
    MAX(CAST(ISNULL(total_deaths, 0) AS BIGINT)) AS TotalDeaths,
    MAX(CAST(ISNULL(total_cases, 0) AS BIGINT)) AS TotalCases,
    ROUND(MAX(CASE 
            WHEN ISNULL(total_cases, 0) = 0 THEN 0
            ELSE (CAST(ISNULL(total_deaths, 0) AS FLOAT) / CAST(ISNULL(total_cases, 0) AS FLOAT)) * 100
        END), 3) AS MaxDeathPercentageOfCases,
    ROUND(MAX(CASE 
            WHEN ISNULL(total_cases, 0) = 0 THEN 0
            ELSE (CAST(ISNULL(total_cases, 0) AS FLOAT) / CAST(ISNULL(population, 0) AS FLOAT)) * 100
        END), 3) AS MaxCasesPercentageOfPopulation
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalCases DESC, TotalDeaths DESC;

-- Countries with highest COVID-19 infection rate compared to population
SELECT 
    location,
    CAST(population AS BIGINT) AS population,
    MAX(CAST(ISNULL(total_cases, 0) AS FLOAT)) AS MaxCases,
    ROUND(MAX(CASE 
            WHEN CAST(population AS BIGINT) > 0 THEN 
                (CAST(ISNULL(total_cases, 0) AS FLOAT) / CAST(population AS FLOAT)) * 100
            ELSE 0
        END), 3) AS MAXPopulationInflation
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY MAXPopulationInflation DESC;

-- Max reported deaths for countries without a continent (likely data errors or missing info)
SELECT 
    location, 
    MAX(CAST(ISNULL(total_deaths, 0) AS BIGINT)) AS MaxDeaths
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY MaxDeaths DESC;

-- Total new cases, new deaths, and death rate for countries without a continent
SELECT 
    date, 
    SUM(CAST(ISNULL(new_cases, 0) AS INT)) AS TotalNewCases,
    SUM(CAST(ISNULL(new_deaths, 0) AS INT)) AS TotalNewDeaths,
    CASE 
        WHEN SUM(CAST(ISNULL(new_cases, 0) AS FLOAT)) = 0 THEN 0
        ELSE ROUND((SUM(CAST(ISNULL(new_deaths, 0) AS FLOAT)) / SUM(CAST(ISNULL(new_cases, 0) AS BIGINT)) * 100), 2)
    END AS NewDeathsPercentOfNewCases
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY date
ORDER BY NewDeathsPercentOfNewCases DESC;

-- Vaccination progress by country
WITH PopvsVac (continent, location, date, population, new_vaccinations, TotalVaccination) AS (
    SELECT 
        cd.continent,
        cd.location,
        cd.date,
        cd.population,
        cv.new_vaccinations,
        SUM(CAST(cv.new_vaccinations AS FLOAT)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS TotalVaccination
    FROM CovidDeaths cd
    JOIN CovidVaccination cv ON cd.location = cv.location AND cd.date = cv.date
    WHERE cd.continent IS NOT NULL
)
SELECT *, ROUND((CAST(TotalVaccination AS FLOAT) / CAST(population AS FLOAT)) * 100, 2) AS PercentOfVaccinPop
FROM PopvsVac;

-- Using temp table to store percentage of population vaccinated
DROP TABLE IF EXISTS #PercentOfPopulationVaccination;
CREATE TABLE #PercentOfPopulationVaccination (
    continent NVARCHAR(50), 
    location NVARCHAR(50), 
    date DATETIME, 
    population NUMERIC, 
    new_vaccinations NUMERIC, 
    TotalVaccination NUMERIC
);
INSERT INTO #PercentOfPopulationVaccination
SELECT 
    cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(CAST(cv.new_vaccinations AS FLOAT)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS TotalVaccination
FROM CovidDeaths cd
JOIN CovidVaccination cv ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL;

SELECT *, ROUND((CAST(TotalVaccination AS FLOAT) / CAST(population AS FLOAT)) * 100, 2) AS PercentOfVaccinPop
FROM #PercentOfPopulationVaccination;

-- Creating a view to store data for later visualizations
CREATE VIEW PopulationVaccinated AS 
SELECT 
    cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(CAST(cv.new_vaccinations AS FLOAT)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS TotalVaccination
FROM CovidDeaths cd
JOIN CovidVaccination cv ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL;

SELECT * FROM PopulationVaccinated;
