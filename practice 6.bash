#!/bin/bash
SHOW_USERS=false
SHOW_PROCESSES=false
LOG_FILE=""
ERROR_FILE=""
show_help() {
    echo *
Использование: $0 [ОПЦИИ]
Опции:
    -u, --users         Вывести список пользователей и их домашние директории
    -p, --processes     Вывести список запущенных процессов по PID
    -h, --help          Показать эту справку и выйти
    -l PATH, --log PATH Перенаправить вывод в файл PATH
    -e PATH, --errors PATH Перенаправить stderr в файл PATH
}
show_users() {
    awk -F: '{print $1 ":" $6}' /etc/passwd | sort
}
show_processes() {
    ps -eo pid,comm --sort=pid
}
check_path() {
    local path="$1"
    local dir=$(dirname "$path")
    
    if [ ! -d "$dir" ]; then
        echo "Ошибка: Директория $dir не существует" >&2
        return 1
    fi
    
    if [ ! -w "$dir" ]; then
        echo "Ошибка: Нет прав на запись в директорию $dir" >&2
        return 1
    fi
    
    return 0
}
while getopts ":uphl:e:-:" opt; do
    case $opt in
        u)
            SHOW_USERS=true
            ;;
        p)
            SHOW_PROCESSES=true
            ;;
        h)
            show_help
            exit 0
            ;;
        l)
            LOG_FILE="$OPTARG"
            if ! check_path "$LOG_FILE"; then
                exit 1
            fi
            ;;
        e)
            ERROR_FILE="$OPTARG"
            if ! check_path "$ERROR_FILE"; then
                exit 1
            fi
            ;;
        -)
            case "${OPTARG}" in
                users)
                    SHOW_USERS=true
                    ;;
                processes)
                    SHOW_PROCESSES=true
                    ;;
                help)
                    show_help
                    exit 0
                    ;;
                log)
                    LOG_FILE="${!OPTIND}"
                    OPTIND=$((OPTIND + 1))
                    if ! check_path "$LOG_FILE"; then
                        exit 1
                    fi
                    ;;
                errors)
                    ERROR_FILE="${!OPTIND}"
                    OPTIND=$((OPTIND + 1))
                    if ! check_path "$ERROR_FILE"; then
                        exit 1
                    fi
                    ;;
                *)
                    echo "Неизвестная опция: --${OPTARG}" >&2
                    show_help
                    exit 1
                    ;;
            esac
            ;;
        \?)
            echo "Неизвестная опция: -$OPTARG" >&2
            show_help
            exit 1
            ;;
        :)
            echo "Опция -$OPTARG требует аргумент" >&2
            exit 1
            ;;
    esac
done
if [ -n "$LOG_FILE" ]; then
    exec > "$LOG_FILE"
fi
if [ -n "$ERROR_FILE" ]; then
    exec 2> "$ERROR_FILE"
else
    # Фильтрация stderr
    exec 2> >(grep -v "Отказано в доступе\|Permission denied" >&2)
fi
if [ "$SHOW_USERS" = true ]; then
    echo "=== Список пользователей и их домашние директории ==="
    show_users
fi
if [ "$SHOW_PROCESSES" = true ]; then
    echo "=== Список запущенных процессов (сортировка по PID) ==="
    show_processes
fi
if [ "$SHOW_USERS" = false ] && [ "$SHOW_PROCESSES" = false ]; then
    echo "Ошибка: Не указано действие. Используйте -u, -p или -h" >&2
    show_help
    exit 1
fi

exit 0
