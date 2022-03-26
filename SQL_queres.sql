Select *
From portfolio_project..covid_deaths
order by 3,4

Select *
From portfolio_project..covid_vaccinations
order by 3,4


-- looking at the data
Select location, date, total_cases, new_cases, total_deaths, population
From portfolio_project..covid_deaths
order by 1,2


-- looking at the Total Cases vs Total Deaths
-- shows the likelihood of dying if you get covid in Canada
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
From portfolio_project..covid_deaths
where location like '%Canada%'
order by 1,2


-- looking at the Population vs Total Deaths
-- shows the percentage of population who got covid in Canada
Select location, date, total_deaths, population, (total_deaths/population)*100 as covid_percentage
From portfolio_project..covid_deaths
where location like '%canada%'
order by 1,2


-- looking at the countries with the highest infection rate compared to population
Select location, population, MAX(total_cases) as highest_infection, MAX((total_cases/population))*100 as covid_percentage
From portfolio_project..covid_deaths
-- where location like '%canada%'
group by location, population
order by covid_percentage desc


Select location, population, date, MAX(total_cases) as highest_infection, MAX((total_cases/population))*100 as covid_percentage
From portfolio_project..covid_deaths
-- where location like '%canada%'
group by location, population, date
order by covid_percentage desc


-- looking at the countries with the highest death count
Select location, MAX(cast(total_deaths as int)) as death_count
From portfolio_project..covid_deaths
-- where location like '%canada%'
where continent is not null   -- added this b/c its showing continents and etc
group by location
order by death_count desc


-- looking at continents
Select location, MAX(cast(total_deaths as int)) as death_count
From portfolio_project..covid_deaths
where continent is null
and location not in ('World', 'European Union', 'International', 'Upper middle income', 'High income', 'Lower middle income', 'Low income') -- added this to remove the 7 groups of income
group by location
order by death_count desc


-- looking at continents with the highest deaths
Select continent, MAX(cast(total_deaths as int)) as death_count
From portfolio_project..covid_deaths
where continent is not null
group by continent
order by death_count desc


-- Global numbers
Select date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as death_rate
From portfolio_project..covid_deaths
where continent is not null
group by date
order by 1,2

Select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as death_rate
From portfolio_project..covid_deaths
where continent is not null
order by 1,2




-- combining the two data
-- find the rolling vaccinated count by location with partition
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as rolling_vaccinated
From portfolio_project..covid_deaths dea
join portfolio_project..covid_vaccinations vac
	On dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- Use CT
with PopvsVac (continent, location, date, population, new_vaccinations, rolling_vaccinated) as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as rolling_vaccinated
From portfolio_project..covid_deaths dea
join portfolio_project..covid_vaccinations vac
	On dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
)

Select *, (rolling_vaccinated/population)*100 as rolling_vaccine_rate
from PopvsVac


-- Use temp tables
drop table if exists #percent_pop_vaccinated 
create table #percent_pop_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
data datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccinated numeric
)

insert into #percent_pop_vaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as rolling_vaccinated
From portfolio_project..covid_deaths dea
join portfolio_project..covid_vaccinations vac
	On dea.location = vac.location and dea.date = vac.date
where dea.continent is not null

Select *, (rolling_vaccinated/population)*100 as rolling_vaccine_rate
from #percent_pop_vaccinated



-- create views
create view global_death_count as
Select location, MAX(cast(total_deaths as int)) as death_count
From portfolio_project..covid_deaths
where continent is null
and location not like '%income%' -- added this to remove the three groups of income
group by location

select * from global_death_count