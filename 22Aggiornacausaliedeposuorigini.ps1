<#
.SYNOPSIS
    Updates InvRsn and StoragePhase values in MA_InventoryEntries tables in multiple databases.
.DESCRIPTION
    This script connects to the database server and executes a series of UPDATE statements
    to modify inventory reason codes and storage phase values in the MA_InventoryEntries table on multiple databases.
    Compatible with SQL Server 2008.
.NOTES
    Author: System Administrator
    Date: June 11, 2025
#>

# SQL Server connection parameters
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"
$connectionTimeout = 30
$queryTimeout = 120

# Prepare SQL connection string with SQL authentication (without specifying database)
$connectionString = "Server=$ServerInstance;User Id=$SqlUsername;Password=$SqlPassword;Connect Timeout=$connectionTimeout"

try {
    Write-Host "Connecting to SQL Server 2008 on server '$ServerInstance'..."
    
    # Create SQL connection
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    Write-Host "Connection established successfully."
    
    # Define each update statement separately with fully qualified database references
    $updateStatements = @(
        # Updates for FurmanteClone database - InvRsn updates
        "UPDATE [furmanetclone].[dbo].[MA_InventoryEntries] SET InvRsn = 'MOV-DEPF' WHERE InvRsn = 'MOV-DEP'",
        "UPDATE [furmanetclone].[dbo].[MA_InventoryEntries] SET InvRsn = 'ACQ-FRM' WHERE InvRsn = 'ACQ'",
        "UPDATE [furmanetclone].[dbo].[MA_InventoryEntries] SET InvRsn = 'AMEUR-F' WHERE InvRsn = 'AMEUR'",
        "UPDATE [furmanetclone].[dbo].[MA_InventoryEntries] SET InvRsn = 'CPEUR-F' WHERE InvRsn = 'CPEUR'",
        "UPDATE [furmanetclone].[dbo].[MA_InventoryEntries] SET InvRsn = 'MID-Frm' WHERE InvRsn = 'MID'",
        "UPDATE [furmanetclone].[dbo].[MA_InventoryEntries] SET InvRsn = 'MOV-LIBF' WHERE InvRsn = 'MOV-LIB'",
        "UPDATE [furmanetclone].[dbo].[MA_InventoryEntries] SET InvRsn = 'MUD-FRM' WHERE InvRsn = 'MUD'",
        
        # Updates for VedBondifeClone database - InvRsn updates
        "UPDATE [vedbondifeclone].[dbo].[MA_InventoryEntries] SET InvRsn = 'MOV-DEPB' WHERE InvRsn = 'MOV-DEP'",
        "UPDATE [vedbondifeclone].[dbo].[MA_InventoryEntries] SET InvRsn = 'VEN-O-B' WHERE InvRsn = 'VEN-O'",
        
        # New updates for FurmanteClone database - StoragePhase updates
        "UPDATE [furmanetclone].[dbo].[MA_InventoryEntries] SET StoragePhase1 = '01FRM' WHERE StoragePhase1 = '01'",
        "UPDATE [furmanetclone].[dbo].[MA_InventoryEntries] SET StoragePhase2 = '01FRM' WHERE StoragePhase2 = '01'",
        "UPDATE [furmanetclone].[dbo].[MA_InventoryEntries] SET StoragePhase1 = '01MPFRM' WHERE StoragePhase1 = '01MP'",
        "UPDATE [furmanetclone].[dbo].[MA_InventoryEntries] SET StoragePhase2 = '01MPFRM' WHERE StoragePhase2 = '01MP'",
        
        # New updates for VedBondifeClone database - StoragePhase updates
        "UPDATE [vedbondifeclone].[dbo].[MA_InventoryEntries] SET StoragePhase1 = 'COLLBDF' WHERE StoragePhase1 = 'COLLAUDI'",
        "UPDATE [vedbondifeclone].[dbo].[MA_InventoryEntries] SET StoragePhase2 = 'COLLBDF' WHERE StoragePhase2 = 'COLLAUDI'",
        "UPDATE [vedbondifeclone].[dbo].[MA_InventoryEntries] SET StoragePhase1 = 'SANNABDF' WHERE StoragePhase1 = 'SANNAZZA'",
        "UPDATE [vedbondifeclone].[dbo].[MA_InventoryEntries] SET StoragePhase2 = 'SANNABDF' WHERE StoragePhase2 = 'SANNAZZA'"
    )
    
    # Execute each update statement
    foreach ($sql in $updateStatements) {
        $command = New-Object System.Data.SqlClient.SqlCommand($sql, $connection)
        $command.CommandTimeout = $queryTimeout
        
        Write-Host "Executing: $sql"
        $rowsAffected = $command.ExecuteNonQuery()
        Write-Host "  - $rowsAffected rows affected"
    }
    
    # Close the connection
    $connection.Close()
    Write-Host "Database connection closed."
    Write-Host "Script execution completed successfully."
}
catch {
    Write-Error "An error occurred during script execution:"
    Write-Error $_.Exception.Message
    
    if ($connection -ne $null -and $connection.State -eq 'Open') {
        $connection.Close()
        Write-Host "Database connection closed after error."
    }
    
    exit 1
}