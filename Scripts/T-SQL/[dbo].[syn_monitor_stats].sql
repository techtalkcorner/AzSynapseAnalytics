
-- Return deviation between actual rows and stats rows
SELECT
  objidswithstats.[object_id],
  actualrowcounts.[schema],
  actualrowcounts.logical_table_name,
  statsrowcounts.stats_row_count,
  actualrowcounts.actual_row_count,
  row_count_difference =
                        CASE
                          WHEN actualrowcounts.actual_row_count >= statsrowcounts.stats_row_count THEN actualrowcounts.actual_row_count - statsrowcounts.stats_row_count
                          ELSE statsrowcounts.stats_row_count - actualrowcounts.actual_row_count
                        END,
  percent_deviation_from_actual =
                                 CASE
                                   WHEN actualrowcounts.actual_row_count = 0 THEN statsrowcounts.stats_row_count
                                   WHEN statsrowcounts.stats_row_count = 0 THEN actualrowcounts.actual_row_count
                                   WHEN actualrowcounts.actual_row_count >= statsrowcounts.stats_row_count THEN CONVERT(numeric(18, 0), CONVERT(numeric(18, 2), (actualrowcounts.actual_row_count - statsrowcounts.stats_row_count)) / CONVERT(numeric(18, 2), actualrowcounts.actual_row_count) * 100)
                                   ELSE CONVERT(numeric(18, 0), CONVERT(numeric(18, 2), (statsrowcounts.stats_row_count - actualrowcounts.actual_row_count)) / CONVERT(numeric(18, 2), actualrowcounts.actual_row_count) * 100)
                                 END,
  create_stat_ddl = 'UPDATE STATISTICS [' + actualrowcounts.[schema] + '].[' + actualrowcounts.logical_table_name + ']'
FROM (SELECT DISTINCT
  object_id
FROM sys.stats
WHERE stats_id > 1) objidswithstats
LEFT JOIN (SELECT
  object_id,
  SUM(rows) AS stats_row_count
FROM sys.partitions
GROUP BY object_id) statsrowcounts
  ON objidswithstats.object_id = statsrowcounts.object_id
LEFT JOIN (SELECT
  sm.name [schema],
  tb.name logical_table_name,
  tb.object_id object_id,
  SUM(rg.row_count) actual_row_count
FROM sys.schemas sm
INNER JOIN sys.tables tb
  ON sm.schema_id = tb.schema_id
  AND tb.is_external = 0 -- Remove external tables
INNER JOIN sys.pdw_table_mappings mp
  ON tb.object_id = mp.object_id
INNER JOIN sys.pdw_nodes_tables nt
  ON nt.name = mp.physical_name
INNER JOIN sys.dm_pdw_nodes_db_partition_stats rg
  ON rg.object_id = nt.object_id
  AND rg.pdw_node_id = nt.pdw_node_id
  AND rg.distribution_id = nt.distribution_id
WHERE 1 = 1
GROUP BY sm.name,
         tb.name,
         tb.object_id) actualrowcounts
  ON objidswithstats.object_id = actualrowcounts.object_id