@echo OFF
setlocal ENABLEDELAYEDEXPANSION

set up=%1
if "%up%" NEQ "" goto :numentered

cd ..
goto :exit2 


:numentered
rem echo "NumEntered"
set /a upnum = %1
if %upnum% LEQ 0 goto :exit1
:process
rem echo "Process"
pushd ..	
set /a upnum = %upnum% - 1
if %upnum% GTR 0 ( 
	goto :process 
) ELSE ( goto :exit1 )

:exit2

:exit1
rem echo "Exit"
pushd .
endlocal
popd
