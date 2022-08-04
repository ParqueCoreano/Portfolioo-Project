--�̿��Ϸ��� data ����
Select *
From PortfolioProject..CovidVaccinations
order by 3,4


--���̺��� ���ϴ� �ุ ���
Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 3,4



--total_cases �� total_deaths �� ~> DeathPercentage(ġ����)ǥ��
--�̰��� ���� ���ѹα��� 2020-12-31 ġ������ 1.4%�ΰ��� �� �� �ִ�.
Select location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where location like '%korea%'
order by 1,2


--Total cases(������) �� Population (�α���) ��
Select location as ����, date as ��¥, Population as �α���,total_cases as ����Ȯ����,  (total_cases/population)*100 as ġ����
From PortfolioProject..CovidDeaths
where location like '%korea%'
order by 1,2



--������ �α����� �ְ� Ȯ���ڼ�
Select location as ����, population as �α���, max(total_cases) as ����_�ִ�Ȯ����,  max((total_cases/population))*100 as ġ����
From PortfolioProject..CovidDeaths
group by location, population
order by population Desc

--������ �� ����ڼ�
--������ �������� ���� �� ����ڼ� �ִ밪�� ��_����ڼ��� ��Ī������ order by�� �����ϴ� �Ӽ�, order by ��_����ڼ��� �ؾ��Ѵ�
--cast(�� as ����ȯ) : ���� ���ϴ� ���·� ��ȯ (total_deaths�� nvarchar���������� int�� ����ȯ)
--continent(���) �Ӽ����� �������� is not null�� �ɾ��ָ� ����� Ȯ���ڴ� ������ �ʴ´�
select location as ����, max(cast(total_deaths as int)) as ��_����ڼ�
from PortfolioProject..CovidDeaths
where continent is not null
group by location
order by ��_����ڼ� desc


--����ڼ��� ���� ���� ���
select continent, max(cast(total_deaths as int)) as ��_����ڼ�
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by ��_����ڼ� desc

--
--�ű�Ȯ����(new_cases)�� float �Ǽ��� �հ迬���� ����� ����������
--�űԻ����(new_deaths)�� nvarchar �������ڿ��̶� ���¸� �����Ͽ��� ���갡�� ~> cast�Լ�(���º�ȯ)�̿�
Select date, sum(new_cases) as �ű�Ȯ����, sum(cast(new_deaths as int)) as �űԻ����, 
sum(cast(new_deaths as int))/sum(new_cases)*100 as �����
From PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1,2



--�ڷγ� �����, �ڷγ� ��������� DB join�غ���
--�ش� DB �ڿ� ���ڸ� ���̸� �ش� DB�� ª�� ���� ����� �� �ִ�.
select *
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date



--join�� ����� �ű� ��������ڼ�
--1.location�� date�� �������� join ~> continent null�� ���� ~> �ߺ����� ���� distinct�� �ߺ�����
--2.�� ��������� �հ� ~> ������ ���踦 ���� pratition by location
--�ű������ڴ� �������ڿ��̱⿡ int������ ���� convert(���ϴ� �ڷ���, �Ӽ�)
--3. ���ĺ������� �������� order by 2,3
--4. partition by ����  order by ����, ��¥�� ������~��¥�� �ű�������, ���������� ���� ī��Ʈ �� �� �ִ�.


select distinct dea.continent as ���, dea.location as ����, dea.date as ��¥, population as �α���, vac.new_vaccinations as �űԹ��������,
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rolling
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and vac.new_vaccinations is not null
order by 2,3



--cte���

with PopvsVac (continet, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent as ���, dea.location as ����, dea.date as ��¥, population as �α���, vac.new_vaccinations as �űԹ��������,
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
select *, (RollingPeopleVaccinated/population)*100
from PopvsVac



--�ӽ� ���̺�

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
select dea.continent as ���, dea.location as ����, dea.date as ��¥, population as �α���, vac.new_vaccinations as �űԹ��������,
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date

select *, (RollingPeopleVaccinated/population)*100
from #percentPopulationVaccinated


-- �ð�ȭ�� ���� �����͸� ������ ��
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
