 @set masver=2.5
@setlocal DisableDelayedExpansion
@echo off

::::
::  For command line switches, check mass grave[.]dev/command_line_switches.html
::  If you want to better understand script, read from MAS separate files version. 


::============================================================================
::
::   This script is a part of 'Microsoft_Activation_Scripts' (MAS) project.
::
::   Homepage: mass grave[.]dev
::      Email: windowsaddict@protonmail.com
::
::============================================================================




::========================================================================================================================================

::  Set Path variable, it helps if it is misconfigured in the system

set "PATH=%SystemRoot%\System32;%SystemRoot%\System32\wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "PATH=%SystemRoot%\Sysnative;%SystemRoot%\Sysnative\wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%PATH%"
)

:: Re-launch the script with x64 process if it was initiated by x86 process on x64 bit Windows
:: or with ARM64 process if it was initiated by x86/ARM32 process on ARM64 Windows

set "_cmdf=%~f0"
for %%# in (%*) do (
if /i "%%#"=="r1" set r1=1
if /i "%%#"=="r2" set r2=1
if /i "%%#"=="-qedit" (
reg add HKCU\Console /v QuickEdit /t REG_DWORD /d "1" /f 1>nul
rem check the code below admin elevation to understand why it's here
)
)

if exist %SystemRoot%\Sysnative\cmd.exe if not defined r1 (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" %* r1"
exit /b
)

:: Re-launch the script with ARM32 process if it was initiated by x64 process on ARM64 Windows

if exist %SystemRoot%\SysArm32\cmd.exe if %PROCESSOR_ARCHITECTURE%==AMD64 if not defined r2 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" %* r2"
exit /b
)

::========================================================================================================================================

set "blank="
set "mas=ht%blank%tps%blank%://mass%blank%grave.dev/"

::  Check if Null service is working, it's important for the batch script

sc query Null | find /i "RUNNING"
if %errorlevel% NEQ 0 (
echo:
echo Null service is not running, script may crash...
echo:
echo:
echo Help - %mas%troubleshoot.html
echo:
echo:
ping 127.0.0.1 -n 10
)
cls

::  Check LF line ending

pushd "%~dp0"
>nul findstr /v "$" "%~nx0" && (
echo:
echo Error: Script either has LF line ending issue or an empty line at the end of the script is missing.
echo:
ping 127.0.0.1 -n 6 >nul
popd
exit /b
)
popd

::========================================================================================================================================

cls
color 07
title  Microsoft_Activation_Scripts %masver%

set _args=
set _elev=
set _MASunattended=

set _args=%*
if defined _args set _args=%_args:"=%
if defined _args (
for %%A in (%_args%) do (
if /i "%%A"=="-el"                    set _elev=1
)
)

if defined _args echo "%_args%" | find /i "/" >nul && set _MASunattended=1

::========================================================================================================================================

set "nul1=1>nul"
set "nul2=2>nul"
set "nul6=2^>nul"
set "nul=>nul 2>&1"

set winbuild=1
set psc=powershell.exe
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G

set _NCS=1
if %winbuild% LSS 10586 set _NCS=0
if %winbuild% GEQ 10586 reg query "HKCU\Console" /v ForceV2 %nul2% | find /i "0x0" %nul1% && (set _NCS=0)

call :_colorprep

set "nceline=echo: &echo ==== ERROR ==== &echo:"
set "eline=echo: &call :_color %Red% "==== ERROR ====" &echo:"

::========================================================================================================================================

if %winbuild% LSS 7600 (
%nceline%
echo Unsupported OS version detected [%winbuild%].
echo Project is supported only for Windows 7/8/8.1/10/11 and their Server equivalent.
goto MASend
)

for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" (
%nceline%
echo Unable to find powershell.exe in the system.
echo Aborting...
goto MASend
)

::========================================================================================================================================

::  Fix for the special characters limitation in path name

set "_work=%~dp0"
if "%_work:~-1%"=="\" set "_work=%_work:~0,-1%"

set "_batf=%~f0"
set "_batp=%_batf:'=''%"

