USE PortfolioProject
SELECT * FROM covidDeaths
SELECT * FROM covidVaccinations

--Number of global covid-19 cases and deaths
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covidDeaths
ORDER BY 1, 2

--Death percentage compared to total cases in Indonesia
SELECT location, date, total_cases, total_deaths, CONCAT((total_deaths/total_cases)*100, '%') as DeathPercentage
FROM covidDeaths
WHERE location like '%indonesia%'
ORDER BY 1, 2

-- Total cases percentage compared to population in Indonesia
SELECT location, date, total_cases, population, CONCAT((total_cases/population)*100, '%') as totalCasesPercentage
FROM covidDeaths
WHERE location like '%indonesia%'
ORDER BY 1, 2

-- Countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, CONCAT(MAX((total_cases/population)*100), '%') as HighestInfectionRate
FROM covidDeaths
GROUP BY location, population
ORDER BY 4 DESC

--Highest death count in each country
SELECT location, MAX(CAST(total_deaths AS INT)) as TotalDeathCount
FROM covidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC


--Total death count per continent
SELECT location, MAX(CAST(total_deaths AS INT)) as TotalDeathCount
FROM covidDeaths
WHERE continent IS NULL and location not in ('World', 'European Union', 'International')
GROUP BY location
ORDER BY 2 DESC

--Continents with the highest death count per population
SELECT continent, population, MAX(CAST(total_deaths AS INT)) as TotalDeathCount
FROM covidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, population
ORDER BY 1,3 DESC


--GLOBAL DATA
--presentage per day
SELECT date, SUM(new_cases) as [Cases per day], SUM(CAST(new_deaths as INT)) as [Death per day], CONCAT((SUM(CAST(new_deaths as INT))/SUM(new_cases))*100, '%') as DeathPercentage
FROM covidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1

--total presentage
SELECT SUM(new_cases) as [Cases per day], SUM(CAST(new_deaths as INT)) as [Death per day], CONCAT((SUM(CAST(new_deaths as INT))/SUM(new_cases))*100, '%') as DeathPercentage
FROM covidDeaths
WHERE continent IS NOT NULL

--using VACCINATION DATA
--Vaccinated percentage compared to population (overall presentage)
SELECT cd.continent, cd.location, cd.population, MAX(CAST(cv.people_vaccinated AS BIGINT)) as vaccinated, CONCAT((MAX(CAST(cv.people_vaccinated AS BIGINT))/ cd.population)*100, '%') as VaccinatedPercentage
FROM covidVaccinations cv
	JOIN covidDeaths cd
	on cv.date = cd.date and cv.location = cd.location
WHERE cd.continent IS NOT NULL
GROUP BY cd.continent, cd.location, cd.population 
ORDER BY 1,2,3

--Progress of the vaccination process for each country
WITH PopAndVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(CONVERT(int, cv.new_vaccinations)) 
	OVER (Partition by cd.location ORDER BY cd.location, cd.date) as RollingPeopleVaccinated
FROM covidVaccinations cv
	JOIN covidDeaths cd
	on cv.date = cd.date and cv.location = cd.location
WHERE cd.continent IS NOT NULL
GROUP BY cd.continent, cd.location, cd.population, cd.date, cv.new_vaccinations
)
SELECT *, (RollingPeopleVaccinated/Population)*100 as [RPV Percentage] FROM PopAndVac
WHERE (RollingPeopleVaccinated/Population)*100 is not null
order by 1,2


--TEMP TABLE for progress of the vaccination process for each country
DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinated numeric,
	rollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(CONVERT(bigint, cv.new_vaccinations)) 
	OVER (Partition by cd.location ORDER BY cd.location, cd.date) as RollingPeopleVaccinated
FROM covidVaccinations cv
	JOIN covidDeaths cd
	on cv.date = cd.date and cv.location = cd.location

SELECT *, (rollingPeopleVaccinated/population)*100 as PercentPopulationVaccinated
FROM #PercentPopulationVaccinated

--VIEW
--create view to store data for later visualization
CREATE VIEW PresentPopulationVaccinated_view as
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(CONVERT(bigint, cv.new_vaccinations)) 
	OVER (Partition by cd.location ORDER BY cd.location, cd.date) as RollingPeopleVaccinated
FROM covidVaccinations cv
	JOIN covidDeaths cd
	on cv.date = cd.date and cv.location = cd.location
WHERE cd.continent is not null

