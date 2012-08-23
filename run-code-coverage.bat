@ECHO OFF

ECHO Building Delphi Code Coverage

CALL "SetupEnvironment.bat"

PUSHD %BUILD%

MKDIR reports > NUL 2>&1
PUSHD reports
MKDIR coverage > NUL 2>&1

POPD

%BUILD%\CodeCoverage.exe -e %BUILD%\%PRJ%.exe -m %BUILD%\%PRJ%.map -ife -xml -html -uf %BASEDIR%\coverage_units.lst -sd %PRJDIR% -od %REPORTS%\coverage -dproj %PRJDIR%\%PRJ%.dproj -lt %REPORTS%\CodeCoverage.log

POPD
