# Systemd service files для app1 и app2

## Что реализовано

Реализован запуск двух приложений через systemd:

- `app1.service` — запуск приложения `app1`;
- `app2@.service` — шаблонный unit-файл для запуска нескольких экземпляров `app2`;
- `apps.target` — общий target для запуска всего набора приложений одной командой.

По заданию `app2` запускается только после `app1`, а само приложение `app2` запускается в двух экземплярах.

В этой реализации используются два экземпляра:

```text
app2@9002.service
app2@9003.service
```

Номер экземпляра одновременно является портом приложения

## Состав файлов

```text
app1.service
app2@.service
apps.target
app1.env.example
app2.env.example
install.sh
```

## Подготовка env-файлов

Перед установкой нужно создать реальные env-файлы из примеров:

```bash
cp app1.env.example app1.env
cp app2.env.example app2.env
```

После этого при необходимости можно отредактировать значения

Пример `app1.env`:

```env
PORT=9001
CONFIG_FILE_PATH=conf/application.conf
JAVA_OPTS=-Xms512m -Xmx1G
```

Пример `app2.env`:

```env
CONFIG_FILE_PATH=conf/application.conf
JAVA_OPTS=-Xms512m -Xmx1G
```

Для `app2` порт не указывается в env-файле, потому что он задаётся через имя экземпляра systemd-сервиса:

```ini
Environment="PORT=%i"
```

Примеры:

```text
app2@9002.service -> PORT=9002
app2@9003.service -> PORT=9003
```

Переменная `JAVA_OPTS` не указывается в `ExecStart`, потому что по условию она используется внутри скрипта запуска приложения `/opt/app1/bin/app1` или `/opt/app2/bin/app2`.

## Логика запуска

`app1.service` запускается первым.

В `app2@.service` указана зависимость от `app1`:

```ini
After=network.target app1.service
Requires=app1.service
```

Это означает:

- `After=app1.service` задаёт порядок запуска: `app2` стартует после `app1`;
- `Requires=app1.service` указывает, что для запуска `app2` нужен `app1`.

В `apps.target` перечислены все сервисы, которые должны быть запущены вместе:

```ini
Requires=app1.service app2@9002.service app2@9003.service
After=network.target app1.service
```

Поэтому весь набор можно запустить одной командой:

```bash
sudo systemctl start apps.target
```

## Установка через install.sh

Сначала создать env-файлы:

```bash
cp app1.env.example app1.env
cp app2.env.example app2.env
```

Затем запустить установку:

```bash
chmod +x install.sh
./install.sh
```

Скрипт:

1. проверяет наличие `app1.env` и `app2.env`;
2. копирует unit-файлы в `/etc/systemd/system/`;
3. копирует env-файлы в `/opt/app1/conf/` и `/opt/app2/conf/`;
4. создаёт системных пользователей `app1` и `app2`, если их ещё нет;
5. назначает права на каталоги `/opt/app1` и `/opt/app2`;
6. выполняет `systemctl daemon-reload`;
7. включает и запускает `apps.target`.

Cами приложения должны уже лежать в каталогах:

```text
/opt/app1/bin/app1
/opt/app2/bin/app2
```

## Ручная установка

Создать env-файлы:

```bash
cp app1.env.example app1.env
cp app2.env.example app2.env
```

Скопировать unit-файлы:

```bash
sudo cp app1.service /etc/systemd/system/
sudo cp app2@.service /etc/systemd/system/
sudo cp apps.target /etc/systemd/system/
```

Скопировать env-файлы:

```bash
sudo mkdir -p /opt/app1/conf /opt/app2/conf
sudo cp app1.env /opt/app1/conf/app1.env
sudo cp app2.env /opt/app2/conf/app2.env
```

Создать пользователей:

```bash
sudo useradd --system --no-create-home --shell /usr/sbin/nologin app1
sudo useradd --system --no-create-home --shell /usr/sbin/nologin app2
sudo chown -R app1:app1 /opt/app1
sudo chown -R app2:app2 /opt/app2
```

Перечитать конфигурацию systemd:

```bash
sudo systemctl daemon-reload
```

Включить автозапуск:

```bash
sudo systemctl enable apps.target
```

Запустить приложения:

```bash
sudo systemctl start apps.target
```

## Проверка состояния

```bash
systemctl status apps.target
systemctl status app1.service
systemctl status app2@9002.service
systemctl status app2@9003.service
```

## Остановка

Остановить весь набор приложений:

```bash
sudo systemctl stop apps.target
```

