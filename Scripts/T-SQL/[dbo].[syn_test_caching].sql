-- Master database
-- Enable Caching at the Database Level
select is_result_set_caching_on, * from sys.databases
where name = 'DataWarehouse'

ALTER DATABASE [DataWarehouse] 
SET RESULT_SET_CACHING ON;

-- In user database
create table [dbo].[ResultSetCachingSample]
(
City varchar(255)
)

Insert into [dbo].[ResultSetCachingSample]
select 'Brisbane'

-- Supported
select * from [dbo].[ResultSetCachingSample]
OPTION (LABEL = 'Result Set Caching Sample')


SELECT result_cache_hit, *
FROM sys.dm_pdw_exec_requests
where [label] ='Result Set Caching Sample'
order by request_id desc


SELECT  location_type, *
FROM sys.dm_pdw_request_steps 
where request_Id = ''
order by request_id desc

-- Disable for the session
SET RESULT_SET_CACHING OFF;

select * from [dbo].[ResultSetCachingSample]
OPTION (LABEL = 'Result Set Caching Sample')

SELECT result_cache_hit, *
FROM sys.dm_pdw_exec_requests
where [label] ='Result Set Caching Sample'
order by request_id desc

SELECT  location_type, *
FROM sys.dm_pdw_request_steps 
where request_Id = ''
order by request_id desc

SET RESULT_SET_CACHING ON;


-- Not supported
-- Inserting row
Insert into [dbo].[ResultSetCachingSample]
select 'Melbourne'

select * from [dbo].[ResultSetCachingSample]
OPTION (LABEL = 'Result Set Caching Sample')

SELECT result_cache_hit, *
FROM sys.dm_pdw_exec_requests
where [label] ='Result Set Caching Sample'
order by request_id desc

SELECT  location_type, *
FROM sys.dm_pdw_request_steps 
where request_Id = 'QID52965'
order by request_id desc


-- Adding getdate()
select *,getdate() from [dbo].[ResultSetCachingSample]
OPTION (LABEL = 'Result Set Caching Sample')

SELECT result_cache_hit, *
FROM sys.dm_pdw_exec_requests
where [label] ='Result Set Caching Sample'
order by request_id desc


SELECT  location_type, *
FROM sys.dm_pdw_request_steps 
where request_Id = 'QID53025'
order by request_id desc


-- Drop result cache results
DBCC DROPRESULTSETCACHE 

SELECT result_cache_hit
FROM sys.dm_pdw_exec_requests
WHERE request_id = 'QID58286'