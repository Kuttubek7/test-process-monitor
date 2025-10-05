#!/bin/bash

# Путь к лог-файлу
LOG_FILE="/var/log/monitoring.log"

# Проверка существования лог-файла. если файл отсутствует то созадет
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    chmod 664 "$LOG_FILE"  # дает права на исполняемый файл
    sudo chown root:adm "$LOG_FILE"
fi

# проверка прав на запись в лог-файл
if [ ! -w "$LOG_FILE" ]; then
    echo "Error: Cannot write to $LOG_FILE" >&2
    exit 1
fi

# функция для записи в лог с временной меткой
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# проверяю существует ли процесс test
if pgrep -x "test" > /dev/null; then
    # если процесс запущен то отправляем запрос. на деле я запустил процесс test (http) а также процесс тест через nginx (https)
    response=$(curl -s -o /dev/null -w "%{http_code}" https://test.com/monitoring/test/api 2>/dev/null)
    
    # проверяем статус ответа
    if [ "$response" != "200" ]; then
        log_message "ERROR: Monitoring server https://test.com/monitoring/test/api is unavailable (HTTP code: $response)"
    fi

    # проверка, был ли процес перезапущен а также сравниваю PID процесса
    LAST_PID_FILE="/tmp/test_process.pid"
    CURRENT_PID=$(pgrep -x "test" | head -1)
    
    # проверка существования и прав на PID
    if [ -f "$LAST_PID_FILE" ] && [ ! -w "$LAST_PID_FILE" ]; then
        sudo rm "$LAST_PID_FILE" || { echo "Error: Cannot remove $LAST_PID_FILE" >&2; exit 1; }
    fi

    if [ -f "$LAST_PID_FILE" ]; then
        LAST_PID=$(cat "$LAST_PID_FILE")
        if [ "$CURRENT_PID" != "$LAST_PID" ]; then
            log_message "Process test was restarted (new PID: $CURRENT_PID, old PID: $LAST_PID)"
        fi
    fi

    # сохраняем текущий PID для следующей проверки
    echo "$CURRENT_PID" > "$LAST_PID_FILE" || { echo "Error: Cannot write to $LAST_PID_FILE" >&2; exit 1; }
else
    # процесс test не запущен, ничего не делаем
    :
fi
