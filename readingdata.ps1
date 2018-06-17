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

$sqlFileStream = [SqlFileStream]::new($filePath,$txContext,[System.IO.FileAccess]::ReadWrite);

[byte[]]$buffer = [byte[]]::new(100033);

$sqlFileStream.Seek(0L, [System.IO.SeekOrigin]::Begin);

$numBytes = $sqlFileStream.Read($buffer, 0, $buffer.Length);

$sqlFileStream.Close();

$cmd.Transaction.Commit();

$formater = [System.Runtime.Serialization.Formatters.Binary.BinaryFormatter]::new();
$memoryStream = [System.IO.MemoryStream]::new($buffer);


$someData_ = @(0);

for ($idx = 0; $idx -lt 100; $idx++)
{
    for ($jdx = 0; $jdx -lt 100; $jdx++)
    {
        $someData_ += [double]0;
    }
}


$someData_ = $formater.Deserialize($memoryStream); #now my data is in this memorystream


