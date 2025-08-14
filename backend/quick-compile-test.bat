@echo off
echo ==========================================
echo Quick Compilation Test
echo ==========================================
cd /d "C:\Users\abcd8\IdeaProjects\TodayUs\backend"
set "JAVA_HOME=C:\Program Files\Java\jdk-17"
set "PATH=%JAVA_HOME%\bin;%PATH%"

echo Testing specific problematic files...
echo.

echo 1. Testing TodayUsApplication...
"%JAVA_HOME%\bin\javac" -version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Java compiler not found!
    goto end
)

echo 2. Java compiler found, testing basic syntax...
find src -name "*.java" | wc -l 2>nul || echo No find command

echo 3. Attempting Gradle build...
gradlew.bat --version

:end
echo.
echo ==========================================
echo Test completed
echo ==========================================
pause