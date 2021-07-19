@echo off


REM IMPORTANT: This file must be in CRLF format and not LF, i.e. \r\n line ends instead of only \n.
REM Call signature: `run.bat <stage> [<YYYYMMDD> [path\to\config\file.bat]]`
REM   * <stage> should be one of the following (without the backquotes): `etl`, `convert`, `report`.
REM   * `<YYYYMMDD>` is a placeholder for date, e.g. `20201231` for `31/12/2020`.
REM   * If 3nd argument was not passed, will use `config.bat` file under current working directory.
REM   * If 2nd argument was not passed, will use system date instead (the logic is in the config file).
REM Exit Codes:
REM 0 - Success
REM 1 - Unhandled error.
REM 2 - Batch error (not related to CompuRisk). E.g. missing config file.
REM 5 - Batch (minor) warning (not related to CompuRisk). E.g. failed to compact contracts.mdb.
REM 10 - Warning. E.g. missing execution log file or CompuRisk's exit code due to warnings in execution log.
REM 15 - Important warning. CompuRisk's exit code due to important warnings in execution log, e.g. due to warnings in conversion log.
REM 20 - Severe warning. CompuRisk's exit code due to severe warnings in execution log, e.g. due to errors in conversion log.
REM 25 - Error. E.g. missing report or conversion log files or CompuRisk's exit code due to exceptions in execution log.


set EXITCODE=0


REM >>> 1 >>> Selecting the Batches to be Run
setlocal EnableDelayedExpansion
if "%~1" EQU "" (
	call :EchoDateTime & echo ^>^>^> ERROR: No batches were supplied. ^<^<^<
	set EXITCODE=2
	goto :Exit
) else (
	set RUNNING=
	if "%~1" EQU "etl" (
		set RUNNING=%~1
		set LNAME=ETL
		set UNAME=ETL
		set CHECK_MISSING_FILES=0
	)
	if "%~1" EQU "convert" (
		set RUNNING=%~1
		set LNAME=convert
		set UNAME=Convert
		set CHECK_MISSING_FILES=1
	)
	if "%~1" EQU "report" (
		set RUNNING=%~1
		set LNAME=report
		set UNAME=Reporting
		set CHECK_MISSING_FILES=1
	)
	if "!RUNNING!" EQU "" (
		call :EchoDateTime & echo ^>^>^> ERROR: Unrecognized batches were supplied. ^<^<^<
		set EXITCODE=2
		goto :Exit
	)
)
endlocal & (set RUNNING=%RUNNING%) & (set LNAME=%LNAME%) & (set UNAME=%UNAME%) & (set CHECK_MISSING_FILES=%CHECK_MISSING_FILES%)
shift
REM <<< 1 <<< Selecting the Batches to be Run


call :EchoDateTime & echo ~~~~~~~~~~~~~~~~~~~~ Started %UNAME% ~~~~~~~~~~~~~~~~~~~~


REM >>> 2 >>> Loading Configuration
if "%~2" NEQ "" (
	set CONFIG_FILE=%~2
) else (
	set CONFIG_FILE=config.bat
)
if not exist "%CONFIG_FILE%" (
	call :EchoDateTime & echo ERROR: Automation configuration file was not found.
	set EXITCODE=2
	goto :Exit
)
call %CONFIG_FILE% %~1
if %ERRORLEVEL% NEQ 0 (
	REM Internal convention is that script error code is 2. If error code is anything else, it is probably due to system failure, so we set the code to 1.
	if %ERRORLEVEL% NEQ 2 (set EXITCODE=1) else (set EXITCODE=2)
	goto :Exit
)

if "%RUNNING%" EQU "etl" set BATCHES=%ETL_BATCHES%
if "%RUNNING%" EQU "convert" set BATCHES=%CONVERT_BATCHES%
if "%RUNNING%" EQU "report" set BATCHES=%REPORT_BATCHES%
REM <<< 2 <<< Loading Configuration


REM >>> 3 >>> Making Sure CompuRisk Project Exists
if %DEBUG% NEQ 0 (
	call :EchoDateTime & echo DEBUG: Making sure CompuRisk project exists
)
if not exist "%WORK_DIR%\%PROJECT_FILENAME%" (
	call :EchoDateTime & echo `"%WORK_DIR%\%PROJECT_FILENAME%"` CompuRisk's project was not found. Make sure that execution date is correct and that project's path is correct.
	set EXITCODE=2
	goto :Exit
)
REM >>> 3 >>> Making Sure CompuRisk Project Exists


