@echo off


REM IMPORTANT: This file must be in CRLF format and not LF, i.e. \r\n line ends instead of only \n.
REM Call signature: `config.bat [<YYYYMMDD>]`
REM   * `<YYYYMMDD>` is a placeholder for date, e.g. `20201231` for `31/12/2020`.
REM   * If 1st argument was not passed, will use system date instead (the logic is in the config file).
REM Exit Codes:
REM 0 - Success.
REM 2 - Error. E.g. CompuRisk or MS Access executable paths.


call :EchoDateTime & (echo | set /p _=Loading configuration...)


REM >>> 1 >>> Deal with Date Strings to be Used in Paths and in CompuRisk Project
REM DON'T EDIT THIS SECTION
if "%~1" NEQ "" (
	call set "YYYYMMDD=%~1"
	call set "DD_MM_YYYY=%%YYYYMMDD:~6,2%%/%%YYYYMMDD:~4,2%%/%%YYYYMMDD:~0,4%%"
) else (
	REM <<<<<<<<<<<<<<<<<<<<<<<< IMPORTANT >>>>>>>>>>>>>>>>>>>>>>>>
	REM Depending on Windows regional format, DD_MM_YYYY may need to be changed.
	call set "DD_MM_YYYY=%%DATE%%"
	call set "YYYYMMDD=%%DD_MM_YYYY:~6,4%%%%DD_MM_YYYY:~3,2%%%%DD_MM_YYYY:~0,2%%"
)
REM <<< 1 <<< Deal with Date Strings to be Used in Paths and in CompuRisk Project


REM >>> 2 >>> Flags
REM Will be used in `prepare.bat`. If not 0 and `WORK_DIR` exists, will remove and recreate.
set OVERRIDE=0

REM Will be used in `run.bat etl`. If not 0 and will compact `CONTRACTS_FILENAME` before and after each each batch.
set COMPACT=1

REM Will be used in `run.bat`. If not 0 and will delete `TEMP_DIR` and CompuRisk project's auto-backup files.
set CLEAN=1

REM If not 0, will log additional, debug, messages during scripts' execution.
REM Maybe useful to pinpoint the exact place a script fails at.
set DEBUG=0
REM <<< 2 <<< Flags


REM >>> 3 >>> Exit Codes
REM DON'T EDIT `COMPURISK_EXITCODES`.
set COMPURISK_EXITCODES=10 15 20 25

REM `MIN_EXITCODE_FOR_FAILURE` should be in [5, 25) range.
set MIN_EXITCODE_FOR_FAILURE=25
REM <<< 3 <<<  Exit Codes


REM >>> 4 >>> Application Paths
set COMPURISK="C:\Program Files\Hedge-Tech\CompuRisk\CompuRisk.exe"

REM `MSACCESS` is only required if `COMPACT` is not 0.
set MSACCESS="C:\Program Files\Microsoft Office\root\Office16\MSACCESS.EXE"
REM <<< 4 <<< Application Paths


REM >>> 5 >>> Folder Paths
REM `TEMPLATE_DIR` will contain project file, contracts file, layouts and constant input files.
REM Also, its folder structure is used as a template for `WORK_DIR`.
set TEMPLATE_DIR=C:\Users\bankuser01\Desktop\FDB_Automation\Template

REM `INPUT_DATA_DIR` will contain all of the input files that change daily/monthly.
set INPUT_DATA_DIR=C:\Users\bankuser01\Desktop\FDB_Automation\Data

REM `WORK_DIR` is the folder where all of the calculations will be done and all output files stored.
REM Its folder name should be dated.
set WORK_DIR=C:\Users\bankuser01\Desktop\FDB_Automation\Archive\%YYYYMMDD%

REM DON'T EDIT `LOGS_DIR`, `REPORTS_DIR` and `TEMP_DIR`.
set LOGS_DIR=%WORK_DIR%\Output\Logs
set REPORTS_DIR=%WORK_DIR%\Output\Reports
set TEMP_DIR=%WORK_DIR%\Output\Temp

