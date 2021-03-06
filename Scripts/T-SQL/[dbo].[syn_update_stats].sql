CREATE PROCEDURE [dbo].[syn_update_stats] 
(
@percent_deviation_from_actual INT, -- Default Value 10
@execute BIT -- Default value (don't execute)
)   
AS
--==========================================================================================
-- Author:      David Alzamendi (https://techtalkcorner.com)
-- Create date: 13/06/2020
-- Description: Stored Procedure to update statistics of tables based on variance agains actual number of rows
-- Example: 
--			exec [dbo].[syn_update_stats] @percent_deviation_from_actual = 10, @execute= 0
-- Parameters:
-- @percent_deviation_from_actual:  percent variation from actual number of rows
-- @execute: 1 (Execute). 0 (Print script)
-- ==========================================================================================
BEGIN
    -- Define variables
    DECLARE @incremental INT = 1
    DECLARE @total       INT = 0
    DECLARE @statement   NVARCHAR(4000) = N''
		
	-- Define default number of days old
    IF @percent_deviation_from_actual IS NULL
    BEGIN
		SET @percent_deviation_from_actual = 10;
    END;

    -- Defines default value for execution
    IF @execute IS NULL
    BEGIN
      SET @execute = 0;
    END;

    -- Drop temporal tables if exist
    IF object_id('tempdb..#stats_ddl') IS NOT NULL
    BEGIN;
      DROP TABLE #stats_ddl;
    
    END;

    if object_id('tempdb..#stats_data') IS NOT NULL
    BEGIN;
      DROP TABLE #stats_data;
    END;

	-- Populate temporal tables
    -- Capture statistics
    CREATE TABLE #stats_ddl WITH
                 (
                              distribution = round_robin ,
                              location = user_db
                 )
                 AS
					SELECT    objidswithstats.[object_id],
							  actualrowcounts.[schema],
							  actualrowcounts.logical_table_name,
							  statsrowcounts.stats_row_count,
							  actualrowcounts.actual_row_count,
							  row_count_difference =
							  CASE
										WHEN actualrowcounts.actual_row_count >= statsrowcounts.stats_row_count THEN actualrowcounts.actual_row_count - statsrowcounts.stats_row_count
										ELSE statsrowcounts.stats_row_count                                                                           - actualrowcounts.actual_row_count
							  END,
							  percent_deviation_from_actual =
							  CASE
										WHEN actualrowcounts.actual_row_count = 0 THEN statsrowcounts.stats_row_count
										WHEN statsrowcounts.stats_row_count = 0 THEN actualrowcounts.actual_row_count
										WHEN actualrowcounts.actual_row_count >= statsrowcounts.stats_row_count THEN CONVERT(numeric(18, 0), CONVERT(numeric(18, 2), (actualrowcounts.actual_row_count - statsrowcounts.stats_row_count)) / CONVERT(numeric(18, 2), actualrowcounts.actual_row_count) * 100)
										ELSE CONVERT(                                                                        numeric(18, 0), CONVERT(numeric(18, 2), (statsrowcounts.stats_row_count   - actualrowcounts.actual_row_count)) / CONVERT(numeric(18, 2), actualrowcounts.actual_row_count) * 100)
							  END,
							  create_stat_ddl = 'UPDATE STATISTICS [' + actualrowcounts.[schema] +'].['+ actualrowcounts.logical_table_name+']'
					FROM      (
											  SELECT DISTINCT object_id
											  FROM            sys.stats
											  WHERE           stats_id > 1 ) objidswithstats
					LEFT JOIN
							  (
									   SELECT   object_id,
												sum(rows) AS stats_row_count
									   FROM     sys.partitions
									   GROUP BY object_id ) statsrowcounts
					ON        objidswithstats.object_id = statsrowcounts.object_id
					LEFT JOIN
							  (
										 SELECT     sm.name [schema] ,
													tb.name           logical_table_name ,
													tb.object_id      object_id ,
													sum(rg.row_count) actual_row_count
										 FROM       sys.schemas sm
										 INNER JOIN sys.tables tb
										 ON         sm.schema_id = tb.schema_id
										 AND        tb.is_external=0 -- Remove external tables
										 INNER JOIN sys.pdw_table_mappings mp
										 ON         tb.object_id = mp.object_id
										 INNER JOIN sys.pdw_nodes_tables nt
										 ON         nt.name = mp.physical_name
										 INNER JOIN sys.dm_pdw_nodes_db_partition_stats rg
										 ON         rg.object_id = nt.object_id
										 AND        rg.pdw_node_id = nt.pdw_node_id
										 AND        rg.distribution_id = nt.distribution_id
										 WHERE      1 = 1
										 GROUP BY   sm.name,
													tb.name,
													tb.object_id ) actualrowcounts
					ON        objidswithstats.object_id = actualrowcounts.object_id
					WHERE
							  CASE
										WHEN actualrowcounts.actual_row_count = 0 THEN statsrowcounts.stats_row_count
										WHEN statsrowcounts.stats_row_count = 0 THEN actualrowcounts.actual_row_count
										WHEN actualrowcounts.actual_row_count >= statsrowcounts.stats_row_count THEN CONVERT(numeric(18, 0), CONVERT(numeric(18, 2), (actualrowcounts.actual_row_count - statsrowcounts.stats_row_count)) / CONVERT(numeric(18, 2), actualrowcounts.actual_row_count) * 100)
										ELSE CONVERT(                                                                        numeric(18, 0), CONVERT(numeric(18, 2), (statsrowcounts.stats_row_count   - actualrowcounts.actual_row_count)) / CONVERT(numeric(18, 2), actualrowcounts.actual_row_count) * 100)
							  END >= @percent_deviation_from_actual
   


    -- Create DDL table for the statements
    CREATE TABLE #stats_data
                 (
                              sno             int,
                              create_stat_ddl varchar(2000)
                 )
    INSERT INTO #stats_data
                (
                            sno,
                            create_stat_ddl
                )
    SELECT   sno = row_number() OVER(ORDER BY percent_deviation_from_actual DESC),
             create_stat_ddl
    FROM     #stats_ddl

	-- Total number of stats
    SET @total =   (SELECT Count(*) FROM   #stats_data)
	print 'Number of statistics to update: '+ cast(@total as varchar)

	IF (@total > 0)
	BEGIN
		IF (@Execute = 0)  -- Print statement
		BEGIN
		  WHILE @incremental <= @total
		  BEGIN
			SET @statement=
			(SELECT TOP 1
						  create_stat_ddl
				   FROM   #stats_data
				   WHERE  sno = @incremental);
			if @statement IS NOT NULL
			BEGIN
			  PRINT @statement
			END
			SET @incremental+=1;
		  END
		END
		ELSE  -- Execute statement 
		BEGIN
		  WHILE @incremental <= @total
		  BEGIN
			SET @statement=
			(
				   SELECT TOP 1
						  create_stat_ddl
				   FROM   #stats_data
				   WHERE  sno = @incremental);
			if @statement IS NOT NULL
			BEGIN
			  PRINT format(getdate(),'yyyy-MM-dd HH:mm:ss')+ ' - Start: ' + @statement 
			  EXEC sp_executesql @statement; -- Update stats
			  PRINT format(getdate(),'yyyy-MM-dd HH:mm:ss')+ ' - End: ' + @statement 
			END
			SET @incremental += 1;
		  END
		END
	END

	-- Drop temporal tables if exist
    IF object_id('tempdb..#stats_ddl') IS NOT NULL
    BEGIN;
      DROP TABLE #stats_ddl;
    END;

    if object_id('tempdb..#stats_data') IS NOT NULL
    BEGIN;
      DROP TABLE #stats_data;
    END;

END