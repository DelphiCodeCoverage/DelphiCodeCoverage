echo Building Delphi Code Coverage

echo %PATH%


call "SetupEnvironment.Bat"

msbuild  /p:DCC_UnitSearchPath="$(BDS)\lib;$(BDS)\include;%JWAPI%\Win32API;%JWAPI%\Includes;%JWAPI%\Common;%JCL%\source\include;%JCL%\source\common;%JCL%\source\windows;%JVCL%\run;%JVCL%\Common;$(DCC_UnitSearchPath)" /t:build /p:config=Debug /verbosity:detailed "CodeCoverage\Test\CodeCoverageTests.dproj"

