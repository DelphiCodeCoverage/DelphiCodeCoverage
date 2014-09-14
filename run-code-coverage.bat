@ECHO OFF

ECHO Running Delphi Code Coverage

CALL "SetupEnvironment.bat"

PUSHD %BUILD%

MKDIR reports > NUL 2>&1
PUSHD reports
MKDIR coverage > NUL 2>&1

POPD

set Platform=Win32

%BUILD%\%Platform%\CodeCoverage.exe -e %BUILD%\%Platform%\%PRJ%.exe -m %BUILD%\%Platform%\%PRJ%.map -ife -xml -html -uf %BASEDIR%\coverage_units.lst -sd %PRJDIR% -od %REPORTS%\coverage -dproj %PRJDIR%\%PRJ%.dproj -lt %REPORTS%\CodeCoverage.log

POPD
