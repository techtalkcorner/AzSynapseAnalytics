-- This query returns the state for the tables that are replicated
SELECT [SchemaName] = schema_name(schema_id)
	,[TableName] = t.name
	,[CompleteTableName] = QUOTENAME(schema_name(schema_id)) + '.' + QUOTENAME(t.name)
	,[State] = STATE
	,[SyncDMLStatement] = CASE
		WHEN STATE = 'NotReady'
			THEN 'select top 1 * from ' + schema_name(schema_id) + '.' + t.name
		END
FROM sys.tables t
JOIN sys.pdw_replicated_table_cache_state c ON c.object_id = t.object_id
JOIN sys.pdw_table_distribution_properties p ON p.object_id = t.object_id
WHERE distribution_policy = 3
ORDER BY t.name