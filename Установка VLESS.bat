@echo off
chcp 65001 > nul
cls
echo *******************************************************
echo *         Настройка VPS с полным циклом операций       *
echo *******************************************************
echo.

:: Проверка прав администратора
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ОШИБКА: Скрипт должен быть запущен от имени Администратора!
    pause
    exit /b
)

:: 0. Копирование папки VPS в корень диска C:\
echo [0/6] Копирование папки VPS в C:\...

:: Проверка исходной папки
if not exist "%~dp0VPS" (
    echo ОШИБКА: Папка VPS не найдена рядом со скриптом
    echo Расположение скрипта: %~dp0
    dir "%~dp0"
    pause
    exit /b
)

:: Проверка существующей папки
if exist "C:\VPS" (
    echo ВНИМАНИЕ: Папка C:\VPS уже существует
    choice /C YN /M "Удалить и перезаписать"
    if errorlevel 2 (
        echo Отменено пользователем
        pause
        exit /b
    )
    echo Удаляю старую папку...
    rmdir "C:\VPS" /S /Q
)

:: Копирование
echo Копирую VPS в C:\...
xcopy "%~dp0VPS" "C:\VPS\" /E /H /C /I /Y
if errorlevel 1 (
    echo ОШИБКА копирования!
    echo Проверьте:
    echo - Доступ к диску C:\
    echo - Права администратора
    echo - Свободное место
    pause
    exit /b
)

echo УСПЕХ: Папка скопирована в C:\VPS

:: Улучшенная проверка IP-адреса
:input_ip
echo.
set /p server_ip="Введите IP-адрес вашего сервера: "
if "%server_ip%"=="" (
    echo ОШИБКА: IP-адрес не может быть пустым!
    goto input_ip
)

:: Проверка с помощью PowerShell для надежности
echo Проверка IP-адреса...
powershell -command "$ip = '%server_ip%'; if (-not ($ip -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$')) { exit 1 }; $octets = $ip -split '\.'; foreach ($octet in $octets) { if ([int]$octet -gt 255) { exit 1 } }"
if %errorlevel% neq 0 (
    echo ОШИБКА: Неверный формат IP-адреса! Пример: 192.168.1.1
    goto input_ip
)

:: 1. Проверка и установка обновлений на сервере
echo.
echo [1/6] Проверка и установка обновлений на сервере...
echo.
ssh root@%server_ip% "export LANG=ru_RU.UTF-8; apt-get update && apt-get dist-upgrade -y && apt-get autoremove -y"
if errorlevel 1 (
    echo.
    echo ВНИМАНИЕ: Ошибка при обновлении сервера!
    echo ------------------------------------------
    echo.
    choice /C YN /M "Пропустить обновление и продолжить (Y) или прервать (N)"
    if errorlevel 2 (
        exit /b
    ) else (
        goto :continue_script
    )
)
:continue_script

:: 2. Копирование файлов на сервер
echo.
echo [2/6] Копирование файлов на сервер...
cd /D C:\VPS
scp -p Install_VLESS.sh config.json profile.txt root@%server_ip%:/root/
if errorlevel 1 (
    echo ОШИБКА при копировании файлов на сервер!
    pause
    exit /b
)

:: 3. Запуск скрипта на сервере
echo.
echo [3/6] Запуск скрипта на сервере...
ssh root@%server_ip% "export LANG=ru_RU.UTF-8; chmod 755 /root/Install_VLESS.sh && ./Install_VLESS.sh"
if errorlevel 1 (
    echo ОШИБКА при выполнении скрипта на сервере!
    pause
    exit /b
)

:: 4. Копирование профиля обратно на компьютер
echo.
echo [4/6] Копирование профиля на локальный компьютер...
if not exist "C:\VPS\Hiddify\" mkdir "C:\VPS\Hiddify"
scp -p root@%server_ip%:/root/profile.txt C:\VPS\Hiddify\
if errorlevel 1 (
    echo ОШИБКА при копировании профиля!
    pause
    exit /b
)

:: 5. Открытие профиля для копирования
echo.
echo [5/6] Открытие профиля для копирования в Hiddify...
start notepad C:\VPS\Hiddify\profile.txt

:: 6. Опциональная перезагрузка сервера
echo.
echo [6/6] Хотите перезагрузить сервер для применения обновлений? (y/n)
set /p reboot="> "
if /i "%reboot%"=="y" (
    ssh root@%server_ip% "reboot now"
    echo Сервер перезагружается...
)

echo.
echo ===================================================
echo Готово! Основные операции выполнены:
echo 1. Папка VPS скопирована в C:\
echo 2. Сервер обновлен
echo 3. Файлы переданы на сервер
echo 4. Скрипт установки выполнен
echo 5. Профиль скопирован обратно
echo 6. Открыт для копирования в Hiddify
echo ===================================================
pause