set _PSarg="""%~f0""" -el %_args%

set "_ttemp=%userprofile%\AppData\Local\Temp"

setlocal EnableDelayedExpansion

::========================================================================================================================================

echo "!_batf!" | find /i "!_ttemp!" %nul1% && (
if /i not "!_work!"=="!_ttemp!" (
%nceline%
echo Script is launched from the temp folder,
echo Most likely you are running the script directly from the archive file.
echo:
echo Extract the archive file and launch the script from the extracted folder.
goto MASend
)
)

::========================================================================================================================================

::  Elevate script as admin and pass arguments and preventing loop

%nul1% fltmc || (
if not defined _elev %psc% "start cmd.exe -arg '/c \"!_PSarg:'=''!\"' -verb runas" && exit /b
%nceline%
echo This script requires admin privileges.
echo To do so, right click on this script and select 'Run as administrator'.
goto MASend
)

if not exist "%SystemRoot%\Temp\" mkdir "%SystemRoot%\Temp" %nul%

::========================================================================================================================================

::  This code disables QuickEdit for this cmd.exe session only without making permanent changes to the registry
::  It is added because clicking on the script window pauses the operation and leads to the confusion that script stopped due to an error

if defined _MASunattended set quedit=1
for %%# in (%_args%) do (if /i "%%#"=="-qedit" set quedit=1)

reg query HKCU\Console /v QuickEdit %nul2% | find /i "0x0" %nul1% || if not defined quedit (
reg add HKCU\Console /v QuickEdit /t REG_DWORD /d "0" /f %nul1%
start cmd.exe /c ""!_batf!" %_args% -qedit"
rem quickedit reset code is added at the starting of the script instead of here because it takes time to reflect in some cases
exit /b
)

::========================================================================================================================================

::  Check for updates

set -=
set old=

for /f "delims=[] tokens=2" %%# in ('ping -4 -n 1 updatecheck.mass%-%grave.dev') do (
if not [%%#]==[] (echo "%%#" | find "127.69" %nul1% && (echo "%%#" | find "127.69.%masver%" %nul1% || set old=1))
)