REM >>> 4 >>> Compacting Contracts.mdb before ETL
setlocal EnableDelayedExpansion
if "%RUNNING%" EQU "etl" (
	if %COMPACT% NEQ 0 (
		call :EchoDateTime & (echo | set /p _=Compacting `%WORK_DIR%\%CONTRACTS_FILENAME%` before ETL... )
		%MSACCESS% "%WORK_DIR%\%CONTRACTS_FILENAME%" /compact
		if !ERRORLEVEL! NEQ 0 (
			(echo | set /p _=FAILED@) & call :EchoDateTime & echo.
			call :EchoDateTime & echo WARNING: There was an error during DB compacting.
			set EXITCODE=5
		) else (
			(echo | set /p _=DONE@) & call :EchoDateTime & echo.
		)
	)
)
endlocal & set EXITCODE=%EXITCODE%
REM <<< 4 <<< Compacting Contracts.mdb before ETL


REM >>> 5 >>> Calculating the Number of Output Files
REM Not needed for ETL
set NUMBER_OF_OUTPUT_FILES=1
:NumberOfOutputFilesLoop
if defined OUTPUT_FILES[%NUMBER_OF_OUTPUT_FILES%] (
	set /A NUMBER_OF_OUTPUT_FILES+=1
	goto :NumberOfOutputFilesLoop
)
set /A NUMBER_OF_OUTPUT_FILES-=1
REM <<< 5 <<< Calculating the Number of Output Files


REM >>> 6 >>> Running Batches (and in Case of ETL, Compacting Contracts.mdb after Each)
if %DEBUG% NEQ 0 (
	call :EchoDateTime & echo DEBUG: Started CompuRisk's batches execution loop
)
setlocal EnableDelayedExpansion
for %%B in (%BATCHES%) do (
	call :EchoDateTime & (echo | set /p _=Running `%%B` %LNAME% batch... )
	set CURRENT_EXITCODE=0
	call %COMPURISK% "%WORK_DIR%\%PROJECT_FILENAME%" /batch %%B "%COPY_DIR%" "%LOGS_DIR%\%YYYYMMDD%_%%B.log"
	set COMPURISK_EXITCODE=!ERRORLEVEL!
	if %DEBUG% NEQ 0 (
		echo.
		call :EchoDateTime & echo DEBUG: CompuRisk's exit code for `%%B` batch is !COMPURISK_EXITCODE!
	)
	if !COMPURISK_EXITCODE! NEQ 0 (
		if %DEBUG% NEQ 0 (
			call :EchoDateTime & echo DEBUG: CompuRisk's supported exit codes are `%COMPURISK_EXITCODES%`
		)
		set CURRENT_EXITCODE=1
		for %%Z in (%COMPURISK_EXITCODES%) do (
			if %DEBUG% NEQ 0 (
				call :EchoDateTime & echo DEBUG: Checking if CompuRisk's exit code is `%%Z`
			)
			if %%Z EQU !COMPURISK_EXITCODE! set CURRENT_EXITCODE=!COMPURISK_EXITCODE!
		)
	)
	if %DEBUG% NEQ 0 (
		call :EchoDateTime & echo DEBUG: Adjusted exit code for `%%B` batch is !CURRENT_EXITCODE!
	)
	if !CURRENT_EXITCODE! EQU 1 (
		(echo | set /p _=FAILED@) & call :EchoDateTime & echo.
		call :EchoDateTime & echo ERROR: CompuRisk failed due to an unknown error.
		set EXITCODE=1
		goto :Exit
	)
	if !EXITCODE! LSS !CURRENT_EXITCODE! set EXITCODE=!CURRENT_EXITCODE!
	if %DEBUG% NEQ 0 (
		call :EchoDateTime & echo DEBUG: Current script's exit code is !EXITCODE!
	)
	if !EXITCODE! GEQ %MIN_EXITCODE_FOR_FAILURE% (
		(echo | set /p _=FAILED@) & call :EchoDateTime & echo.
		call :EchoDateTime & echo ERROR: CompuRisk's Error Level ^(!EXITCODE!^) exceeded the defined threshold for failure ^(%MIN_EXITCODE_FOR_FAILURE%^).
		goto :Exit
	)
	if "%RUNNING%" NEQ "etl" (
		if %DEBUG% NEQ 0 (
			call :EchoDateTime & echo DEBUG: Checking existence of `%%B` batch's expected output files
		)
		set MISSING_FILES=
		for /L %%N in (1,1,%NUMBER_OF_OUTPUT_FILES%) do (
			for /F "tokens=1-3" %%X in ("!OUTPUT_FILES[%%N]!") do (
				if "%%X" EQU "%%B" if not exist "%%Y\%YYYYMMDD%_%%Z" set MISSING_FILES=!MISSING_FILES! %YYYYMMDD%_%%Z;
			)
		)
		if "!MISSING_FILES!" NEQ "" (
			(echo | set /p _=FAILED@) & call :EchoDateTime & echo.
			call :EchoDateTime & echo ERROR: `%%B` batch failed to export the following file^(s^):!MISSING_FILES!
			set EXITCODE=25
			goto :Exit
		)
		(echo | set /p _=DONE@) & call :EchoDateTime & echo.
	) else (
		(echo | set /p _=DONE@) & call :EchoDateTime & echo.
		if %COMPACT% NEQ 0 (
			call :EchoDateTime & (echo | set /p _=Compacting `%WORK_DIR%\%CONTRACTS_FILENAME%` after `%%B` ETL batch... )
			%MSACCESS% "%WORK_DIR%\%CONTRACTS_FILENAME%" /compact
			if !ERRORLEVEL! NEQ 0 (
				(echo | set /p _=FAILED@) & call :EchoDateTime & echo.
				call :EchoDateTime & echo WARNING: There was an error during DB compacting.
				set EXITCODE=5
			) else (
				(echo | set /p _=DONE@) & call :EchoDateTime & echo.
			)
		)
	)
	if %DEBUG% NEQ 0 (
		call :EchoDateTime & echo DEBUG: Checking existence of `%%B` batch's modules log
	)
	if not exist "%LOGS_DIR%\%YYYYMMDD%_%%B.log" (
		call :EchoDateTime & echo WARNING: `%LOGS_DIR%\%YYYYMMDD%_%%B.log` file is missing.
		if !EXITCODE! LSS 10 set EXITCODE=10
	)
)
endlocal & set EXITCODE=%EXITCODE%
if %DEBUG% NEQ 0 (
	call :EchoDateTime & echo DEBUG: Finished CompuRisk's batches execution loop
)
REM <<< 6 <<< Running Batches (and in Case of ETL, Compacting Contracts.mdb after Each)


