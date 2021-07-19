@echo off
REM Utility script that calls `test.bat` script with yesterday's date.
powershell "C:\Users\Digibank01\Desktop\FDB_Automation\ScriptsAndDocs\test.bat" $([DateTime]::Today.AddDays(-1).ToString('yyyyMMdd'))
