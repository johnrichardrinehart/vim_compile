@ECHO off
REM Next line ensures that global variables are assigned values properly
SETLOCAL EnableDelayedExpansion
SET PYTHONDIR=C:/Python27
Set LUADIR=C:/Lua

REM ------- Feel free to change the environment variables defined below.  ---------
REM STARTTIME records the start time of the script
SET STARTTIME=%TIME: =0%

REM Get the current directory for later
SET CURDIR=%cd%

REM WORKDIR records the directory in which this batch file exists. Note that
REM $WORKDIR% includes a trailing slash
SET WORKDIR=%~dp0

REM VIMDIR records the location of the vim/ repository relative to the working
REM directory.
SET VIMDIR=%WORKDIR%vim
SET VIMSRC=%VIMDIR%\src

REM LOGFILE records the location of the compilation log file specified relative to the
REM working directory.
SET LOGFILE="%WORKDIR%batch.log"

REM INSTALLDIR records the location of the installation directory. All runtime
REM files and compiled files will be placed in this directory.
SET INSTALLDIR="C:\Program Files (x86)\vim"
REM ----------- Don't change anything below this line -------------

REM Check for existence of files, clearing them if necessary
COPY /Y NUL %LOGFILE%>NUL
COPY /Y NUL "%WORKDIR%gvim_build.log">NUL
COPY /Y NUL "%WORKDIR%vim_build.log">NUL
COPY /Y NUL "%WORKDIR%vimrun_build.log">NUL
REM Copy Make_ming.mak and Make_cyg_ming.mak to working directory.
COPY /Y "%VIMDIR%"\src\Make_cyg_ming.mak Make_cyg_ming_copy.mak>NUL
COPY /Y "%VIMDIR%"\src\Make_ming.mak Make_ming_copy.mak>NUL
REM Count lines in Make_ming_copy.mak
CALL:CountLines
REM Only include the first N-1 lines
SET /A LINES=LINES-1
Call:PrintFirstNLines>Make_ming.mak
REM Append Make_cyg_min.mak to Make_ming.mak
TYPE Make_cyg_ming_copy.mak>>Make_ming.mak
REM Don't need the copies, anymore
DEL Make_ming_copy.mak Make_cyg_ming_copy.mak

IF NOT EXIST "%WORKDIR%make_ming.mak" (
ECHO Error: "%WORKDIR%make_ming.mak" is not present. Check to make sure you have configured make_ming.mak >> %LOGFILE% 
) ELSE (
ECHO Copying "%WORKDIR%Make_ming.mak" to "%VIMDIR%\src\make_ming.mak" >> %LOGFILE%
COPY "%WORKDIR%Make_ming.mak" "%VIMDIR%\src\make_ming.mak">NUL
REM Removing Make_ming.mak because we no longer need it
)

REM Record the start time
ECHO Started at %STARTTIME% >> %LOGFILE%

SET /A STARTTIME=(1%STARTTIME:~0,2%-100)*360000 + (1%STARTTIME:~3,2%-100)*6000 + (1%STARTTIME:~6,2%-100)*100 + (1%STARTTIME:~9,2%-100)

ECHO Work directory: "%WORKDIR%" >> %LOGFILE%
ECHO Vim repository directory: "%VIMDIR%" >> %LOGFILE%
ECHO Vim target (install) directory: %INSTALLDIR% >> %LOGFILE%

REM Update Vim
ECHO Grabbing the latest commit from the Git repository >> %LOGFILE%

CD "%VIMDIR%\src"
git fetch >> %LOGFILE% 2>&1
git pull >> %LOGFILE% 2>&1
git reset --hard HEAD

REM --- Build GUI version (gvim.exe) ---
ECHO.>>%LOGFILE%
ECHO .......... Building gvim.exe (see gvim_build.log).......... >> %LOGFILE%
ECHO.>>%LOGFILE%
mingw32-make.exe -d -f "%WORKDIR%Make_ming.mak" GUI=yes gvim.exe >> "%WORKDIR%gvim_build.log"

