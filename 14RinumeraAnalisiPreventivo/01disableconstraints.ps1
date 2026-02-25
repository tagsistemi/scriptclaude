# Script per disabilitare i vincoli
$sqlServer = "192.168.0.3\sql2008"
$username = "sa"
$password = "stream"

# Definizione delle tabelle interessate
$tables = @(
    "IM_JobQuotasNotes",
    "IM_JobsDetails",
    "IM_JobQuotasDetails",
    "IM_JobQuotasDetailsVCL",
    "IM_JobQuotasSections",
    "IM_JobQuotasSummByCompType",
    "IM_JobQuotasSummary",
    "IM_JobQuotations",
    "IM_JobQuotasTaxSummary",
    "IM_JobQuotasWorkingStep",
    "IM_JobQuotasSummByCompTypeByWorkingStep",
    "IM_JobQuotasDocuments",
    "IM_JobQuotasAddCharges",
    "IM_TmpJobQuotasDetails",
    "IM_TmpJobQuotasTree"
)

# Definizione dei database
$databases = @(
   "gpxnetclone",
   "furmanetclone",
   "vedbondifeclone"
)

function Execute-SqlQuery {
   param (
       [string]$server,
       [string]$query,
       [string]$username,
       [string]$password
   )
   
   $connection = New-Object System.Data.SqlClient.SqlConnection
   $connection.ConnectionString = "Server=$server;User Id=$username;Password=$password;"
   
   $command = New-Object System.Data.SqlClient.SqlCommand
   $command.Connection = $connection
   $command.CommandText = $query
   $command.CommandTimeout = 300
   
   try {
       $connection.Open()
       Write-Host "Executing query..."
       $result = $command.ExecuteNonQuery()
       Write-Host "Query executed."
   }
   catch {
       Write-Host "Error executing query: $_" -ForegroundColor Red
       throw $_
   }
   finally {
       $connection.Close()
   }
}

function Disable-Constraints {
   param (
       $database
   )

   Write-Host "Processing database: $database"

   $sqlScript = @"
USE [$database];
BEGIN TRY
   -- Trova e disabilita tutti i vincoli FK relativi alle tabelle specificate
   DECLARE @sql nvarchar(max) = ''
   SELECT @sql = @sql + 
       'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id))
       + '.' + QUOTENAME(OBJECT_NAME(parent_object_id)) 
       + ' NOCHECK CONSTRAINT '
       + QUOTENAME(name) + ';' + CHAR(13)
   FROM sys.foreign_keys
   WHERE OBJECT_NAME(parent_object_id) IN 
       ('$(($tables -join ''','''))')
   OR OBJECT_NAME(referenced_object_id) IN 
       ('$(($tables -join ''','''))')

   EXEC sp_executesql @sql
   PRINT 'Successfully disabled constraints for $database'
END TRY
BEGIN CATCH
   DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
   RAISERROR (@ErrorMessage, 16, 1)
END CATCH
"@

   try {
       Execute-SqlQuery -server $sqlServer -query $sqlScript -username $username -password $password
       Write-Host "Successfully disabled constraints for $database" -ForegroundColor Green
   }
   catch {
       Write-Host "Error disabling constraints for $database : $_" -ForegroundColor Red
   }
}

# Main execution
Write-Host "Starting constraint disable process..."

foreach ($database in $databases) {
   Disable-Constraints -database $database
}

Write-Host "Constraint disable process completed."