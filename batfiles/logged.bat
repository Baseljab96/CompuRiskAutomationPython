@echo off

REM A utility script that allows calling any other script and diverting its messages into a file.

set LOG_FILE=C:\progress.log
set SEP=------------------------------------------------------------------------------------------------------------------------

if "%~1" NEQ "" set LOG_FILE=%~1
shift

if "%~1" == "" (
	echo %SEP%>> "%LOG_FILE%"
	call :EchoDateTime & echo ^>^>^> ERROR: no script was supplied. ^<^<^<>> "%LOG_FILE%"
	echo %SEP%>> "%LOG_FILE%"
	exit /b 1
)

echo %SEP%>> "%LOG_FILE%"
call :EchoDateTime & echo ^>^>^> Started execution of `%1 %2 %3 %4`...>> "%LOG_FILE%"
call %1 %2 %3 %4>> "%LOG_FILE%"
set EXITCODE=%ERRORLEVEL%
call :EchoDateTime & echo ^<^<^< Finished execution of `%1 %2 %3 %4`. Exit code is %EXITCODE%.>> "%LOG_FILE%"
echo %SEP%>> "%LOG_FILE%"

exit /b %EXITCODE%

:EchoDateTime
REM <<<<<<<<<<<<<<<<<<<<<<<< IMPORTANT >>>>>>>>>>>>>>>>>>>>>>>>
REM Depending on Windows regional format, the formula may need to be changed.
(echo | set /p _=%DATE% %TIME% >> "%LOG_FILE%")