if defined old (
echo ________________________________________________
%eline%
echo You are running outdated version MAS %masver%
echo ________________________________________________
echo:
if not defined _MASunattended (
echo [1] Get Latest MAS
echo [0] Continue Anyway
echo:
call :_color %_Green% "Enter a menu option in the Keyboard [1,0] :"
choice /C:10 /N
if !errorlevel!==2 rem
if !errorlevel!==1 (start ht%-%tps://github.com/mass%-%gravel/Microsoft-Acti%-%vation-Scripts & start %mas% & exit /b)
)
)
cls

::========================================================================================================================================

::  Run script with parameters in unattended mode

set _elev=
if defined _args echo "%_args%" | find /i "/S" %nul% && (set "_silent=%nul%") || (set _silent=)
if defined _args echo "%_args%" | find /i "/" %nul% && (
echo "%_args%" | find /i "/HWID"   %nul% && (setlocal & cls & (call :HWIDActivation   %_args% %_silent%) & endlocal)
echo "%_args%" | find /i "/KMS38"  %nul% && (setlocal & cls & (call :KMS38Activation  %_args% %_silent%) & endlocal)
echo "%_args%" | find /i "/KMS-"   %nul% && (setlocal & cls & (call :KMSActivation    %_args% %_silent%) & endlocal)
echo "%_args%" | find /i "/Ohook"  %nul% && (setlocal & cls & (call :OhookActivation  %_args% %_silent%) & endlocal)
exit /b
)

::========================================================================================================================================

setlocal DisableDelayedExpansion

::  Check desktop location

set _desktop_=
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_desktop_=%%b"
if not defined _desktop_ for /f "delims=" %%a in ('%psc% "& {write-host $([Environment]::GetFolderPath('Desktop'))}"') do call set "_desktop_=%%a"

setlocal EnableDelayedExpansion

::========================================================================================================================================

:MainMenu

cls
color 07
title  Microsoft_Activation_Scripts %masver%
mode 76, 30

echo:
echo:
echo:
echo:
echo:       ______________________________________________________________
echo:
echo:                 Activation Methods:
echo:
echo:             [1] HWID        ^|  Windows           ^|   Permanent
echo:             [2] Ohook       ^|  Office            ^|   Permanent
echo:             [3] KMS38       ^|  Windows           ^|   Year 2038
echo:             [4] Online KMS  ^|  Windows / Office  ^|    180 Days
echo:             __________________________________________________      
echo:
echo:             [5] Activation Status
echo:             [6] Troubleshoot
echo:             [7] Extras
echo:             [8] Help
echo:             [0] Exit
echo:       ______________________________________________________________
echo:
call :_color2 %_White% "          " %_Green% "Enter a menu option in the Keyboard [1,2,3,4,5,6,7,8,0] :"
choice /C:123456780 /N
set _erl=%errorlevel%

if %_erl%==9 exit /b
if %_erl%==8 start %mas%troubleshoot.html & goto :MainMenu
if %_erl%==7 goto:Extras
if %_erl%==6 setlocal & call :troubleshoot      & cls & endlocal & goto :MainMenu
if %_erl%==5 setlocal & call :_Check_Status_wmi & cls & endlocal & goto :MainMenu
if %_erl%==4 setlocal & call :KMSActivation     & cls & endlocal & goto :MainMenu
if %_erl%==3 setlocal & call :KMS38Activation   & cls & endlocal & goto :MainMenu
if %_erl%==2 setlocal & call :OhookActivation   & cls & endlocal & goto :MainMenu
if %_erl%==1 setlocal & call :HWIDActivation    & cls & endlocal & goto :MainMenu
goto :MainMenu

::========================================================================================================================================

:Extras

cls
title  Extras
mode 76, 30
echo:
echo:
echo:
echo:
echo:
echo:       ______________________________________________________________
echo:
echo:             [1] Change Windows Edition
echo:
echo:             [2] Extract $OEM$ Folder
echo:
echo:             [3] Activation Status [vbs]
echo:
echo:             [4] Download Genuine Windows / Office
echo:             __________________________________________________      
echo:                                                                     
echo:             [0] Go to Main Menu
echo:       ______________________________________________________________
echo:
call :_color2 %_White% "           " %_Green% "Enter a menu option in the Keyboard [1,2,3,4,0] :"
choice /C:12340 /N
set _erl=%errorlevel%

if %_erl%==5 goto :MainMenu
if %_erl%==4 start %mas%genuine-installation-media.html & goto :Extras
if %_erl%==3 setlocal & call :_Check_Status_vbs & cls & endlocal & goto :Extras
if %_erl%==2 goto:Extract$OEM$
if %_erl%==1 setlocal & call :change_edition    & cls & endlocal & goto :Extras
goto :Extras

::========================================================================================================================================

:Extract$OEM$

cls
title  Extract $OEM$ Folder
mode 76, 30

if not exist "!_desktop_!\" (
%eline%
echo Desktop location was not detected, aborting...
echo _____________________________________________________
echo:
call :_color %_Yellow% "Press any key to go back..."
pause >nul
goto Extras
)

if exist "!_desktop_!\$OEM$\" (
%eline%
echo $OEM$ folder already exists on the Desktop.
echo _____________________________________________________
echo:
call :_color %_Yellow% "Press any key to go back..."
pause >nul
goto Extras
)

:Extract$OEM$2

