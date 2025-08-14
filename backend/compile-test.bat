@echo off
set "JAVA_HOME=C:\Program Files\Java\jdk-17"
set "PATH=%JAVA_HOME%\bin;%PATH%"
echo Testing Java setup...
java -version
echo.
echo JAVA_HOME: %JAVA_HOME%
echo.
echo Testing Gradle compilation...
gradlew.bat compileJava --info --stacktrace
echo.
echo Compilation test complete.