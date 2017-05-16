/*Configure database mail*/

EXEC sp_configure 'Show Advanced Options', 1;
GO
RECONFIGURE;
GO
sp_configure 'Database Mail XPs',1;
GO
RECONFIGURE;
GO
-- Setup and configure database mail
 
-------------------------------------------------------------
--  Database Mail Simple Configuration Template.
--
--  This template creates a Database Mail profile, an SMTP account and 
--  associates the account to the profile.
--  The template does not grant access to the new profile for
--  any database principals.  Use msdb.dbo.sysmail_add_principalprofile
--  to grant access to the new profile for users who are not
--  members of sysadmin.
-------------------------------------------------------------
 
DECLARE 
 
	@profile_name sysname,
        @account_name sysname,
        @SMTP_servername sysname,
        @email_address NVARCHAR(128),
	@display_name NVARCHAR(128);
 
	-- Profile name. Replace with the name for your profile
        SET @profile_name = 'its-dba-team';
 
	-- Account information. Replace with the information for your account.
 
	SET @account_name = 'its-dba-team';
	SET @SMTP_servername = 'smtp.qmul.ac.uk';
	SET @email_address = 'its-dba-team@qmul.ac.uk';
        SELECT @display_name = @@SERVERNAME;
 
BEGIN
 
	-- Verify the specified account and profile do not already exist.
	IF EXISTS (SELECT * FROM msdb.dbo.sysmail_profile WHERE name = @profile_name)
	BEGIN
	  RAISERROR('The specified Database Mail profile (its-dba-team) already exists.', 16, 1);
	  GOTO done;
	END;
 
	IF EXISTS (SELECT * FROM msdb.dbo.sysmail_account WHERE name = @account_name )
	BEGIN
	 RAISERROR('The specified Database Mail account (its-dba-team) already exists.', 16, 1) ;
	 GOTO done;
	END;
 
	-- Start a transaction before adding the account and the profile
	BEGIN TRANSACTION ;
 
	DECLARE @rv INT;
 
	-- Add the account
	EXECUTE @rv=msdb.dbo.sysmail_add_account_sp
		@account_name = @account_name,
		@email_address = @email_address,
		@display_name = @display_name,
		@mailserver_name = @SMTP_servername;
 
	IF @rv<>0
	BEGIN
		RAISERROR('Failed to create the specified Database Mail account (its-dba-team).', 16, 1) ;
		GOTO done;
	END
 
	-- Add the profile
	EXECUTE @rv=msdb.dbo.sysmail_add_profile_sp
		@profile_name = @profile_name ;
 
	IF @rv<>0
	BEGIN
		RAISERROR('Failed to create the specified Database Mail profile (its-dba-team).', 16, 1);
		ROLLBACK TRANSACTION;
		GOTO done;
	END;
 
	-- Associate the account with the profile.
	EXECUTE @rv=msdb.dbo.sysmail_add_profileaccount_sp
		@profile_name = @profile_name,
		@account_name = @account_name,
		@sequence_number = 1 ;
 
	IF @rv<>0
	BEGIN
		RAISERROR('Failed to associate the speficied profile with the specified account (its-dba-team).', 16, 1) ;
		ROLLBACK TRANSACTION;
		GOTO done;
	END;
 
	-- Grant public access as default to the profile
	EXECUTE @rv=msdb.dbo.sysmail_add_principalprofile_sp
		@principal_name = 'public',
		@profile_name = @profile_name,
		@is_default = 1 ;
 
	IF @rv<>0
	BEGIN
		RAISERROR('Failed to grant public access to the speficied profile (its-dba-team).', 16, 1) ;
		ROLLBACK TRANSACTION;
		GOTO done;
	END;
 
	COMMIT TRANSACTION;
 
	done:
 
END;
GO 
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder=1
GO
EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', 
    N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'UseDatabaseMail', 
    N'REG_DWORD', 1
GO
EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', 
    N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'DatabaseMailProfile', 
    N'REG_SZ', N'its-dba-team'
GO