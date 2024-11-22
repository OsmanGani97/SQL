use covid19
go
--Insert Sample Data on Table--
insert into Zones values
(1,'Red'),(2,'Yellow'),(3,'Green')
go
select*from Zones
go
insert into Areas values
(1,'Mirpur',1),(2,'Motijheel',2)
go
select*from Areas
go
insert into Dailyrecords values
('2022-01-01',1,55,23,11),('2022-01-02',2,23,4,2)
go
select*from Dailyrecords
go
insert into zonetracks values
(1,1,'2022-01-01'),(1,2,'2022-01-02'),(1,1,'2022-01-03')
go
select*from zonetracks
go
--Inner Join--
select Dr.[Date],a.areaid,a.areaname,z.zoneid,zt.zonetrackid,zt.lastupdate,z.zonename,
a.currentzone,Dr.newcase,Dr.deathcase,Dr.curedcase
from Areas a
inner join zonetracks zt on a.areaid=zt.areaid
inner join Zones z on z.zoneid=zt.zoneid
inner join Areas a1 on a1.currentzone=z.zoneid
inner join Dailyrecords Dr on a1.areaid=Dr.areaid
GO
-- Test View---
select * from todaysrecords
go
select * from vCaseRecord
go
--Test Procedures---

EXEC spInsertZone 4, 'Blue'
GO
SELECT * FROM Zones
GO
EXEC spUpdateZone @ZoneID = 3 , @ZoneName = 'White'
GO 
SELECT * FROM Zones
GO
EXEC spUpdateZone @ZoneID = 3 , @ZoneName = 'Red'
GO 
SELECT * FROM Zones
GO
EXEC spDeleteZone 4
GO
SELECT * FROM Zones
GO

Exec spInsertAreas 3,'Mohammadpur',1
Exec spInsertAreas 4, 'Uttara',1
-- 
Exec spInsertAreas 5, 'Gulshan',2
Exec spInsertAreas 6, 'Dhanmondi',2

Exec spInsertAreas 7,'Sutrapur',3
Exec spInsertAreas 8,'Nobabgonj',3
Exec spInsertAreas 9, 'Keranigonj',3
Exec spInsertAreas 10,'Narayangonj',3
GO
--
SELECT * FROM Areas
go
EXEC spUpdateAreas @AreaID = 10, @AreaName = 'Khilkhet', @CurrentZone = 3
GO
SELECT * FROM Areas
GO
Exec spDeleteArea 10
GO
SELECT * FROM Areas
GO
EXEC spInsertDailyRecords '2022-01-06',1,123,23,63
EXEC spInsertDailyRecords '2022-01-06',2,65,20,25
DECLARE @d DATE = GETDATE()
EXEC spInsertDailyRecords @d,2,65,20,25
GO
SELECT * FROM Dailyrecords
GO
Exec spUpdateDailyRecords '2022-01-06', 1,120,6,9
GO
SELECT * FROM DailyRecords
GO
Exec spDeleteFromDailyRecords 1, '2022-01-06'
GO
SELECT * FROM DailyRecords
go
--Test Function--
SELECT * FROM fnCaseRecord(1, '2022-01-01', GETDATE())
GO
select * from fnAreaSummary(1)
go
select * from areainzone(3)
go
select dbo.totalCases(1)
go
select dbo.totalDeaths(1)
go
--Test Trigger

EXEC spInsertDailyRecords '2022-01-09',2,65,20,25
go
/*
 * --Queries added
 */

