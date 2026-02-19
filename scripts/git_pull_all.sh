#!/bin/bash

# Скрипт для runtel_auto_tests
set -eux

echo "Clean and update git references (fetch, prune, gc)"
git fetch --all --prune           # Получаем все изменения и удаляем устаревшие ссылки
git remote prune origin            # Удаляем локальные ссылки на удаленные ветки
git gc --prune=now                 # Очищаем мусор и сжимаем репозиторий

echo "=== Make  git pull  for all branches ==="
for branch in $(git branch -r | grep -v HEAD | cut -d'/' -f2-); do
	echo "Processing branch: $branch"

    # Проверяем существование удаленной ветки
    if git ls-remote --heads origin $branch | grep -q $branch; then
        if git show-ref --verify --quiet "refs/heads/$branch"; then
            git checkout $branch                # Переключаемся на локальную ветку
            git pull origin $branch              # Обновляем ветку с сервера
        else
            echo "Create local branch"
            git checkout -b $branch origin/$branch  # Создаем локальную ветку из удаленной
        fi
    else
        echo "Удаленная ветка $branch не существует, пропускаем"
        # Удаляем локальную ветку, если удаленная ветка не существует
        if git show-ref --verify --quiet "refs/heads/$branch"; then
            echo "Удаление локальной ветки: $branch"
            git branch -D "$branch"              # Принудительно удаляем локальную ветку
        fi
    fi
done

echo "Update master branch"
git checkout master                  # Переключаемся на ветку master
# Проверяем существование удаленной ветки master перед pull
if git ls-remote --heads origin master | grep -q master; then
    git pull origin master            # Обновляем master с сервера
else
    echo "Удаленная ветка master не существует"
fi

echo "Show branch status"
git branch -va                        # Показываем все ветки с последними коммитами


#git fetch --all --prune - загружает все изменения и удаляет устаревшие ссылки на ветки
#git remote prune origin - чистит локальный кэш удаленных веток
#git gc --prune=now - оптимизирует хранилище Git
#git pull origin $branch - обновляет ветку с сервера
#git branch -D - принудительно удаляет локальную ветку
#git branch -va - показывает все ветки и их последние коммиты
