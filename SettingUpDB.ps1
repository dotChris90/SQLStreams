using namespace System.Data.SqlClient;
using namespace System.Data.SqlTypes;

# Do this in SSMS or Powershell SQL Console

#CREATE DATABASE Archive
#ON
#PRIMARY ( NAME = Arch1,
#    FILENAME = 'c:\data\archdat1.mdf'),
#FILEGROUP FileStreamGroup1 CONTAINS FILESTREAM( NAME = Arch3,
#    FILENAME = 'c:\data\filestream1')
#LOG ON  ( NAME = Archlog1,
#    FILENAME = 'c:\data\archlog1.ldf')
#GO

# CREATE TABLE Archive.dbo.Records
#(
#	[Id] [uniqueidentifier] ROWGUIDCOL NOT NULL UNIQUE,
#	[SerialNumber] INTEGER UNIQUE,
#	[Chart] VARBINARY(MAX) FILESTREAM NULL
#)
#GO

# ensure there is a connection
$connStr = 'server=L0146\SQLEXPRESS;Trusted_Connection=True'
$connection = [SqlConnection]::new()
$connection.ConnectionString = $connStr
$connection.Open()

# execute command to get location for file handle
$cmd = [SqlCommand]::new()
$cmd.Connection = $connection
$cmd.CommandText = "SELECT Chart.PathName() FROM Archive.dbo.Records WHERE SerialNumber = 3";
$obj = $cmd.ExecuteScalar()

[string]$filePath = $obj

# okay time to start a transaction (special MS SQL language for comlplex programming like style)
$transaction = $connection.BeginTransaction("mainTranaction")
$cmd.Transaction = $transaction
$cmd.CommandText = "SELECT GET_FILESTREAM_TRANSACTION_CONTEXT()" # get the file handle
$obj = $cmd.ExecuteScalar()
[byte[]]$txContext  = $obj


$someData = @(0);

for ($idx = 0; $idx -lt 100; $idx++)
{
    for ($jdx = 0; $jdx -lt 100; $jdx++)
    {
        $someData += [double]$idx * $jdx;
    }
}

# lets start to bring in series :D
$formater = [System.Runtime.Serialization.Formatters.Binary.BinaryFormatter]::new();
$memoryStream = [System.IO.MemoryStream]::new();
$formater.Serialize($memoryStream,$someData); #now my data is in this memorystream


$sqlFileStream.Write($memoryStream.ToArray(),0,$memoryStream.ToArray().Length);

$sqlFileStream.Close();

$cmd.Transaction.Commit();
