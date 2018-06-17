using namespace System.Data.SqlClient;
using namespace System.Data.SqlTypes;

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
