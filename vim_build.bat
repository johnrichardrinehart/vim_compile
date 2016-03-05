@ECHO off

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
ECHO %VIMDIR%\src
COPY /Y "%VIMDIR%"\src\Make_cyg_ming.mak .
COPY /Y "%VIMDIR%"\src\Make_ming.mak Make_ming_copy.mak
REM Remove the last line of Make_ming.mak (include Make_cyg_ming.mak)
CALL:CountLines
ECHO Total lines in Make_ming.mak : %LINES%
GOTO EOF
REM IF NOT EXIST "%WORKDIR%make_ming.mak" (
REM ECHO Error: "%WORKDIR%make_ming.mak" is not present. Check to make sure you have configured make_ming.mak >> %LOGFILE% 
REM ) ELSE (
REM ECHO Copying "%WORKDIR%Make_ming.mak" to "%VIMDIR%\src\make_ming.mak" >> %LOGFILE%
REM COPY "%WORKDIR%Make_ming.mak" "%VIMDIR%\src\make_ming.mak">NUL
REM )

REM Record the start time
ECHO Started at %STARTTIME% >> %LOGFILE%

SET /A STARTTIME=(1%STARTTIME:~0,2%-100)*360000 + (1%STARTTIME:~3,2%-100)*6000 + (1%STARTTIME:~6,2%-100)*100 + (1%STARTTIME:~9,2%-100)

ECHO Work directory: "%WORKDIR%" >> %LOGFILE%
ECHO Vim repository directory: "%VIMDIR%" >> %LOGFILE%
ECHO Vim target (install) directory: %INSTALLDIR% >> %LOGFILE%

REM Update Vim
ECHO Grabbing the latest commit from the Git repository >> %LOGFILE%

CD "%VIMDIR%\src"
git pull origin master >> %LOGFILE% 2>&1

REM --- Build GUI version (gvim.exe) ---
ECHO.>>%LOGFILE%
ECHO .......... Building gvim.exe (see gvim_build.log).......... >> %LOGFILE%
ECHO.>>%LOGFILE%
mingw32-make.exe -d -f "%WORKDIR%Make_ming.mak" GUI=yes gvim.exe >> "%WORKDIR%gvim_build.log"

REM --- Build console version (vim.exe) ---
ECHO .......... Building vim.exe (see vim_build.log) .......... >> %LOGFILE%
ECHO.>>%LOGFILE%
mingw32-make.exe -d -f "%WORKDIR%Make_ming.mak" GUI=no vim.exe >> "%WORKDIR%vim_build.log"

ECHO .......... Building vimrun.exe (see vimrun_build.log) .......... >> %LOGFILE%
ECHO.>>%LOGFILE%
gcc vimrun.c -o vimrun.exe >> "%WORKDIR%vimrun_build.log"

ECHO Moving compiled files. >> %LOGFILE%
COPY /Y /D gvim.exe %INSTALLDIR%
COPY /Y /D vim.exe %INSTALLDIR%
COPY /Y /D vimrun.exe %INSTALLDIR%
XCOPY /Y /S /D /Q  ..\runtime %INSTALLDIR%

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

:CountLines
setlocal EnableDelayedExpansion
set LINES=0
for /f "delims==" %%I in (Make_ming_copy.mak) do (
set /a LINES=LINES+1    
)

:PrintFirstNLine
set cur=0
for /f "delims==" %%I in (Make_ming_copy.mak) do (      
echo %%I        
::echo !cur! : %%I      
set /a cur=cur+1    
if "!cur!"=="%LINES%" goto EOF
) 

:EOF
