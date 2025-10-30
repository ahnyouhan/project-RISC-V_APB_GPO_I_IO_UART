@echo off
:: 한글 깨짐 방지
chcp 65001 >nul

:: 커밋 메시지 입력
set /p msg="commit message: "

:: 특정 확장자만 하위폴더 포함해서 add
for /R ".\CODE" %%f in (*.c *.cpp *.v *.sv *.xdc *.mem ) do git add "%%f"

:: 커밋
git commit -m "%msg%"

:: 푸시
git push

pause