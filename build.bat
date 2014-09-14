echo Building Delphi Code Coverage

call SetupEnvironment.bat

msbuild /p:Platform=Win32 /p:DCC_UnitSearchPath="$(BDS)\lib;$(BDS)\include;%LIBS%;%JWAPI%\Win32API;%JWAPI%\Common;%JCL%\source\include;%JCL%\source\common;%JCL%\source\windows;%JVCL%\run;%JVCL%\Common;$(DCC_UnitSearchPath)" /t:build /p:config=Release /verbosity:detailed "CodeCoverage\CodeCoverage.dproj"