cls
title  Extract $OEM$ Folder
mode 78, 30
echo:
echo:
echo:
echo:
echo:                     Extract $OEM$ folder on the desktop           
echo:           ________________________________________________________
echo:
echo:              [1] HWID
echo:              [2] Ohook
echo:              [3] KMS38
echo:              [4] Online KMS
echo:
echo:              [5] HWID       ^(Windows^) ^+ Ohook      ^(Office^)
echo:              [6] HWID       ^(Windows^) ^+ Online KMS ^(Office^)
echo:              [7] KMS38      ^(Windows^) ^+ Ohook      ^(Office^)
echo:              [8] KMS38      ^(Windows^) ^+ Online KMS ^(Office^)
echo:              [9] Online KMS ^(Windows^) ^+ Ohook      ^(Office^)
echo:
call :_color2 %_White% "              [R] " %_Green% "ReadMe"
echo:              [0] Go Back
echo:           ________________________________________________________
echo:  
call :_color2 %_White% "           " %_Green% "Enter a menu option in the Keyboard:"
choice /C:123456789R0 /N
set _erl=%errorlevel%

if %_erl%==11 goto:Extras
if %_erl%==10 start %mas%oem-folder.html &goto:Extract$OEM$2
if %_erl%==9 (set "_oem=Online KMS [Windows] + Ohook [Office]" & set "para=/KMS-ActAndRenewalTask /KMS-Windows /Ohook" &goto:Extract$OEM$3)
if %_erl%==8 (set "_oem=KMS38 [Windows] + Online KMS [Office]" & set "para=/KMS38 /KMS-ActAndRenewalTask /KMS-Office" &goto:Extract$OEM$3)
if %_erl%==7 (set "_oem=KMS38 [Windows] + Ohook [Office]" & set "para=/KMS38 /Ohook" &goto:Extract$OEM$3)
if %_erl%==6 (set "_oem=HWID [Windows] + Online KMS [Office]" & set "para=/HWID /KMS-ActAndRenewalTask /KMS-Office" &goto:Extract$OEM$3)
if %_erl%==5 (set "_oem=HWID [Windows] + Ohook [Office]" & set "para=/HWID /Ohook" &goto:Extract$OEM$3)
if %_erl%==4 (set "_oem=Online KMS" & set "para=/KMS-ActAndRenewalTask /KMS-WindowsOffice" &goto:Extract$OEM$3)
if %_erl%==3 (set "_oem=KMS38" & set "para=/KMS38" &goto:Extract$OEM$3)
if %_erl%==2 (set "_oem=Ohook" & set "para=/Ohook" &goto:Extract$OEM$3)
if %_erl%==1 (set "_oem=HWID" & set "para=/HWID" &goto:Extract$OEM$3)
goto :Extract$OEM$2

::========================================================================================================================================

:Extract$OEM$3

cls
set "_dir=!_desktop_!\$OEM$\$$\Setup\Scripts"
md "!_dir!\"
copy /y /b "!_batf!" "!_dir!\MAS_AIO.cmd" %nul%

