---------------------------------------------------------
--------	SQL Server 2017 Developer’s Guide    --------
------   Chapter 13 - Supporting R in SQL Server  -------
---------------------------------------------------------

----------------------------------------------------
-- Section 4: SQL Server R Services
----------------------------------------------------

-- Configure SQL Server to enable external scripts
USE master;
EXEC sys.sp_configure 'show advanced options', 1;
RECONFIGURE
EXEC sys.sp_configure 'external scripts enabled', 1; 
RECONFIGURE;
GO
-- Check the configuration
EXEC sys.sp_configure;
GO

-- Check R version
EXECUTE sys.sp_execute_external_script
 @language=N'R',
 @script = 
 N'str(OutputDataSet);
   OutputDataSet <- as.data.frame(R.version.string);'
WITH RESULT SETS ( ( PackageName nvarchar(50) ) );
GO

-- Check installed packages
EXECUTE sys.sp_execute_external_script
 @language=N'R',
 @script = 
 N'str(OutputDataSet);
   packagematrix <- installed.packages();
   NameOnly <- packagematrix[,1];
   OutputDataSet <- as.data.frame(NameOnly);'
WITH RESULT SETS ( ( PackageName nvarchar(20) ) );
GO

-- Check the results of the logistic regression prediction
USE AdventureWorksDW2014;
SELECT * 
FROM dbo.TargetMailLogR;
GO

-- Create a table to store a model
CREATE TABLE dbo.RModels
(Id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
 ModelName NVARCHAR(50) NOT NULL,
 Model VARBINARY(MAX) NOT NULL);
GO

-- Procedure to store a model
CREATE PROCEDURE dbo.InsertModel
(@modelname NVARCHAR(50),
 @model NVARCHAR(MAX))
AS
BEGIN
    SET NOCOUNT ON;  
    INSERT INTO dbo.RModels (ModelName, Model)
	VALUES (@modelname, CONVERT(VARBINARY(MAX), @model, 2));
END;
GO

-- Serialize the model from R
-- Use it for predictions

-- Prediction on a single row
DECLARE @input AS NVARCHAR(MAX)
SET @input = N'
    SELECT * 
    FROM (VALUES 
          (0, 2, 44, 90000)) AS 
          inpQ(NumberCarsOwned, TotalChildren, Age, YearlyIncome);' 
DECLARE @mod VARBINARY(max) =
 (SELECT Model 
  FROM DBO.RModels
  WHERE ModelName = N'bbLogR');  
EXEC sys.sp_execute_external_script
 @language = N'R',  
 @script = N'  
  mod <- unserialize(as.raw(model));  
  OutputDataSet<-rxPredict(modelObject = mod, data = InputDataSet, outData = NULL,   
          predVarNames = "BikeBuyerPredict", type = "response", 
		  checkFactorLevels=FALSE,
		  writeModelVars = TRUE, overwrite = TRUE);  
 ',  
  @input_data_1 = @input,  
  @params = N'@model VARBINARY(MAX)',
  @model = @mod  
WITH RESULT SETS ((
 BikeBuyerPredict FLOAT,
 NumberCarsOwned INT,
 TotalChildren INT,
 Age INT,
 YearlyIncome FLOAT));  
GO


-- Decision Trees model for the PREDICT T-SQL function 
DECLARE @model VARBINARY(MAX);
EXECUTE sys.sp_execute_external_script
  @language = N'R'
 ,@script = N'
   bbDTree <- rxDTree(BikeBuyer ~ NumberCarsOwned +
                        TotalChildren + Age + YearlyIncome,
                      data = sqlTM);
   model <- rxSerializeModel(bbDTree, realtimeScoringOnly = TRUE);'
 ,@input_data_1 = N'
     SELECT CustomerKey, BikeBuyer, NumberCarsOwned,
	  TotalChildren, Age, YearlyIncome
     FROM dbo.vTargetMail;'
 ,@input_data_1_name =  N'sqlTM'
 ,@params = N'@model VARBINARY(MAX) OUTPUT'
 ,@model = @model OUTPUT;
INSERT INTO dbo.RModels (ModelName, Model)
VALUES('bbDTree', @model);
GO

-- Check the models
SELECT *
FROM dbo.RModels;
GO


-- Use the PREDICT function
DECLARE @model VARBINARY(MAX) = 
(
  SELECT Model
  FROM dbo.RModels
  WHERE ModelName = 'bbDTree'
);
SELECT d.CustomerKey, d.BikeBuyer,
 d.NumberCarsOwned, d.TotalChildren, d.Age, 
 d.YearlyIncome, p.BikeBuyer_Pred
FROM PREDICT(MODEL = @model, DATA = dbo.vTargetMail AS d)
WITH(BikeBuyer_Pred FLOAT) AS p
ORDER BY d.CustomerKey;
GO


-- Clean up
USE AdventureWorksDW2014;
GO
DROP PROCEDURE dbo.InsertModel;
DROP TABLE dbo.RModels;
DROP TABLE dbo.TargetMailLogR;
GO
