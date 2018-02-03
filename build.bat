echo Building Delphi Code Coverage

call SetupEnvironment.bat

msbuild /p:Platform=Win32 /t:build /p:config=Release /verbosity:detailed "Source\CodeCoverage.dproj"