REM >>> 7 >>> Clean
if %CLEAN% NEQ 0 (
	call :EchoDateTime & (echo | set /p _=Deleting temp files...)
	if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
	if exist "%WORK_DIR%\~%PROJECT_FILENAME%*" del /f /q "%WORK_DIR%\~%PROJECT_FILENAME%*"
	echo. DONE
)
REM <<< 7 <<< Clean


REM >>> 8 >>> Exit
:Exit
set END_MESSAGE=~~~~~~~~~~~~~ %UNAME% Failed for Unknown Reason ~~~~~~~~~~~~~
if %EXITCODE% EQU 0 set END_MESSAGE=~~~~~~~~~~~~~ %UNAME% Finished Successfully ~~~~~~~~~~~~~
if %EXITCODE% EQU 1 set END_MESSAGE=~~~~~~~~~~~~~~~ %UNAME% Failed Critically ~~~~~~~~~~~~~~~
if %EXITCODE% EQU 2 set END_MESSAGE=~~~~~~~~~~ %UNAME% Failed Due to Script Error ~~~~~~~~~~~
if %EXITCODE% EQU 5 set END_MESSAGE=~~ %UNAME% Finished Successfully. Failed Compacting DB ~~
if %EXITCODE% EQU 10 set END_MESSAGE=~~~~~~~~~~~~~ %UNAME% Finished with Warnings ~~~~~~~~~~~~
if %EXITCODE% EQU 15 set END_MESSAGE=~~~~~~~~ %UNAME% Finished with Important Warnings ~~~~~~~
if %EXITCODE% EQU 20 set END_MESSAGE=~~~~~~~~~ %UNAME% Finished with Severe Warnings ~~~~~~~~~
if %EXITCODE% EQU 25 set END_MESSAGE=~~~~~~~~~~~~~~ %UNAME% Finished with Errors ~~~~~~~~~~~~~
if %ERRORLEVEL% NEQ 0 set END_MESSAGE=~~~~~~~~~~~~~ %UNAME% Failed for Unknown Reason ~~~~~~~~~~~~~
if %DEBUG% NEQ 0 (
	call :EchoDateTime & echo DEBUG: Exiting with %EXITCODE% exit code
)
call :EchoDateTime & echo %END_MESSAGE%
exit /b %EXITCODE%
REM <<< 8 <<< Exit


:EchoDateTime
REM <<<<<<<<<<<<<<<<<<<<<<<< IMPORTANT >>>>>>>>>>>>>>>>>>>>>>>>
REM Depending on Windows regional format, the formula may need to be changed.
(echo | set /p _=%DATE% %TIME% )
