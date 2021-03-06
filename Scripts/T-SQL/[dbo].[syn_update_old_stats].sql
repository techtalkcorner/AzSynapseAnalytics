CREATE PROCEDURE [dbo].[syn_update_old_stats] 
(
@number_of_days INT, -- default value 7 days
@execute BIT -- Default value (don't execute)
)
AS
--==========================================================================================
-- Author:      David Alzamendi (https://techtalkcorner.com)
-- Create date: 13/06/2020
-- Description: Stored Procedure to update statistics of tables 
-- Example: 
--		exec [dbo].[syn_update_old_stats] @number_of_days = 7, @execute= 0
-- Parameters:
-- @number_of_days: number of days to update old statistics
-- @execute: 1 (Execute). 0 (Print script)
-- ==========================================================================================
BEGIN
    -- Define variables
    DECLARE @incremental INT = 1
    DECLARE @total       INT = 0
    DECLARE @statement   NVARCHAR(4000) = N''
    
	-- Define default number of days old
    IF @number_of_days IS NULL
    BEGIN
		SET @number_of_days = -7;
    END;
	ELSE 	 -- Define negative number number of days old
	BEGIN
		SET @number_of_days = - @number_of_days;
	END

    -- Defines default value for execution
    IF @execute IS NULL
    BEGIN
      SET @execute = 0;
    END;

    -- Drop temporal tables if exist
    IF Object_id('tempdb..#old_stats_ddl') IS NOT NULL
    BEGIN;
      DROP TABLE #old_stats_ddl;
    
    END;
    IF Object_id('tempdb..#old_stats_data') IS NOT NULL
    BEGIN;
      DROP TABLE #old_stats_data;
    
    END;

    -- Populate temporal tables
    -- Capture old statistics
    CREATE TABLE #old_stats_ddl with
                 (
                              distribution = round_robin ,
                              location = user_db
                 )
                AS
					SELECT DISTINCT sm.[name] AS [schema_name],
									tb.[name] AS [table_name],
									update_stats_ddl = 'UPDATE STATISTICS [' + sm.[name] + '].[' + tb.[name] +']',
									[stats_date] = Stats_date(st.[object_id],st.[stats_id])
					FROM            sys.objects ob
					JOIN            sys.stats st
					ON              ob.[object_id] = st.[object_id]
					JOIN            sys.stats_columns sc
					ON              st.[stats_id] = sc.[stats_id]
					AND             st.[object_id] = sc.[object_id]
					JOIN            sys.columns co
					ON              sc.[column_id] = co.[column_id]
					AND             sc.[object_id] = co.[object_id]
					JOIN            sys.types ty
					ON              co.[user_type_id] = ty.[user_type_id]
					JOIN            sys.tables tb
					ON              co.[object_id] = tb.[object_id]
					AND             tb.is_external=0 -- Remove external tables
					JOIN            sys.schemas sm
					ON              tb.[schema_id] = sm.[schema_id]
					WHERE           (st.[user_created] = 1 OR auto_created = 1)
					AND             Stats_date(st.[object_id],st.[stats_id]) < Dateadd(d,@number_of_days,Cast(Getdate() AS DATE));


    -- Create DDL table for the statements
    CREATE TABLE #old_stats_data
                 (
                              statement_number INT,
                              update_stats_ddl  VARCHAR(2000)
                 ) ;
    
    WITH cte AS
    (
             SELECT   [stats_date] = Min([stats_date]),
                      update_stats_ddl
             FROM     #old_stats_ddl
             GROUP BY update_stats_ddl -- multiple stats per table, group by minimum date
    ) 
    INSERT INTO #old_stats_data
                (
                            statement_number,
                            update_stats_ddl
                )
    SELECT   statement_number = Row_number() OVER( ORDER BY [stats_date] ASC),
             update_stats_ddl
    FROM     cte
	
	-- Total number of stats
    SET @total =   (SELECT Count(*) FROM   #old_stats_ddl)
	print 'Number of statistics to update: '+ cast(@total as varchar)

	IF (@total > 0)
	BEGIN
		-- Start loop
		IF (@execute = 0) -- Print statement
		BEGIN
		  WHILE @incremental <= @total
		  BEGIN
			SET @statement=
			(SELECT TOP 1
						  update_stats_ddl
				   FROM   #old_stats_data
				   WHERE  statement_number = @incremental);
			IF @statement IS NOT NULL
			BEGIN
			  PRINT @statement
			END
			SET @incremental+=1;
		  END
		END
		ELSE -- Execute statement 
		BEGIN
		  WHILE @incremental <= @total
		  BEGIN
			SET @statement=
			(
				   SELECT TOP 1
						  update_stats_ddl
				   FROM   #old_stats_data
				   WHERE  statement_number = @incremental);
			IF @statement IS NOT NULL
			BEGIN
			  PRINT format(getdate(),'yyyy-MM-dd HH:mm:ss')+ ' - Start: ' + @statement 
			  EXEC sp_executesql @statement; -- Update old stats
			  PRINT format(getdate(),'yyyy-MM-dd HH:mm:ss')+ ' - End: ' + @statement 
			END
			SET @incremental += 1;
		  END
		END
	END

    -- Drop temporal tables if exist
    IF Object_id('tempdb..#old_stats_ddl') IS NOT NULL
    BEGIN;
      DROP TABLE #old_stats_ddl;
    END;

    IF Object_id('tempdb..#old_stats_data') IS NOT NULL
    BEGIN;
      DROP TABLE #old_stats_data;
    END;

END