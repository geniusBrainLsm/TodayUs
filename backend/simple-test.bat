@echo off
cd /d "C:\Program Files\Java\jdk-17\bin"
echo Testing Java compiler...
javac -version
echo.
cd /d "C:\Users\abcd8\IdeaProjects\TodayUs\backend"
echo Testing simple compilation...
"C:\Program Files\Java\jdk-17\bin\javac" -cp . src\main\java\com\todayus\TodayUsApplication.java 2>&1
echo Done.
pause