SELECT *
FROM CovidDeaths
WHERE continent is not null
ORDER BY 3,4

--SELECT *
--FROM CovidVaccinations
--ORDER BY 3,4

--Selecting data to be used
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2

--Total Cases vs Total Deaths: Likelyhood of dying if covid is contracted in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDeaths
Where location LIKE '%Nigeria%' AND continent is not null
ORDER BY 1,2

--Got the 'Operand data type nvarchar is invalid for divide operator.' error so I altered the table column from nvarchar to float
Alter Table coviddeaths
alter column total_cases float

--Total Cases vs Population: Percentage of the population that has gotten covid
SELECT location, date, population, total_cases, (total_cases/population)*100 as InfectedPopulationPercentage
FROM CovidDeaths
Where location LIKE '%Nigeria%' AND continent is not null
ORDER BY 1,2

--Countries with the highest infection rate compared to infection
SELECT location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 as InfectedPopulationPercentage
FROM CovidDeaths
WHERE continent is not null
--Where location LIKE '%Nigeria%'
GROUP BY location, Population
ORDER BY InfectedPopulationPercentage DESC


--Countries with the highest death count per population
SELECT location, MAX(CAST(total_deaths AS INT)) AS HighestDeathCount
FROM CovidDeaths
WHERE continent is not null
--Where location LIKE '%Nigeria%'
GROUP BY location
ORDER BY HighestDeathCount DESC

--Breakdown by Continent


--Continent with the highest death count
SELECT continent, MAX(CAST(total_deaths AS INT)) AS HighestDeathCount
FROM CovidDeaths
WHERE continent is null
--Where location LIKE '%Nigeria%'
GROUP BY continent
ORDER BY HighestDeathCount DESC

--Global Numbers
SELECT date, 
	   SUM(new_cases) AS TotalCases, 
	   SUM(CAST(new_deaths AS INT)) AS TotalDeaths,
	   CASE
			WHEN SUM(new_cases) = 0 THEN NULL
			ELSE SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 END AS DeathPercentage
FROM CovidDeaths
--Where location LIKE '%Nigeria%'
WHERE continent IS NOT NULL
GROUP BY Date
ORDER BY 1,2;

SELECT SUM(new_cases) AS TotalCases, 
	   SUM(CAST(new_deaths AS INT)) AS TotalDeaths,
	   CASE
			WHEN SUM(new_cases) = 0 THEN NULL
			ELSE SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 END AS DeathPercentage
FROM CovidDeaths
--Where location LIKE '%Nigeria%'
WHERE continent IS NOT NULL
ORDER BY 1,2

--Total Population vs Vaccinations: Arithmetic Overflow error with int data type
/*SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location)
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3*/ 

--Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(decimal(18,2), vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumulativeVaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--USE CTE
WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, CumulativeVaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(decimal(18,2), vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumulativeVaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (CumulativeVaccinations/Population)*100
FROM PopvsVac

--TEMP TABLE
DROP TABLE IF EXISTS #PercentagePopulationVaccinated
CREATE TABLE #PercentagePopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric, 
CumulativeVaccinations numeric
)

INSERT INTO #PercentagePopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(decimal(18,2), vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumulativeVaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (CumulativeVaccinations/Population)*100
FROM #PercentagePopulationVaccinated

--CREATE Views to store data for later visualizations
CREATE VIEW PercentagePopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(decimal(18,2), vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumulativeVaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL