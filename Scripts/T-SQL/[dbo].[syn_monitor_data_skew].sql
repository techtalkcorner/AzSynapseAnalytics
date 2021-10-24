with DataDistribution as (
SELECT
 s.name as [Schema Name]
,t.name as  [Table Name]
,tp.[distribution_policy_desc] as  [Distribution Policy Name]
,sum([row_count]) as  [Table Row Count]
,max(row_count) as  [Max Distribution Row Count]
,min(row_count) as  [Min Distribution Row Count]
,avg(row_count) as  [Avg Distribution Row Count]
from
    sys.schemas s
JOIN sys.tables t
    ON s.[schema_id] = t.[schema_id]
JOIN sys.pdw_table_distribution_properties tp
    ON t.[object_id] = tp.[object_id]
JOIN sys.pdw_table_mappings tm
    ON t.[object_id] = tm.[object_id]
JOIN sys.pdw_nodes_tables nt
    ON tm.[physical_name] = nt.[name]
JOIN sys.dm_pdw_nodes pn
    ON  nt.[pdw_node_id] = pn.[pdw_node_id]
JOIN sys.pdw_distributions di
    ON  nt.[distribution_id] = di.[distribution_id]
JOIN sys.dm_pdw_nodes_db_partition_stats nps
 ON nt.[object_id] = nps.[object_id]
    AND nt.[pdw_node_id] = nps.[pdw_node_id]
    AND nt.[distribution_id] = nps.[distribution_id]
where tp.[distribution_policy_desc] ='HASH'
 -- AND t.name = @tbl
GROUP BY
  s.name
,t.name
,tp.[distribution_policy_desc]
)
Select [Schema Name],
	   [Table Name],
	   [Distribution Policy Name],
	   [Table Row Count],
	   [Max Distribution Row Count],
	   [Min Distribution Row Count],
	   [Avg Distribution Row Count],
	   CASE WHEN [Table Row Count] = 0 then -1
	   else abs([Max Distribution Row Count] * 1.0 - [Min Distribution Row Count]*1.0) / [Max Distribution Row Count] * 100.0
	   END  as [Table Skew Percent]
FROM DataDistribution