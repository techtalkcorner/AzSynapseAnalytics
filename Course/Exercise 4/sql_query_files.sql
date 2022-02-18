-- Query multiple Parquet files using Azure Synapse Analytics Serverless by using wildcards like *
-- Replace the URL with 'https://{data_lake_account_name}.dfs.core.windows.net/{container_name}/{delta_lake_file_path}'
-- Example: https://dlsdataauedev.dfs.core.windows.net/dlsfs/*/*/*/*/SalesLT_SalesOrderHeader_*.parquet
SELECT
    *
FROM
    OPENROWSET(
        BULK 'https://{data_lake_account_name}.dfs.core.windows.net/{container_name}/{delta_lake_file_path}',
        FORMAT = 'PARQUET'
    ) AS [result]


-- Query Delta tables by using the following query
-- The query only needs to point to the folder where the Delta files are located
-- Replace the URL with 'https://{data_lake_account_name}.dfs.core.windows.net/{container_name}/{delta_lake_table_path}/'
-- Example: https://dlsdataauedev.dfs.core.windows.net/dlsfs/Delta/AdventureWorks/Customer/
SELECT *
FROM OPENROWSET(
    BULK 'https://{data_lake_account_name}.dfs.core.windows.net/{container_name}/{delta_lake_table_path}',
    FORMAT = 'delta') as rows;

-- Create database
if not exists (select 1 from sys.databases where name = 'Serverless')
CREATE DATABASE Serverless


-- Create view
-- The query only needs to point to the folder where the Delta files are located
-- Replace the URL with 'https://{data_lake_account_name}.dfs.core.windows.net/{container_name}/{delta_lake_table_path}/'
-- Example: https://dlsdataauedev.dfs.core.windows.net/dlsfs/Delta/AdventureWorks/Customer/
DROP VIEW IF EXISTS dbo.Customer;
GO
create view dbo.Customer as 
SELECT *
FROM OPENROWSET(
    BULK 'https://{data_lake_account_name}.dfs.core.windows.net/{container_name}/{delta_lake_table_path}',
    FORMAT = 'delta') as rows;


