echo Building Delphi Code Coverage

echo %PATH%


call "SetupEnvironment.Bat"

mkdir reports
cd reports
mkdir coverage
cd..

build\CodeCoverage.exe -e build\CodeCoverageTests.exe -m build\CodeCoverageTests.map -u CoverageConfiguration -sd CodeCoverage\Test -od reports\coverage -lt -emma