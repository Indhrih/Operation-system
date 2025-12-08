#!/bin/bash
SHOW_USERS=false
SHOW_PROCESSES=false
LOG_FILE=""
ERROR_FILE=""
show_help() {
    echo "
Использование: $0 [ОПЦИИ]
Опции:
    -u, --users         Вывести список пользователей и их домашние директории
    -p, --processes     Вывести список запущенных процессов по PID
    -h, --help          Показать эту справку и выйти
    -l PATH, --log PATH Перенаправить вывод в файл PATH
    -e PATH, --errors PATH Перенаправить stderr в файл PATH
    "
}

show_users() {
    cat /etc/passwd | cut -d ":" -f 1,6 | sort
}
show_processes() {
    ps -eo pid,comm --no-headers | sort -n
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
PARSED=$(getopt -o uphl:e: --long users,processes,help,log:,errors: -n "$0" -- "$@")

if [ $? -ne 0 ]; then
    echo "Ошибка разбора аргументов" >&2
    exit 1
fi

eval set -- "$PARSED"

while true; do
    case "$1" in
        -u|--users)
            SHOW_USERS=true
            shift
            ;;
        -p|--processes)
            SHOW_PROCESSES=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -l|--log)
            LOG_FILE="$2"
            if ! check_path "$LOG_FILE"; then
                exit 1
            fi
            shift 2
            ;;
        -e|--errors)
            ERROR_FILE="$2"
            if ! check_path "$ERROR_FILE"; then
                exit 1
            fi
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Внутренняя ошибка" >&2
            exit 1
            ;;
    esac
done

# Замещаем вывод ошибок из потока stderr в файл по заданному пути PATH
if [ -n "$ERROR_FILE" ]; then
    if ! exec 2>"$ERROR_FILE"; then
        echo "Ошибка: Не удалось перенаправить stderr в файл $ERROR_FILE" >&2
        exit 1
    fi
else
    # Фильтрация вывода в stderr используемых команд
    exec 2> >(grep -v "Отказано в доступе\|Permission denied\|No such file or directory" >&2)
fi

# Замещаем вывод на экран выводом в файл по заданному пути PATH
if [ -n "$LOG_FILE" ]; then
    if ! exec 1>"$LOG_FILE"; then
        echo "Ошибка: Не удалось перенаправить stdout в файл $LOG_FILE" >&2
        exit 1
    fi
fi

# Выполняем запрошенные действия
if [ "$SHOW_USERS" = true ]; then
    show_users
fi

if [ "$SHOW_PROCESSES" = true ]; then
    show_processes
fi

# Если не указано ни одного действия, выводим справку
if [ "$SHOW_USERS" = false ] && [ "$SHOW_PROCESSES" = false ]; then
    echo "Ошибка: Не указано действие. Используйте -u, -p или -h" >&2
    show_help
    exit 1
fi

exit 0
