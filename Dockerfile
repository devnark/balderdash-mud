# --- Этап 1: Сборка бинарника ---
FROM ubuntu:14.04 AS builder

# ИСПРАВЛЕНИЕ: Переключаем репозитории на архивные (необходимо для работы apt-get в Ubuntu 14.04)
RUN sed -i 's|http://ubuntu.com|http://ubuntu.com|g' /etc/apt/sources.list && \
    sed -i 's|http://ubuntu.com|http://ubuntu.com|g' /etc/apt/sources.list

WORKDIR /app
COPY . .

# Патчи для корректной компиляции легаси-кода на Mac ARM64
RUN sed -i 's|srandom(time(NULL)\^getpid());|srandom((unsigned int)time(NULL) \^ (unsigned int)getpid());|g' src/db.c || true
RUN sed -i 's|C_FLAGS =|C_FLAGS = -fsigned-char|g' src/Makefile

RUN apt-get update && apt-get install -y build-essential zlib1g-dev
RUN cd /app/src && make rom

# --- Этап 2: Финальный образ для запуска ---
FROM ubuntu:14.04
WORKDIR /app

# Копируем всё дерево проекта из сборщика
COPY --from=builder /app /app

# Подготовка папок и прав
RUN mkdir -p /app/player /app/gods /app/log && \
    chmod -R 777 /app/player /app/gods /app/log /app/area

EXPOSE 9000

# Запуск сервера
WORKDIR /app/area
CMD ["/app/src/rom", "-p", "9000", "-f", "/app/area/mud.cfg"]
