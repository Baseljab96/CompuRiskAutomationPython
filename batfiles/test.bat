@echo off

REM A utility for running automation test, e.g. after updating `Template` folder or `config.bat` file.
REM 1. Will backup, for the duration of the test, any production folder for test date in a swap folder.
REM 2. Run the test for the exact production template and config.
REM 3. Move the result from `Archive` to `Test\Archive` folder.
REM 4. If existed before the test, move the backed up production folder for test date drom swap to `Archive`.

REM You can supply RUNDATE value here.
REM IMPORTANT: If you pass it via the CLI or want to use today's date, leave it empty,
REM            i.e. NOTHING is after `=` sign, not even spaces.
set RUNDATE=
set BASE_DIR=C:\Users\Digibank01\Desktop\FDB_Automation

if "%RUNDATE%" EQU "" (
	if "%~1" NEQ "" (
		set RUNDATE=%~1
	) else (
		set RUNDATE=%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%
	)
)
set THRESHOLD_EXITCODE=25
set LOGGED_SCRIPT=%BASE_DIR%\ScriptsAndDocs\logged.bat
set LOG_FILE=%BASE_DIR%\ScriptsAndDocs\progress.log
set CONFIG_SCRIPT=%BASE_DIR%\ScriptsAndDocs\config.bat
set RUN_SCRIPT=%BASE_DIR%\ScriptsAndDocs\run.bat
set PREPARE_SCRIPT=%BASE_DIR%\ScriptsAndDocs\prepare.bat
set ARCHIVE_FOLDER=%BASE_DIR%\Archive
set TEST_FOLDER=%BASE_DIR%\Test
set TEST_ARCHIVE_FOLDER=%TEST_FOLDER%\Archive
set TEST_SWAP_FOLDER=%TEST_FOLDER%\Swap

echo ^>^>^> Test ^>^>^> ================================================================>>"%LOG_FILE%"
echo ^>^>^> Test ^>^>^> Started...>>"%LOG_FILE%"

if not exist "%TEST_FOLDER%" mkdir "%TEST_FOLDER%
if not exist "%TEST_ARCHIVE_FOLDER%" mkdir "%TEST_ARCHIVE_FOLDER%

if exist "%ARCHIVE_FOLDER%\%RUNDATE%" (
	if exist "%TEST_SWAP_FOLDER%\%RUNDATE%" (
		echo ^>^>^> Test ^>^>^> Can't continue with the test since "%TEST_SWAP_FOLDER%" swap folder already exists.>>"%LOG_FILE%"
		echo ^>^>^> Test ^>^>^> Make sure that everything is correct and ^(re^)move this folder. =>>"%LOG_FILE%"
		pause
		exit /b 1
	)
	echo ^>^>^> "%ARCHIVE_FOLDER%\%RUNDATE%" exists. Moving to swap folder...>>"%LOG_FILE%"
	mkdir "%TEST_SWAP_FOLDER%
	move "%ARCHIVE_FOLDER%\%RUNDATE%" "%TEST_SWAP_FOLDER%">>"%LOG_FILE%"
)

echo ^>^>^> Test ^>^>^> Killing CompuRisk and Excel...>>"%LOG_FILE%"
taskkill /f /im CompuRisk.exe
taskkill /f /im Excel.exe
cmd /c "exit 0"

echo ^>^>^> Test ^>^>^> Started Automation...>>"%LOG_FILE%"
if %ERRORLEVEL% NEQ 1 if %ERRORLEVEL% NEQ 2 if %ERRORLEVEL% LSS %THRESHOLD_EXITCODE% call "%LOGGED_SCRIPT%" "%LOG_FILE%" "%PREPARE_SCRIPT%"     %RUNDATE% "%CONFIG_SCRIPT%"
if %ERRORLEVEL% NEQ 1 if %ERRORLEVEL% NEQ 2 if %ERRORLEVEL% LSS %THRESHOLD_EXITCODE% call "%LOGGED_SCRIPT%" "%LOG_FILE%" "%RUN_SCRIPT%" etl     %RUNDATE% "%CONFIG_SCRIPT%"
if %ERRORLEVEL% NEQ 1 if %ERRORLEVEL% NEQ 2 if %ERRORLEVEL% LSS %THRESHOLD_EXITCODE% call "%LOGGED_SCRIPT%" "%LOG_FILE%" "%RUN_SCRIPT%" convert %RUNDATE% "%CONFIG_SCRIPT%"
if %ERRORLEVEL% NEQ 1 if %ERRORLEVEL% NEQ 2 if %ERRORLEVEL% LSS %THRESHOLD_EXITCODE% call "%LOGGED_SCRIPT%" "%LOG_FILE%" "%RUN_SCRIPT%" report  %RUNDATE% "%CONFIG_SCRIPT%"
echo ^>^>^> Test ^>^>^> Finished Automation.>>"%LOG_FILE%"

if exist "%TEST_ARCHIVE_FOLDER%\%RUNDATE%" (
	echo ^>^>^> Test ^>^>^>  Removing old "%TEST_ARCHIVE_FOLDER%\%RUNDATE%" folder...>>"%LOG_FILE%"
	rmdir /s /q "%TEST_ARCHIVE_FOLDER%\%RUNDATE%"
)
echo ^>^>^> Test ^>^>^> Moving "%ARCHIVE_FOLDER%\%RUNDATE%" to "%TEST_ARCHIVE_FOLDER%\"...>>"%LOG_FILE%"
move "%ARCHIVE_FOLDER%\%RUNDATE%" "%TEST_ARCHIVE_FOLDER%\"

if exist "%TEST_SWAP_FOLDER%\%RUNDATE%" (
	echo ^>^>^> Moving "%ARCHIVE_FOLDER%\%RUNDATE%" back from swap...>>"%LOG_FILE%"
	move "%TEST_SWAP_FOLDER%\%RUNDATE%" "%ARCHIVE_FOLDER%\">>"%LOG_FILE%"
	rmdir "%TEST_SWAP_FOLDER%"
)

echo ^>^>^> Test ^>^>^> DONE>>"%LOG_FILE%"
echo ^>^>^> Test ^>^>^> ================================================================>>"%LOG_FILE%"
