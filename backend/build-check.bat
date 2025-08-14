@echo off
set "JAVA_HOME=C:\Program Files\Java\jdk-17"
set "PATH=%JAVA_HOME%\bin;%PATH%"

echo ========================================
echo Starting iterative build error fixing
echo ========================================
echo.

gradlew.bat clean compileJava --no-daemon --console=plain 2>&1

echo.
echo ========================================
echo Build check complete
echo ========================================