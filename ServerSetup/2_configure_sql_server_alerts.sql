/* Create operators first */
 
USE [msdb];
 
 
IF NOT EXISTS (SELECT name FROM msdb.dbo.sysoperators WHERE name = 'All_Operators')
BEGIN
	EXEC msdb.dbo.sp_add_operator @name=N'All_Operators', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'its-dba-team@qmul.ac.uk', 
		@category_name=N'[Uncategorized]';
END
 
IF NOT EXISTS (SELECT name FROM msdb.dbo.sysoperators WHERE name = 'DBA')
BEGIN
	EXEC msdb.dbo.sp_add_operator @name=N'DBA', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'its-dba-team@qmul.ac.uk', 
		@category_name=N'[Uncategorized]';
END
GO

/* Create SQL Server alerts */
USE [msdb]
GO
/****** Object:  Alert [Full database filegroup]    Script Date: 03/06/2014 15:32:11 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Full database filegroup', 
		@message_id=1105, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]';
 
EXEC msdb.dbo.sp_add_notification @alert_name=N'Full database filegroup', @operator_name=N'DBA', @notification_method = 1;
 
 
/****** Object:  Alert [Full database log]    Script Date: 03/06/2014 15:32:26 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Full database log', 
		@message_id=9002, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]';
 
EXEC msdb.dbo.sp_add_notification @alert_name=N'Full database log', @operator_name=N'DBA', @notification_method = 1;
 
 
/****** Object:  Alert [Full tempdb]    Script Date: 03/06/2014 15:32:36 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Full tempdb', 
		@message_id=9002, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=20, 
		@include_event_description_in=1, 
		@database_name=N'tempdb', 
		@category_name=N'[Uncategorized]';
 
EXEC msdb.dbo.sp_add_notification @alert_name=N'Full tempdb', @operator_name=N'DBA', @notification_method = 1;
 
EXEC msdb.dbo.sp_add_alert @name=N'Severity 016: General Error',
@message_id=0,
@severity=16,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 016: General Error', @operator_name=N'DBA', @notification_method = 1;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 017: Insufficient Resources',
@message_id=0,
@severity=17,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 017: Insufficient Resources', @operator_name=N'DBA', @notification_method = 1;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 018: Nonfatal Internal Error Detected',
@message_id=0,
@severity=18,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 018: Nonfatal Internal Error Detected', @operator_name=N'DBA', @notification_method = 1;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 019: SQL Server Error in Resource',
@message_id=0,
@severity=19,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 019: SQL Server Error in Resource', @operator_name=N'DBA', @notification_method = 1;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 020: SQL Server Fatal Error in Current Process',
@message_id=0,
@severity=20,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 020: SQL Server Fatal Error in Current Process', @operator_name=N'DBA', @notification_method = 1;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 021: SQL Server Fatal Error in Database Processes',
@message_id=0,
@severity=21,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 021: SQL Server Fatal Error in Database Processes', @operator_name=N'DBA', @notification_method = 1;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 022: SQL Server Fatal Error Table Integrity Suspect',
@message_id=0,
@severity=22,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 022: SQL Server Fatal Error Table Integrity Suspect', @operator_name=N'DBA', @notification_method = 1;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 023: SQL Server Fatal Error: Database Integrity Suspect',
@message_id=0,
@severity=23,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 023: SQL Server Fatal Error: Database Integrity Suspect', @operator_name=N'DBA', @notification_method = 1;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 024: Hardware Error',
@message_id=0,
@severity=24,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 024: Hardware Error', @operator_name=N'DBA', @notification_method = 1;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 025: System Error',
@message_id=0,
@severity=25,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 025: System Error', @operator_name=N'DBA', @notification_method = 1;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Number 823',
@message_id=823,
@severity=0,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 823', @operator_name=N'DBA', @notification_method = 1;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Number 824',
@message_id=824,
@severity=0,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 824', @operator_name=N'DBA', @notification_method = 1;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Number 825',
@message_id=825,
@severity=0,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 825', @operator_name=N'DBA', @notification_method = 1;
GO