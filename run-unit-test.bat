@ECHO OFF

ECHO Running unit tests

CALL "SetupEnvironment.bat"
PUSHD %BUILD%

%PRJ%.exe

POPD