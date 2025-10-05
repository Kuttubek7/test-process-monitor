ЗАДАЧА: 
Написать скрипт на bash для мониторинга процесса test в среде linux. Скрипт должен отвечать следующим требованиям:

1) Запускаться при запуске системы (предположительно написать юнит systemd в дополнение к скрипту)
2) отрабатывать каждую минуту
3) если процесс запущен, то стучаться по https на https::/test.com/monitoring/test/api
4) если процесс был перезапущен, писать в лог /var/log/monitoring.log (если процесс не запущен, то ничего не делать)
5) если сервер мониторинга недоступен, также писать в лог 

РЕШЕНИЕ:

1) file: ~/test-process-monitor/systemd/monitor-test.service
2) file: ~/test-process-monitor/systemd/monitor-test.timer
3) file: ~/test-process-monitor/scripts/monitor_test.sh line:27
4) прописано в скрипте
5) line:20

для правильной работы скрипта наши файлы в ubuntu 22.04 LTS должны находиться в директориях

~/usr/local/bin/monitor_test.sh - а также у него должны быть соответствующие права для запуска

~/etc/systemd/system/monitor-test.service

~/etc/systemd/system/monitor-test.timer

~/var/log/monitoring.log - наши логи будут храниться по этому адресу
