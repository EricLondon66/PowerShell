USE RLL
GO
--Delete data in current RLL tables
TRUNCATE TABLE D1117M; 
TRUNCATE TABLE D1993M; 
TRUNCATE TABLE D256M; 
TRUNCATE TABLE D8500M; 
TRUNCATE TABLE D963M; 
TRUNCATE TABLE D993M;
TRUNCATE TABLE [QM_DEV_TEAM].[QMUL_VERIFIED_AS_NOT_DUPE];
TRUNCATE TABLE [QM_DEV_TEAM].[QMUL_GRADE_CATEGORIES];
TRUNCATE TABLE [QM_DEV_TEAM].[QMUL_FEED_EXCEPTIONS];
TRUNCATE TABLE [QM_DEV_TEAM].[QMUL_ALL_POTENTIAL_POSTS_DUPES];
GO
--Move data from Temp database to RLL database
INSERT INTO [QM_DEV_TEAM].[QMUL_VERIFIED_AS_NOT_DUPE]
SELECT * FROM [RLL_TABLESAFE].[QM_DEV_TEAM].[QMUL_VERIFIED_AS_NOT_DUPE_staging];
GO
INSERT INTO [QM_DEV_TEAM].[QMUL_GRADE_CATEGORIES]
SELECT * FROM [RLL_TABLESAFE].[QM_DEV_TEAM].[QMUL_GRADE_CATEGORIES_staging]
GO
INSERT INTO [QM_DEV_TEAM].[QMUL_FEED_EXCEPTIONS]
SELECT * FROM [RLL_TABLESAFE].[QM_DEV_TEAM].[QMUL_FEED_EXCEPTIONS_staging];
GO
SET IDENTITY_INSERT [QM_DEV_TEAM].[QMUL_ALL_POTENTIAL_POSTS_DUPES] ON
INSERT INTO [QM_DEV_TEAM].[QMUL_ALL_POTENTIAL_POSTS_DUPES]
( [PK]
      ,[EMP_UNIQUE_ID]
      ,[EMPLOYEE_NUMBER]
      ,[HESA_STAFF_ID]
      ,[NI_NO]
      ,[TITLE]
      ,[KNOWN_AS]
      ,[SURNAME]
      ,[INITIALS]
      ,[PREV_SURNAME]
      ,[FIRST_FORNAME]
      ,[OTHER_FORENAMES]
      ,[BIRTH_DATE]
      ,[SEX]
      ,[ORIG_START_DATE]
      ,[START_DATE]
      ,[END_DATE]
      ,[ORIGINAL_EMPLOYEE_NUMBER]
      ,[WORK_TEL_NO]
      ,[EMAIL_ADDRESS]
      ,[LDAP_USERNAME]
      ,[POST_ID]
      ,[POST_SHORT_NAME]
      ,[POST_LONG_NAME]
      ,[POST_HOLDING_HR]
      ,[POST_HOLDING_WK_PER_YR]
      ,[JOB_ID]
      ,[JOB_SHORT_DESC]
      ,[JOB_LONG_DESC]
      ,[JOB_STD_HOURS]
      ,[MAIN_FLAG]
      ,[POST_HOLDING_START_DATE]
      ,[POST_HOLDING_END_DATE]
      ,[POST_HOLDING_PROJECTED_END_DATE]
      ,[L5_ID]
      ,[L5_LONG_DESC]
      ,[L5_SHORT_DESC]
      ,[L4_ID]
      ,[L4_LONG_DESC]
      ,[L4_SHORT_DESC]
      ,[L3_ID]
      ,[L3_LONG_DESC]
      ,[L3_SHORT_DESC]
      ,[L2_ID]
      ,[L2_LONG_DESC]
      ,[L2_SHORT_DESC]
      ,[L1_ID]
      ,[L1_LONG_DESC]
      ,[L1_SHORT_DESC]
      ,[NUMBER_R]
      ,[SHORT_DESC]
      ,[LONG_DESC]
      ,[CATEGORY])

SELECT * FROM [RLL_TABLESAFE].[QM_DEV_TEAM].[QMUL_ALL_POTENTIAL_POSTS_DUPES_staging]
SET IDENTITY_INSERT [QM_DEV_TEAM].[QMUL_ALL_POTENTIAL_POSTS_DUPES] OFF

GO
INSERT INTO [dbo].D1117M
SELECT * FROM [RLL_TABLESAFE].[dbo].[D1117M_staging];
GO
INSERT INTO [dbo].D1993M
SELECT * FROM [RLL_TABLESAFE].[dbo].[D1993M_staging];
GO
INSERT INTO [dbo].D256M
SELECT * FROM [RLL_TABLESAFE].[dbo].[D256M_staging];
GO
INSERT INTO [dbo].D8500M
SELECT * FROM [RLL_TABLESAFE].[dbo].[D8500M_staging];
GO
INSERT INTO [dbo].D963M
SELECT * FROM [RLL_TABLESAFE].[dbo].[D963M_staging];
GO
INSERT INTO [dbo].D993M
SELECT * FROM [RLL_TABLESAFE].[dbo].[D993M_staging];
GO
--Clear session files 
TRUNCATE TABLE D000M; 
TRUNCATE TABLE D002M; 
TRUNCATE TABLE D006M; 
TRUNCATE TABLE D007M 
GO
--Update target database name 
DECLARE @dname nvarchar(255)
 
SET @dname = 'ResourceLink '+db_name()+' Database' 
 
UPDATE D995M 
SET TITLE = @dname
WHERE ID = 'CONTROL';