(
echo @echo off
echo fltmc ^>nul ^|^| exit /b
echo call "%%~dp0MAS_AIO.cmd" %para%
echo cd \
echo ^(goto^) 2^>nul ^& ^(if "%%~dp0"=="%%SystemRoot%%\Setup\Scripts\" rd /s /q "%%~dp0"^)
)>"!_dir!\SetupComplete.cmd"

set _error=
if not exist "!_dir!\MAS_AIO.cmd" set _error=1
if not exist "!_dir!\SetupComplete.cmd" set _error=1

if defined _error (
%eline%
echo Failed to extract $OEM$ folder on the Desktop.
) else (
echo:
call :_color %Blue% "%_oem%"
call :_color %Green% "$OEM$ folder is successfully created on the Desktop."
)
echo "%_oem%" | find /i "KMS38" 1>nul && (
echo:
echo To KMS38 activate Server Cor/Acor editions ^(No GUI Versions^),
echo Check this page %mas%oem-folder
)
echo ___________________________________________________________________
echo:
call :_color %_Yellow% "Press any key to go back..."
pause >nul
goto Extras

:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

:HWIDActivation
@setlocal DisableDelayedExpansion
@echo off

::  To activate, run the script with "/HWID" parameter or change 0 to 1 in below line
set _act=0

::  To disable changing edition if current edition doesn't support HWID activation, change the value to 1 from 0 or run the script with "/HWID-NoEditionChange" parameter
set _NoEditionChange=0

::  If value is changed in above lines or parameter is used then script will run in unattended mode

::========================================================================================================================================

cls
color 07
title  HWID Activation %masver%

set _args=
set _elev=
set _unattended=0

set _args=%*
if defined _args set _args=%_args:"=%
if defined _args (
for %%A in (%_args%) do (
if /i "%%A"=="/HWID"                  set _act=1
if /i "%%A"=="/HWID-NoEditionChange"  set _NoEditionChange=1
if /i "%%A"=="-el"                    set _elev=1
)
)

for %%A in (%_act% %_NoEditionChange%) do (if "%%A"=="1" set _unattended=1)

::========================================================================================================================================

set "nul1=1>nul"
set "nul2=2>nul"
set "nul6=2^>nul"
set "nul=>nul 2>&1"

set psc=powershell.exe
set winbuild=1
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G

set _NCS=1
if %winbuild% LSS 10586 set _NCS=0
if %winbuild% GEQ 10586 reg query "HKCU\Console" /v ForceV2 %nul2% | find /i "0x0" %nul1% && (set _NCS=0)

if %_NCS% EQU 1 (
for /F %%a in ('echo prompt $E ^| cmd') do set "esc=%%a"
set     "Red="41;97m""
set    "Gray="100;97m""
set   "Green="42;97m""
set    "Blue="44;97m""
set  "_White="40;37m""
set  "_Green="40;92m""
set "_Yellow="40;93m""
) else (
set     "Red="Red" "white""
set    "Gray="Darkgray" "white""
set   "Green="DarkGreen" "white""
set    "Blue="Blue" "white""
set  "_White="Black" "Gray""
set  "_Green="Black" "Green""
set "_Yellow="Black" "Yellow""
)

set "nceline=echo: &echo ==== ERROR ==== &echo:"
set "eline=echo: &call :dk_color %Red% "==== ERROR ====" &echo:"
if %~z0 GEQ 200000 (
set "_exitmsg=Go back"
set "_fixmsg=Go back to Main Menu, select Troubleshoot and run Fix Licensing option."
) else (
set "_exitmsg=Exit"
set "_fixmsg=In MAS folder, run Troubleshoot script and select Fix Licensing option."
)

::========================================================================================================================================

if %winbuild% LSS 10240 (
%eline%
echo Unsupported OS version detected [%winbuild%].
echo HWID Activation is supported only for Windows 10/11.
echo Use Online KMS Activation option.
goto dk_done
)

if exist "%SystemRoot%\Servicing\Packages\Microsoft-Windows-Server*Edition~*.mum" (
%eline%
echo HWID Activation is not supported for Windows Server.
echo Use KMS38 or Online KMS Activation option.
goto dk_done
)

::========================================================================================================================================

::  Fix for the special characters limitation in path name

set "_work=%~dp0"
if "%_work:~-1%"=="\" set "_work=%_work:~0,-1%"

set "_batf=%~f0"
set "_batp=%_batf:'=''%"

set _PSarg="""%~f0""" -el %_args%

set "_ttemp=%userprofile%\AppData\Local\Temp"

setlocal EnableDelayedExpansion

::========================================================================================================================================

cls
mode 110, 34
if exist "%Systemdrive%\Windows\System32\spp\store_test\" mode 134, 34
title  HWID Activation %masver%

echo:
echo Initializing...

::  Check PowerShell

%psc% $ExecutionContext.SessionState.LanguageMode %nul2% | find /i "Full" %nul1% || (
%eline%
%psc% $ExecutionContext.SessionState.LanguageMode
echo:
echo PowerShell is not working. Aborting...
echo If you have applied restrictions on Powershell then undo those changes.
echo:
echo Check this page for help. %mas%troubleshoot
goto dk_done
)

::========================================================================================================================================

call :dk_product
call :dk_ckeckwmic

::  Show info for potential script stuck scenario

sc start sppsvc %nul%
if %errorlevel% NEQ 1056 if %errorlevel% NEQ 0 (
echo:
echo Error code: %errorlevel%
call :dk_color %Red% "Failed to start 