REM --- Build console version (vim.exe) ---
ECHO .......... Building vim.exe (see vim_build.log) .......... >> %LOGFILE%
ECHO.>>%LOGFILE%
mingw32-make.exe -d -f "%WORKDIR%Make_ming.mak" GUI=no vim.exe >> "%WORKDIR%vim_build.log"

ECHO .......... Building install.exe (see vimrun_build.log) .......... >> %LOGFILE%
ECHO.>>%LOGFILE%
mingw32-make.exe -f "%WORKDIR%Make_ming.mak" install.exe >> "%WORKDIR%vim_build.log"

ECHO .......... Building vimrun.exe (see vimrun_build.log) .......... >> %LOGFILE%
ECHO.>>%LOGFILE%
gcc vimrun.c -o vimrun.exe >> "%WORKDIR%vimrun_build.log"

ECHO Moving compiled files. >> %LOGFILE%
COPY /Y /D gvim.exe %INSTALLDIR%
COPY /Y /D vim.exe %INSTALLDIR%
COPY /Y /D install.exe %INSTALLDIR%
COPY /Y /D vimrun.exe %INSTALLDIR%
XCOPY /Y /S /D /Q  ..\runtime %INSTALLDIR%
ECHO Deleting local Make_ming.mak file. >> %LOGFILE%
DEL "%WORKDIR%Make_ming.mak

ECHO Cleaning Vim source directory. >> %LOGFILE%
REM NOTE: "mingw32-make.exe -f Make_ming.mak clean" does not finish the job

IF NOT "%CD%"=="%VIMSRC%" GOTO THEEND
IF NOT EXIST vim.h GOTO THEEND
IF EXIST pathdef.c DEL pathdef.c
IF EXIST obj\NUL      RMDIR /S /Q obj
IF EXIST obji386\NUL  RMDIR /S /Q obji386
IF EXIST gobj\NUL     RMDIR /S /Q gobj
IF EXIST gobji386\NUL RMDIR /S /Q gobji386
If EXIST gobjx86-64\NUL RMDIR /S /Q gobjx86-64
If EXIST objx86-64\NUL RMDIR /S /Q objx86-64
IF EXIST gvim.exe DEL gvim.exe
IF EXIST vim.exe DEL vim.exe
IF EXIST install.exe DEL install.exe
IF EXIST vimrun.exe DEL vimrun.exe
:THEEND

REM Cleaning up the file endings for the batch log file
TYPE %LOGFILE% | MORE /P > "%WORKDIR%log.tmp"
COPY /Y "%WORKDIR%log.tmp" %LOGFILE%
DEL "%WORKDIR%log.tmp"

REM Get end time
SET ENDTIME=%TIME: =0%
ECHO Completed at %ENDTIME% >> %LOGFILE%
SET /A ENDTIME=(1%ENDTIME:~0,2%-100)*360000 + (1%ENDTIME:~3,2%-100)*6000 + (1%ENDTIME:~6,2%-100)*100 + (1%ENDTIME:~9,2%-100)
SET /A TIMETAKEN=(%ENDTIME%-%STARTTIME%)/100
ECHO Took %TIMETAKEN% seconds to complete compiling^.>>%LOGFILE%
CD "%CURDIR%"

GOTO :EOF

:CountLines
SET LINES=0
FOR /F "delims==" %%I in (Make_ming_copy.mak) do (
SET /A LINES=LINES+1    
)
EXIT /B

:PrintFirstNLines
SET CUR=0
FOR /F "tokens=*" %%I in (Make_ming_copy.mak) do (      
ECHO %%I        
SET /A CUR=CUR+1    
IF "!cur!"=="%LINES%" (
   ECHO PYTHON=%PYTHONDIR%
   ECHO LUA=%LUADIR%
   GOTO :BREAK
   )
) 
:BREAK
EXIT /B

:EOF
