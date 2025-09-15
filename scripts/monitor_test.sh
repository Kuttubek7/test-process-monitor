#!/bin/bash

# Путь к лог-файлу
LOG_FILE="/var/log/monitoring.log"

# Проверка существования лог-файла, создание, если отсутствует
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    chmod 664 "$LOG_FILE"  # Права: rw-rw-r--
    sudo chown root:adm "$LOG_FILE"
fi

# Проверка прав на запись в лог-файл
if [ ! -w "$LOG_FILE" ]; then
    echo "Error: Cannot write to $LOG_FILE" >&2
    exit 1
fi

# Функция для записи в лог с временной меткой
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Проверка, существует ли процесс test
if pgrep -x "test" > /dev/null; then
    # Процесс test запущен, выполняем HTTPS-запрос
    response=$(curl -s -o /dev/null -w "%{http_code}" https://test.com/monitoring/test/api 2>/dev/null)
    
    # Проверяем статус ответа
    if [ "$response" != "200" ]; then
        log_message "ERROR: Monitoring server https://test.com/monitoring/test/api is unavailable (HTTP code: $response)"
    fi

    # Проверяем, был ли процесс перезапущен (сравниваем время запуска)
    LAST_PID_FILE="/tmp/test_process.pid"
    CURRENT_PID=$(pgrep -x "test" | head -1)
    
    # Проверка существования и прав на LAST_PID_FILE
    if [ -f "$LAST_PID_FILE" ] && [ ! -w "$LAST_PID_FILE" ]; then
        sudo rm "$LAST_PID_FILE" || { echo "Error: Cannot remove $LAST_PID_FILE" >&2; exit 1; }
    fi

    if [ -f "$LAST_PID_FILE" ]; then
        LAST_PID=$(cat "$LAST_PID_FILE")
        if [ "$CURRENT_PID" != "$LAST_PID" ]; then
            log_message "Process test was restarted (new PID: $CURRENT_PID, old PID: $LAST_PID)"
        fi
    fi

    # Сохраняем текущий PID для следующей проверки
    echo "$CURRENT_PID" > "$LAST_PID_FILE" || { echo "Error: Cannot write to $LAST_PID_FILE" >&2; exit 1; }
else
    # Процесс test не запущен, ничего не делаем
    :
fi
