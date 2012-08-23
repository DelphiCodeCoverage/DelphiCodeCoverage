@echo off

echo Building Delphi Code Coverage

SET BASEDIR=%CD%

call "SetupEnvironment.Bat"

cd %BASEDIR%\build
mkdir reports > NUL 2>&1
cd reports
mkdir coverage > NUL 2>&1

cd ..


%BASEDIR%\build\CodeCoverage.exe -e %BASEDIR%\build\CodeCoverageTests.exe -m %BASEDIR%\build\CodeCoverageTests.map -ife -xml -html -uf %BASEDIR%\coverage_units.lst -sd %BASEDIR%\CodeCoverage\Test -od %BASEDIR%\build\reports\coverage -dproj %BASEDIR%\CodeCoverage\Test\CodeCoverageTests.dproj -lt %BASEDIR%\build\reports\CodeCoverage.log
