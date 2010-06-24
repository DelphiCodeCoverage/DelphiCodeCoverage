echo Building Delphi Code Coverage

echo %PATH%


call "SetupEnvironment.Bat"

msbuild  /p:Win32LibraryPath="$(BDS)\lib;$(BDS)\include;C:\Users\christer\Downloads\jedi_api22a_jwscl092a\jwapi2.2a\Win32API;C:\Users\christer\Downloads\jedi_api22a_jwscl092a\jwapi2.2a\Common;C:\lib\jcl\jcl\source\include;C:\lib\jcl\jcl\lib\d14;" /t:build /p:config=Debug /verbosity:detailed "CodeCoverage\CodeCoverage.dproj"

