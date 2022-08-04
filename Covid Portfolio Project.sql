--이용하려는 data 선택
Select *
From PortfolioProject..CovidVaccinations
order by 3,4


--테이블에서 원하는 행만 출력
Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 3,4



--total_cases 와 total_deaths 비교 ~> DeathPercentage(치사율)표현
--이것을 통해 대한민국의 2020-12-31 치사율은 1.4%인것을 알 수 있다.
Select location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where location like '%korea%'
order by 1,2


--Total cases(감염률) 와 Population (인구수) 비교
Select location as 지역, date as 날짜, Population as 인구수,total_cases as 당일확진자,  (total_cases/population)*100 as 치사율
From PortfolioProject..CovidDeaths
where location like '%korea%'
order by 1,2



--국가별 인구수별 최고 확진자수
Select location as 지역, population as 인구수, max(total_cases) as 당일_최대확진자,  max((total_cases/population))*100 as 치사율
From PortfolioProject..CovidDeaths
group by location, population
order by population Desc

--국가별 총 사망자수
--국가를 기준으로 묶고 총 사망자수 최대값을 총_사망자수라 지칭했으니 order by는 정렬하는 속성, order by 총_사망자수로 해야한다
--cast(값 as 형변환) : 값을 원하는 형태로 변환 (total_deaths는 nvarchar형태임으로 int로 형변환)
--continent(대륙) 속성값에 조건으로 is not null을 걸어주면 대륙별 확진자는 나오지 않는다
select location as 국가, max(cast(total_deaths as int)) as 총_사망자수
from PortfolioProject..CovidDeaths
where continent is not null
group by location
order by 총_사망자수 desc


--사망자수가 가장 많은 대륙
select continent, max(cast(total_deaths as int)) as 총_사망자수
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by 총_사망자수 desc

--
--신규확진자(new_cases)는 float 실수라 합계연사자 사용이 가능하지만
--신규사망자(new_deaths)는 nvarchar 가변문자열이라 형태를 변형하여야 연산가능 ~> cast함수(형태변환)이용
Select date, sum(new_cases) as 신규확진자, sum(cast(new_deaths as int)) as 신규사망자, 
sum(cast(new_deaths as int))/sum(new_cases)*100 as 사망률
From PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1,2



--코로나 사망자, 코로나 백신접종자 DB join해보기
--해당 DB 뒤에 약자를 붙이면 해당 DB를 짧게 적어 사용할 수 있다.
select *
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date



--join후 대륙발 신규 백신접종자수
--1.location과 date를 기준으로 join ~> continent null값 제거 ~> 중복값이 나와 distinct로 중복제거
--2.총 백신접종자 합계 ~> 국가별 집계를 위해 pratition by location
--신규접종자는 가변문자열이기에 int형으로 변경 convert(원하는 자료형, 속성)
--3. 알파벳순으로 정렬위해 order by 2,3
--4. partition by 국가  order by 국가, 날짜로 국가별~날짜별 신규접종자, 누적접종자 수를 카운트 할 수 있다.


select distinct dea.continent as 대륙, dea.location as 국가, dea.date as 날짜, population as 인구수, vac.new_vaccinations as 신규백신접종자,
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rolling
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and vac.new_vaccinations is not null
order by 2,3



--cte사용

with PopvsVac (continet, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent as 대륙, dea.location as 국가, dea.date as 날짜, population as 인구수, vac.new_vaccinations as 신규백신접종자,
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
select *, (RollingPeopleVaccinated/population)*100
from PopvsVac



--임시 테이블

Drop table if exists #percentPopulationVaccinated
create table #percentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
New_Vaccination numeric,
RollingPeopleVaccinated numeric
)
insert into #percentPopulationVaccinated
select dea.continent as 대륙, dea.location as 국가, dea.date as 날짜, population as 인구수, vac.new_vaccinations as 신규백신접종자,
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date

select *, (RollingPeopleVaccinated/population)*100
from #percentPopulationVaccinated


-- 시각화를 위해 데이터를 저장할 뷰
create view percentPopulationVaccinated as
select dea.continent , dea.location , dea.date, population , vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

 
select *
from percentPopulationVaccinated