--1 Join Inner 
SELECT a.areaname, z.zonename, zt.lastupdate 'upadeon'
FROM Areas a
INNER JOIN zones z on a.currentzone= z.zoneid
INNER JOIN zonetracks zt ON zt.zoneid = z.zoneid
GO
--2 red zone
SELECT a.areaname, z.zonename, zt.lastupdate 'upadeon'
FROM Areas a
INNER JOIN zones z on a.currentzone= z.zoneid
INNER JOIN zonetracks zt ON zt.zoneid = z.zoneid
WHERE z.zonename = 'Red'
-- 3 Not in red
SELECT a.areaname, z.zonename, zt.lastupdate 'upadeon'
FROM Areas a
INNER JOIN zones z on a.currentzone= z.zoneid
INNER JOIN zonetracks zt ON zt.zoneid = z.zoneid
WHERE z.zonename <> 'Red'
--4 left outer
SELECT   a.areaname, z.zonename, zt.lastupdate as 'Updatedate'
FROM  Areas a 
LEFT OUTER JOIN Zones  z ON a.currentzone = z.zoneid 
LEFT OUTER JOIN zonetracks zt ON a.areaid = zt.areaid 
--5 smae with CTE
WITH zoneandtrack
AS
(
SELECT z.zoneid, zt.areaid, z.zonename, zt.lastupdate
	FROM zones z 
	INNER JOIN zonetracks zt ON zt.zoneid = z.zoneid
)
SELECT a.areaname, zat.zonename, zat.lastupdate as 'upadteon'
FROM Areas a
LEFT OUTER JOIN zoneandtrack zat ON zat.areaid = a.areaid
GO
--6 Left outer not matched
SELECT   a.areaname, z.zonename
FROM  Areas a 
LEFT OUTER JOIN Zones  z ON a.currentzone = z.zoneid 
LEFT OUTER JOIN zonetracks zt ON a.areaid = zt.areaid 
WHERE zt.zonetrackid IS NULL
--7 same with sub-query
SELECT   a.areaname, z.zonename
FROM  Areas a 
INNER JOIN Zones z ON a.currentzone = z.zoneid
WHERE a.areaid NOT IN (SELECT areaid FROM zonetracks)
GO
--8 aggregate
SELECT z.zonename, COUNT(a.areaid) 'totalarea', ISNULL(SUM(dr.deathcase), 0) 'totaldeath' , ISNULL(SUM(dr.curedcase), 0) 'totalcured'
FROM Zones z 
INNER JOIN Areas a ON z.zoneid = a.currentzone
LEFT OUTER JOIN Dailyrecords dr ON a.areaid = dr.areaid
GROUP BY z.zonename
GO
--9 aggregate + having
SELECT z.zonename, COUNT(a.areaid) 'totalarea', ISNULL(SUM(dr.deathcase), 0) 'totaldeath' , ISNULL(SUM(dr.curedcase), 0) 'totalcured'
FROM Zones z 
INNER JOIN Areas a ON z.zoneid = a.currentzone
LEFT OUTER JOIN Dailyrecords dr ON a.areaid = dr.areaid
GROUP BY z.zonename
HAVING z.zonename = 'Red'
--10 windowing function
SELECT z.zonename, COUNT(a.areaid) OVER(ORDER BY z.zoneid) 'totalarea', 
SUM(ISNULL(dr.deathcase, 0)) OVER(ORDER BY z.zoneid) 'totaldeath' , 
SUM(ISNULL(dr.curedcase, 0)) OVER(ORDER BY z.zoneid)  'totalcured',
ROW_NUMBER() OVER(ORDER BY z.zoneid) 'rownum',
RANK() OVER(ORDER BY z.zoneid) 'rank',
DENSE_RANK() OVER(ORDER BY z.zoneid) 'denserank',
NTILE(3) OVER(ORDER BY z.zoneid) 'ntile(3)'
FROM Zones z 
INNER JOIN Areas a ON z.zoneid = a.currentzone
LEFT OUTER JOIN Dailyrecords dr ON a.areaid = dr.areaid
GO
--11 select case
SELECT z.zonename, COUNT(a.areaid) 'totalarea',
SUM(
	CASE 
		WHEN dr.deathcase is null THEN 0
		ELSE dr.deathcase
	END
)'totaldeath' , 
SUM(
	CASE 
		WHEN dr.curedcase is null THEN 0
		ELSE dr.curedcase
	END
) 'totalcured'
FROM Zones z 
INNER JOIN Areas a ON z.zoneid = a.currentzone
LEFT OUTER JOIN Dailyrecords dr ON a.areaid = dr.areaid
GROUP BY z.zonename
GO
