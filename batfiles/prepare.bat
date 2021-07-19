@echo off


REM IMPORTANT: This file must be in CRLF format and not LF, i.e. \r\n line ends instead of only \n.
REM Call signature: `prepare.bat [<YYYYMMDD> [path\to\config\file.bat]]`
REM   * `<YYYYMMDD>` is a placeholder for date, e.g. `20201231` for `31/12/2020`.
REM   * If 2nd argument was not passed, will use `config.bat` file under current working directory.
REM   * If 1st argument was not passed, will use system date instead (the logic is in the config file).
REM Exit Codes:
REM 0 - Success
REM 1 - Unhandled error.
REM 2 - Error. E.g. missing config or input file.


set EXITCODE=0


call :EchoDateTime & echo ~~~~~~~~~~~~~~~~~~~~~~ Started Preparation ~~~~~~~~~~~~~~~~~~~~~~


REM >>> 1 >>> Loading Configuration
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
REM <<< 1 <<< Loading Configuration


REM >>> 2 >>> Dealing with Existing %WORK_DIR%
REM Make sure that %WORK_DIR% doesn't exist and exit with an error if it does
REM (unless %OVERRIDE% flag is true, in which case will delete it instead).
set DELETE_WORK_DIR_ON_ERROR=1
if exist "%WORK_DIR%" (
	if %OVERRIDE% NEQ 0 (
		call :EchoDateTime & (echo. | set /p _=Override flag is on. Removing existing `%WORK_DIR%` directory...)
		rmdir /s /q "%WORK_DIR%"
		echo. DONE
	) else (
		call :EchoDateTime & echo Preparation failed since `%WORK_DIR%` directory already exists.
		set DELETE_WORK_DIR_ON_ERROR=0
		set EXITCODE=2
		goto :Exit
	)
)
REM <<< 2 <<< Dealing with Existing %WORK_DIR%


