#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Начинаем настройку репликации MySQL...${NC}"

# Проверяем наличие .env файла
if [ ! -f .env ]; then
    echo -e "${RED}Ошибка: Файл .env не найден!${NC}"
    echo "Скопируйте .env.example в .env и заполните своими паролями:"
    echo "cp .env.example .env"
    exit 1
fi

echo "Останавливаем старые контейнеры..."
docker stop mysql_master mysql_slave 2>/dev/null
docker rm mysql_master mysql_slave 2>/dev/null

echo "Удаляем старую сеть..."
docker network rm replication_network 2>/dev/null

echo "Создаем новую сеть..."
docker network create replication_network

echo "Собираем образы..."
docker build -t mysql_master -f ./Dockerfile_master .
docker build -t mysql_slave -f ./Dockerfile_slave .

echo "Запускаем мастер на порту 3307..."
docker run --name mysql_master \
  --net replication_network \
  -p 3307:3306 \
  --env-file .env \
  -d mysql_master

echo "Запускаем слейв на порту 3308..."
docker run --name mysql_slave \
  --net replication_network \
  -p 3308:3306 \
  --env-file .env \
  -d mysql_slave

echo -e "${GREEN}Готово! Проверьте статус: docker ps${NC}"
echo "Для подключения к мастеру: docker exec -it mysql_master mysql -u root -p"
echo "Для подключения к слейву: docker exec -it mysql_slave mysql -u root -p"
