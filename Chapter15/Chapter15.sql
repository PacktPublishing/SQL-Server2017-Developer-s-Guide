---------------------------------------------------------
--------	SQL Server 2017 Developer’s Guide    --------
--------     Chapter 15 - Introducing Python   ----------
---------------------------------------------------------

----------------------------------------------------
-- Section 3: Data Science with Python
----------------------------------------------------

-- Configure SQL Server to enable external scripts
USE master;
EXEC sys.sp_configure 'show advanced options', 1;
RECONFIGURE WITH OVERRIDE;
EXEC sys.sp_configure 'external scripts enabled', 1; 
RECONFIGURE WITH OVERRIDE;
GO
-- Restart SQL Server
-- Check the configuration
EXEC sys.sp_configure;
GO

-- Test Python
EXECUTE sys.sp_execute_external_script 
@language =N'Python',
@script=N'
OutputDataSet = InputDataSet
print("Input data is: \n", InputDataSet)
', 
@input_data_1 = N'SELECT 1 as col';
GO

-- Preparing the RUser for ML
CREATE LOGIN RUser WITH PASSWORD=N'Pa$$w0rd';
GO
USE AdventureWorksDW2014;
GO
CREATE USER RUser FOR LOGIN RUser;
ALTER ROLE db_datareader ADD MEMBER RUser;
GO

-- Prepare the AWDW system DSN in ODBC64 admin tool
-- Test the connection in Python code

-- Use revoscalepy
USE AdventureWorksDW2014;
EXECUTE sys.sp_execute_external_script 
@language =N'Python',
@script=N'
from revoscalepy import rx_lin_mod, rx_predict
import pandas as pd
linmod = rx_lin_mod(
    "NumberCarsOwned ~ YearlyIncome + Age + TotalChildren", 
    data = InputDataSet)
predmod = rx_predict(linmod, data = InputDataSet, output_data = InputDataSet)
print(linmod)
OutputDataSet = predmod
', 
@input_data_1 = N'
SELECT CustomerKey, CAST(Age AS INT) AS Age,
  CAST(YearlyIncome AS INT) AS YearlyIncome, 
  TotalChildren, NumberCarsOwned
FROM dbo.vTargetMail;'
WITH RESULT SETS ((
 "CustomerKey" INT NOT NULL,
 "Age" INT NOT NULL,
 "YearlyIncome" INT NOT NULL,
 "TotalChildren" INT NOT NULL,
 "NumberCarsOwned" INT NOT NULL, 
 "NumberCarsOwned_Pred" FLOAT NULL));
GO

-- End of script