REM >>> 3 >>> Setting Up Project's (Empty) Directory Structure
call :EchoDateTime & (echo | set /p _=Setting Up Project's Directory Structure...)
xcopy "%TEMPLATE_DIR%" "%WORK_DIR%\" /t /e
if %ERRORLEVEL% NEQ 0 (
	echo. FAILED
	set EXITCODE=2
	goto :Exit
)
echo. DONE
REM <<< 3 <<< Setting Up Project's (Empty) Directory Structure


REM >>> 4 >>> Temporary Backing Up Daily Data Files
REM Note: Not used in any calculations. Just in case updating file dates in project below fails, and not all data files are copied to work dir.
call :EchoDateTime & (echo | set /p _=Temporary Backing Up Daily Data Files... )
set TEMP_DATA_BACKUP_DIR=%WORK_DIR%\TempDataBackup
xcopy "%INPUT_DATA_DIR%" "%TEMP_DATA_BACKUP_DIR%\" /e /y /q
if %ERRORLEVEL% NEQ 0 set EXITCODE=5
REM <<< 4 <<< Temporary Backing Up Daily Data Files


REM >>> 5 >>> Calculating the Number of Input and Output Files
set NUMBER_OF_INPUT_FILES=1
:InputFilesLoop
if defined INPUT_FILES[%NUMBER_OF_INPUT_FILES%] ( 
set /A NUMBER_OF_INPUT_FILES+=1
goto :InputFilesLoop
)
set /A NUMBER_OF_INPUT_FILES-=1

set NUMBER_OF_OUTPUT_FILES=1
:OutputFilesLoop
if defined OUTPUT_FILES[%NUMBER_OF_OUTPUT_FILES%] ( 
set /A NUMBER_OF_OUTPUT_FILES+=1
goto :OutputFilesLoop
)
set /A NUMBER_OF_OUTPUT_FILES-=1
REM <<< 5 <<< Calculating the Number of Input and Output Files


REM >>> 6 >>> Copying Files into %WORK_DIR%
REM Copying all required of the required files.
REM Logging in preparation log (located in work dir) all of the original names of the dated files.
setlocal EnableDelayedExpansion
set K=0
set MISSING_FILES=
for /L %%N in (1,1,%NUMBER_OF_INPUT_FILES%) do (
	for /F "tokens=1-4" %%A in ("!INPUT_FILES[%%N]!") do (
		set FILE_TEMPLATE=%%B
		if "%%C" == "Y" (
			set /A K+=1
			for /F "tokens=1,2 delims=." %%X in ("%%B") do (
				set FILE_TEMPLATE=%%X_20*.%%Y
			)
		)
		set SOURCE_FILEPATH=
		set SOURCE_FILENAME=
		for %%F in (%%A\!FILE_TEMPLATE!) do (
			set SOURCE_FILEPATH=%%F
			for %%G in ("%%F") do (
				set SOURCE_FILENAME=%%~NG%%~XG
			)
		)
		if "!SOURCE_FILENAME!" NEQ "" (
			call :EchoDateTime & (echo | set /p _=Copying `!SOURCE_FILEPATH!` to `%%D\!SOURCE_FILENAME!`...)
			copy "!SOURCE_FILEPATH!" "%%D\!SOURCE_FILENAME!" /v /y
			if not exist "%%D\!SOURCE_FILENAME!" set MISSING_FILES=!MISSING_FILES! %%B;
			if exist "%WORK_DIR%\%PROJECT_FILENAME%" (
				if "%%B" == "%PROJECT_FILENAME%" (
					REM >>>>>> Replacing Paths in Project File <<<<<<
					call :EchoDateTime & (echo | set /p _=Replacing paths in `%WORK_DIR%\%PROJECT_FILENAME%`...)
					for /F "tokens=3 delims=:" %%Z in ('find /c "%TEMPLATE_DIR%" "%WORK_DIR%\%PROJECT_FILENAME%"') do (
						set LEN=%%Z
					)
					if !LEN:~1! NEQ 0 (
						powershell "(Get-Content '%WORK_DIR%\%PROJECT_FILENAME%').replace('%TEMPLATE_DIR%','%WORK_DIR%') | Out-File -encoding utf8 '%WORK_DIR%\%PROJECT_FILENAME%'"
						for /F "tokens=3 delims=:" %%Z in ('find /c "%WORK_DIR%" "%WORK_DIR%\%PROJECT_FILENAME%"') do (
							set LEN=%%Z
							if !LEN:~1! EQU 0 (
								echo. FAILED
								call :EchoDateTime & echo ERROR: Failed replacing project's paths.
								set EXITCODE=2
								goto :Exit
							)
						)
					)
					echo. DONE
					if !LEN:~1! EQU 0 call :EchoDateTime & echo WARNING: No paths were replaced since `%TEMPLATE_DIR%` was not found in the project. This is OK if all project's paths are relative.
					
					REM >>>>>> Updating Dates in Project File <<<<<<
					call :EchoDateTime & (echo | set /p _=Updating dates in `%WORK_DIR%\%PROJECT_FILENAME%`...)
					for %%T in (CashFlowDate PriceDate VolatilityDate StartDate) do (
						powershell "(Get-Content '%WORK_DIR%\%PROJECT_FILENAME%').replace('<%%T>%CRPROJ_DATE_PLACEHOLDER%</%%T>','<%%T>%DD_MM_YYYY% 00:00:00</%%T>') | Out-File -encoding utf8 '%WORK_DIR%\%PROJECT_FILENAME%'"
						if %%T EQU StartDate powershell "(Get-Content '%WORK_DIR%\%PROJECT_FILENAME%').replace('<%%T>01/01/0001 00:00:00</%%T>','<%%T>%DD_MM_YYYY% 00:00:00</%%T>') | Out-File -encoding utf8 '%WORK_DIR%\%PROJECT_FILENAME%'"
						for /F "tokens=3 delims=:" %%Z in ('find /c "<%%T>%DD_MM_YYYY% 00:00:00</%%T>" "%WORK_DIR%\%PROJECT_FILENAME%"') do (
							set LEN=%%Z
							if !LEN:~1! EQU 0 (
								echo. FAILED
								call :EchoDateTime & echo ERROR: Failed updating project's %%T to %DD_MM_YYYY%.
								set EXITCODE=2
								goto :Exit
							)
						)
					)
					echo. DONE
					
					REM >>>>>> Adding Dates to Output Files in Project File <<<<<<
					set FAILED_TO_ADD_DATES=
					call :EchoDateTime & (echo | set /p _=Adding dates to output file names in `%WORK_DIR%\%PROJECT_FILENAME%`...)
					for /L %%X in (1,1,%NUMBER_OF_OUTPUT_FILES%) do (
						for /F "tokens=3" %%Y in ("!OUTPUT_FILES[%%X]!") do (
							powershell "(Get-Content '%WORK_DIR%\%PROJECT_FILENAME%').replace('%%Y','%YYYYMMDD%_%%Y') | Out-File -encoding utf8 '%WORK_DIR%\%PROJECT_FILENAME%'"
							for /F "tokens=3 delims=:" %%Z in ('find /c "%YYYYMMDD%_%%Y" "%WORK_DIR%\%PROJECT_FILENAME%"') do (
								set LEN=%%Z
								if !LEN:~1! EQU 0 set FAILED_TO_ADD_DATES=!FAILED_TO_ADD_DATES! %%Y;
							)
						)
					)
					if "!FAILED_TO_ADD_DATES!" NEQ "" (
						echo. FAILED
						call :EchoDateTime & echo ERROR: Failed to add a date to the following log files:!FAILED_TO_ADD_DATES!
						set EXITCODE=2
						goto :Exit
					)
					echo. Done adding dates to %NUMBER_OF_OUTPUT_FILES% output file^(s^).
				)
				
				REM >>>>>> Replacing Input File Names in Project File by Dated Ones <<<<<<
				if "%%C" == "Y" (
					call :EchoDateTime & (echo | set /p _=Replacing `%%B` file's name in `%WORK_DIR%\%PROJECT_FILENAME%` by `!SOURCE_FILENAME!`...)
					powershell "(Get-Content '%WORK_DIR%\%PROJECT_FILENAME%').replace('%%B','!SOURCE_FILENAME!') | Out-File -encoding utf8 '%WORK_DIR%\%PROJECT_FILENAME%'"
					for /F "tokens=3 delims=:" %%L in ('find /c "!SOURCE_FILENAME!" "%WORK_DIR%\%PROJECT_FILENAME%"') do (
						set LEN=%%L
						if !LEN:~1! EQU 0 (
							echo. FAILED
							call :EchoDateTime & echo ERROR: Failed replacing `%%B` file's name by `!SOURCE_FILENAME!`.
							set EXITCODE=2
							goto :Exit
						)
					)
					echo. DONE
				)
			)
		) else (
			call :EchoDateTime & echo ERROR: Source file for `%%B` wasn't found in `%%A`.
		)
	)
)
if "!MISSING_FILES!" NEQ "" (
	call :EchoDateTime & echo ERROR: The following files are missing:!MISSING_FILES!
	set EXITCODE=1
	goto :Exit
)
endlocal
REM <<< 6 <<< Copying Files into %WORK_DIR%


REM >>> 7 >>> Copying Layouts
call :EchoDateTime & (echo | set /p _=Copying layouts from `%LAYOUTS_DIR%\%LAYOUTS_DIRNAME%` to `%WORK_DIR%\%LAYOUTS_DIRNAME%`... )
xcopy "%TEMPLATE_DIR%\%LAYOUTS_DIRNAME%\*.xml" "%WORK_DIR%\%LAYOUTS_DIRNAME%\" /v /y /q
REM <<< 7 <<< Copying Layouts


REM >>> 8 >>> Removing Temporary Backed Up Data Files
REM Note: If we've got here, temporary backed up data files are no longer needed since
REM       all used data files were successfully copied and their date updated in the project.
if %CLEAN% NEQ 0 (
	(call :EchoDateTime) & (echo | set /p _=Removing Temporary Backed Up Data Files...)
	rmdir /s /q "%TEMP_DATA_BACKUP_DIR%"
	if %ERRORLEVEL% NEQ 0 (
		echo. FAILED
		set EXITCODE=5
	) else (
		echo. DONE
	)
)
REM <<< 8 <<< Removing Temporary Backed Up Data Files


REM >>> 9 >>> Info About APPDATA Folder
REM Should point to "C:\Users\<username>\AppData\Roaming". If it doesn't,
REM e.g. when the script is executed via a scheduler, such as Control-M,
REM CompuRisk's execution in the following scripts may fail.
call :EchoDateTime & echo INFO: `APPDATA` folder is "%APPDATA%".
REM <<< 9 <<< Info About APPDATA Folder


REM >>> 10 >>> Exit
:Exit
set END_MESSAGE=~~~~~~~~~~~~~ Preparation Failed for Unknown Reason ~~~~~~~~~~~~~
if %EXITCODE% EQU 0 set END_MESSAGE=~~~~~~~~~~~~~ Preparation Finished Successfully ~~~~~~~~~~~~~
if %EXITCODE% EQU 1 set END_MESSAGE=~~~~~~~~~~~~~~~ Preparation Failed Critically ~~~~~~~~~~~~~~~
if %EXITCODE% EQU 2 set END_MESSAGE=~~~~~~~~~~ Preparation Failed Due to Script Error ~~~~~~~~~~~
if %ERRORLEVEL% NEQ 0 set END_MESSAGE=~~~~~~~~~~~~~ Preparation Failed for Unknown Reason ~~~~~~~~~~~~~
call :EchoDateTime & echo %END_MESSAGE%
exit /b %EXITCODE%
REM <<< 10 <<< Exit


:EchoDateTime
REM <<<<<<<<<<<<<<<<<<<<<<<< IMPORTANT >>>>>>>>>>>>>>>>>>>>>>>>
REM Depending on Windows regional format, the formula may need to be changed.
(echo | set /p _=%DATE% %TIME% )
