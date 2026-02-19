#!/bin/bash

# Скрипт для runtel_auto_tests - сброс всех веток с обработкой конфликтов
set -eux

echo "=== Запуск процесса сброса git для всех веток ==="
#cd /home/runtel_auto_tests/

echo "=== Проверка наличия незавершенных git операций ==="
# Отмена незавершенных операций (merge/rebase/cherry-pick)
git merge --abort 2>/dev/null || true   # Отмена слияния
git rebase --abort 2>/dev/null || true  # Отмена перебазирования
git cherry-pick --abort 2>/dev/null || true  # Отмена применения коммита

echo "=== Очистка и обновление git ссылок ==="
git fetch --all --prune           # Получаем все изменения, удаляем устаревшие ссылки
git remote prune origin            # Очищаем локальный кэш удаленных веток
git gc --prune=now                 # Очищаем мусор и сжимаем репозиторий

echo "=== Проверка и разрешение конфликтов слияния ==="
# Повторная проверка незавершенных операций
git merge --abort 2>/dev/null || true
git rebase --abort 2>/dev/null || true
git cherry-pick --abort 2>/dev/null || true

echo "=== Обработка каждой удаленной ветки ==="
for branch in $(git branch -r | grep -v HEAD | cut -d'/' -f2-); do
    echo "Обработка ветки: $branch"
    
    # Проверка незавершенных операций перед переключением
    git merge --abort 2>/dev/null || true
    git rebase --abort 2>/dev/null || true
    git cherry-pick --abort 2>/dev/null || true
    
    # Проверяем существование удаленной ветки
    if git ls-remote --heads origin $branch | grep -q $branch; then
        if git show-ref --verify "refs/heads/$branch" 2>/dev/null; then
            echo "Сброс существующей ветки: $branch"
            git checkout -f "$branch"              # Принудительно переключаемся на ветку
            git reset --hard "origin/$branch"       # Жесткий сброс до состояния удаленной ветки
        else
            echo "Создание новой локальной ветки: $branch"
            git checkout -b "$branch" "origin/$branch"  # Создаем ветку из удаленной
        fi
    else
        echo "Удаленная ветка origin/$branch не существует, пропускаем"
        # Удаляем локальную ветку, если удаленной нет
        if git show-ref --verify "refs/heads/$branch" 2>/dev/null; then
            echo "Удаление локальной ветки: $branch"
            git branch -D "$branch"                  # Принудительно удаляем локальную ветку
        fi
    fi
done

echo "=== Очищаем директорию от файлов, которые не отслеживаются git ==="
git clean -fdx                    # Удаляем неотслеживаемые файлы и директории

#echo "=== Воссоздание необходимых директорий ==="
#mkdir -p test_results/allure-results
#mkdir -p test_results/logs

echo "=== Показ текущего статуса ==="
git status                         # Показываем состояние рабочей директории
git log -1 --oneline               # Показываем последний коммит

echo "=== Финальная очистка ==="
# Финальная проверка незавершенных операций
git merge --abort 2>/dev/null || true
git rebase --abort 2>/dev/null || true
git cherry-pick --abort 2>/dev/null || true

echo "=== Переключение на master ==="
git checkout -f master              # Принудительно переключаемся на master
# Проверяем существование удаленной ветки master перед сбросом
if git ls-remote --heads origin master | grep -q master; then
    git reset --hard origin/master   # Жесткий сброс master до состояния удаленной ветки
else
    echo "Удаленная ветка master не существует"
fi
git log -1 --oneline                 # Показываем последний коммит в master




#git reset --hard origin/$branch - жестко сбрасывает локальную ветку до состояния удаленной (все локальные изменения удаляются)
#git checkout -f - принудительное переключение ветки (отменяет локальные изменения)
#git clean -fdx - удаляет все неотслеживаемые файлы, включая игнорируемые (-x) и директории (-d)
#git branch -D - принудительное удаление ветки (даже если не слита)
#git log -1 --oneline - показывает последний коммит в сокращенном формате
