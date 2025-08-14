@echo off
set "JAVA_HOME=C:\Program Files\Java\jdk-17"
set "PATH=%JAVA_HOME%\bin;%PATH%"
echo Java version:
java -version
echo.
echo Testing compilation first...
gradlew.bat compileJava
if %ERRORLEVEL% EQU 0 (
    echo Compilation successful! Starting Spring Boot application...
    gradlew.bat bootRun
) else (
    echo Compilation failed! Check the errors above.
)
pause