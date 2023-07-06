SELECT *
FROM ProjectPortfolio.dbo.CovidDeaths$
ORDER BY 3,4

--SELECT *
--FROM ProjectPortfolio.dbo.CovidVaccinations$
--ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM ProjectPortfolio.dbo.CovidDeaths$
ORDER BY 1,2

-- Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE location like 'Australia'
ORDER BY 1,2

--SELECT MAX(total_cases), MAX(total_deaths), MAX(total_deaths)/MAX(total_cases)*100 AS DeathPercentage
--FROM ProjectPortfolio.dbo.CovidDeaths

-- Total Cases vs Population
SELECT location, population, MAX(total_cases) AS HighestInfectedCount, MAX(total_cases/population)*100 AS PercentagePopulationInfected
FROM ProjectPortfolio.dbo.CovidDeaths
GROUP BY location, population
ORDER BY PercentagePopulationInfected DESC

-- Countries with highest deaths per location
SELECT location, MAX(total_deaths) AS Total_Death_Cases
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent != location AND continent is not NULL
GROUP BY location
ORDER BY Total_Death_Cases DESC

-- Showing contintents with the highest death count per population
SELECT continent, MAX(total_deaths) AS Total_Death_Cases
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY Total_Death_Cases DESC

SELECT date, SUM(new_cases)
FROM ProjectPortfolio.dbo.CovidDeaths
--WHERE new_cases is not NULL
GROUP BY date
ORDER BY 1,2 

-- Global Numbers
SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent is not NULL AND new_cases != 0
GROUP BY date
ORDER BY 1,2

-- Total Population vs Vaccinations
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS CumulativeVaccinations
FROM ProjectPortfolio.dbo.CovidDeaths death
JOIN ProjectPortfolio.dbo.CovidVaccinations$ vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent is not NULL
ORDER BY 2,3

-- CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, CumulativeVaccinations)
as
(SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS CumulativeVaccinations
FROM ProjectPortfolio.dbo.CovidDeaths death
JOIN ProjectPortfolio.dbo.CovidVaccinations$ vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent is not NULL
--ORDER BY 2,3
)
SELECT *, (CumulativeVaccinations/Population)*100 AS VaccinationRatio
FROM PopvsVac

-- Temp Table
DROP Table IF EXISTS #PercentagePopulationVaccinated 
CREATE Table #PercentagePopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
CumulativeVaccinations numeric
)

INSERT INTO #PercentagePopulationVaccinated
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS CumulativeVaccinations
FROM ProjectPortfolio.dbo.CovidDeaths death
JOIN ProjectPortfolio.dbo.CovidVaccinations$ vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent is not NULL

SELECT *, (CumulativeVaccinations/Population)*100 AS VaccinationPercentage
FROM #PercentagePopulationVaccinated

-- Creating View to store data for later visualisations
CREATE VIEW PercentagePopulationVaccinated AS
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS CumulativeVaccinations
FROM ProjectPortfolio.dbo.CovidDeaths death
JOIN ProjectPortfolio.dbo.CovidVaccinations$ vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent is not NULL
--ORDER BY 2,3

SELECT *
FROM PercentagePopulationVaccinated