REM If not empty, all reports and conversion log(s) will also be copied into a sub-directory of `COPY_DIR` by batch type.
set COPY_DIR=
REM <<< 5 <<< Folder Paths


REM >>> 6 >>> Batch Names
set ETL_BATCHES=^
	ETL

set CONVERT_BATCHES=^
	CONVERT

set REPORT_BATCHES=^
	VAR^
	CF^
	KRD
REM <<< 6 <<< Batch Names


REM >>> 7 >>>  Template File and Dir Names, and Placeholders
REM `PROJECT_FILENAME`, `CONTRACTS_FILENAME` and `LAYOUTS_DIRNAME` are the names of the appropriate files and folder in `TEMPLATE_DIR`.
set PROJECT_FILENAME=FDB.crproj
set CONTRACTS_FILENAME=Contracts.mdb
set LAYOUTS_DIRNAME=Layouts

REM `CRPROJ_DATE_PLACEHOLDER` is the date in "Duration Date", "Price Date" and "Val Date" in template CompuRisk's project (in `TEMPLATE_DIR`).
set CRPROJ_DATE_PLACEHOLDER=04/04/2021 00:00:00
REM <<< 7 <<<  Template File and Dir Names, and Placeholders


REM >>> 8 >>>  All Input Files to be Copied to `WORK_DIR` from `TEMPLATE_DIR` and `INPUT_DATA_DIR`
REM NOTE: Dated files are assumed to have a date before file's extension that starts with an underscore, then a 4 digit year, and then the rest of the date.
REM       E.g. If a file's name is `bbg.csv` and it is dated with date and time, then a possible dated name is `bbg_20210918_223000.csv`.
REM       More precisely , what being checked in the example above is that the file starts with `bbg_20` and then has at least 1 additional letter or number before the extension.
REM       So any of the following will also be considered valid dates files: `bbg_20x.csv`, `bbg_20102021_22.csv`, `bbg_20_.csv`, etc.
REM       If there are more the 1 matching file, last one, in alpha-numeric order, will be used.

REM						Source Directory				File's Name							Is Dated?	Target Directory
set INPUT_FILES[1]=		%TEMPLATE_DIR%					%PROJECT_FILENAME%					N			%WORK_DIR%
REM IMPORTANT: %PROJECT_FILENAME% above MUST go 1st, since while copying other files, project file may need to be edited.
set INPUT_FILES[2]=		%TEMPLATE_DIR%					%CONTRACTS_FILENAME%				N			%WORK_DIR%
set INPUT_FILES[3]=		%TEMPLATE_DIR%\Input\External	Manual.xlsx							N			%WORK_DIR%\Input\External
set INPUT_FILES[4]=		%TEMPLATE_DIR%\Input\Dummy		dummy_cs.csv						N			%WORK_DIR%\Input\Dummy
set INPUT_FILES[5]=		%TEMPLATE_DIR%\Input\Positions	ExternalparametersLiq.csv			N			%WORK_DIR%\Input\Positions
set INPUT_FILES[6]=		%TEMPLATE_DIR%\Input\Positions	ExternalParametersMarket.csv		N			%WORK_DIR%\Input\Positions
set INPUT_FILES[7]=		%TEMPLATE_DIR%\Input\Positions	TREE-COVER.csv						N			%WORK_DIR%\Input\Positions
set INPUT_FILES[8]=		%TEMPLATE_DIR%\Input\Market		Market_Curves_and_TP.csv			N			%WORK_DIR%\Input\Market
set INPUT_FILES[9]=		%TEMPLATE_DIR%\Input\Market		HistoricCPI.csv						N			%WORK_DIR%\Input\Market
set INPUT_FILES[10]=	%INPUT_DATA_DIR%				ACCOUNT_BAL_FULL.csv				Y			%WORK_DIR%\Input\Positions
set INPUT_FILES[11]=	%INPUT_DATA_DIR%				BaNCS_customer.csv					Y			%WORK_DIR%\Input\External
set INPUT_FILES[12]=	%INPUT_DATA_DIR%				BaNCS_portfolio.csv					Y			%WORK_DIR%\Input\External
set INPUT_FILES[13]=	%INPUT_DATA_DIR%				BaNCS_cards.csv						Y			%WORK_DIR%\Input\Positions
set INPUT_FILES[14]=	%INPUT_DATA_DIR%				BaNCS_currentaccountbalance.csv		Y			%WORK_DIR%\Input\Positions
set INPUT_FILES[15]=	%INPUT_DATA_DIR%				BaNCS_deposits.csv					Y			%WORK_DIR%\Input\Positions
REM <<< 8 <<<  All Input Files to be Copied to `WORK_DIR` from `TEMPLATE_DIR` and `INPUT_DATA_DIR`


