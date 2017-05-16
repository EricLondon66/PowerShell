
Declare @dt varchar(50)
Set @dt = '$(dt)'



EXEC sys.sp_addextendedproperty @name=N'Refresh_date', @value=@dt
GO

select count(*) as Refresh_input from sys.extended_properties 
where name='Refresh_date'
Go