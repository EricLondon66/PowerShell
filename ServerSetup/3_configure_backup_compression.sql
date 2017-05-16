EXEC sys.sp_configure N'backup compression default', N'1'
GO
RECONFIGURE WITH OVERRIDE
GO

/*The following will set the maximum memory for SQL server at 80% of the system memory*/

sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
 
CREATE TABLE #SVer(ID INT,  Name  sysname, Internal_Value INT, VALUE nvarchar(512))
INSERT #SVer EXEC master.dbo.xp_msver
 
DECLARE @val INT  --Container for the value
 
SELECT @val=0.8 *internal_value  --store the system memory value then calculate 80% of that value.
FROM #SVer
WHERE Name = 'PhysicalMemory'
 
SELECT CEILING(CAST (@val AS FLOAT)) -- this will round up the number you get from the above query.
DROP TABLE #SVer   
 
EXEC sp_configure 'max server memory', @val;
GO
 
RECONFIGURE;
GO