REM >>> 9 >>>  Output (Conversion Log and Report) File Names
REM						Batch Name	Output Directory	File Name
set OUTPUT_FILES[1]=	CONVERT		%LOGS_DIR%			ConversionLog_Deposit.xlsx
set OUTPUT_FILES[2]=	CONVERT		%LOGS_DIR%			ConversionLog_CAB.xlsx
set OUTPUT_FILES[3]=	CONVERT		%LOGS_DIR%			ConversionLog_Cards.xlsx
set OUTPUT_FILES[4]=	CONVERT		%LOGS_DIR%			ConversionLog_ExtParametersMarket.xlsx
set OUTPUT_FILES[5]=	CONVERT		%LOGS_DIR%			ConversionLog_ExtParametersLiq.xlsx
set OUTPUT_FILES[6]=	CONVERT		%LOGS_DIR%			ConversionLog_Deposit_Liq.xlsx
set OUTPUT_FILES[7]=	CONVERT		%LOGS_DIR%			ConversionLog_CAB_Liq.xlsx
set OUTPUT_FILES[8]=	CONVERT		%LOGS_DIR%			ConversionLog_Cards_Liq.xlsx
set OUTPUT_FILES[9]=	CONVERT		%LOGS_DIR%			ConversionLog_LiqTreeFiller.xlsx
set OUTPUT_FILES[10]=	CONVERT		%LOGS_DIR%			ConversionLog_BOI.xlsx
set OUTPUT_FILES[11]=	VAR			%REPORTS_DIR%		Market_VAR.xlsx
set OUTPUT_FILES[12]=	VAR			%REPORTS_DIR%		Liquidity_VAR_Scenarios.xlsx
set OUTPUT_FILES[13]=	CF 			%REPORTS_DIR%		CF_LIQUIDITY.xlsx
set OUTPUT_FILES[14]=	CF			%REPORTS_DIR%		CF_LIQUIDITY_FRN.xlsx
set OUTPUT_FILES[15]=	KRD			%REPORTS_DIR%		KRD_LIQUIDITY.xlsx
REM <<< 9 <<<  Output (Conversion Log and Report) File Names


REM >>> 10 >>>  Validate and Exit
REM DON'T EDIT THIS SECTION
if not exist %COMPURISK% (
	echo. FAILED
	call :EchoDateTime & echo `%COMPURISK%` doesn't exist. Check that CompuRisk is installed and that the path is correct.
	exit /b 2
)
if %COMPACT% NEQ 0 (
	if not exist %MSACCESS% (
		echo. FAILED
		call :EchoDateTime & echo `%MSACCESS%` doesn't exist. Check that MS Office ^(w/ Access^) is installed and that the path is correct.
		exit /b 2
	)
)
echo. DONE
call :EchoDateTime & echo Used date is `%YYYYMMDD%` ^(`%DD_MM_YYYY%`^).
exit /b 0
REM <<< 10 <<<  Valide and Exit


:EchoDateTime
REM <<<<<<<<<<<<<<<<<<<<<<<< IMPORTANT >>>>>>>>>>>>>>>>>>>>>>>>
REM Depending on Windows regional format, the formula may need to be changed.
(echo | set /p _=%DATE% %TIME% )
