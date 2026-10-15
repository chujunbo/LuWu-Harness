@echo off
setlocal DisableDelayedExpansion
set "ELECTRON_RUN_AS_NODE=1"
rem LWH-LOCAL PATCH (LuWu Harness): resolve the bundle's own executable instead of hardcoding the
rem published product name, so a renamed build keeps a working dsh command. The application root
rem holds exactly one executable: the application binary itself.
set "APP_ROOT=%~dp0..\..\..\.."
set "APP_EXECUTABLE="
for %%F in ("%APP_ROOT%\*.exe") do if not defined APP_EXECUTABLE set "APP_EXECUTABLE=%%~fF"
if not defined APP_EXECUTABLE (
  echo dsh: cannot locate the application executable under %APP_ROOT% 1>&2
  exit /b 1
)
"%APP_EXECUTABLE%" --expose-internals "%~dp0..\..\..\app.asar\dsh\node_modules\@deepseek-ai\dsh-desktop-host\lib\cli.js" %*
exit /b %errorlevel%
