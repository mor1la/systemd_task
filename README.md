# Запуск app1 и двух экземпляров app2 через systemd

## Состав

```text
app1.service
app2@.service
apps.target
app1.env
app2.env
install.sh
```

`app1.service` запускает приложение `app1`.

`app2@.service` — шаблонный unit-файл. Через него запускаются два экземпляра `app2`:

```text
app2@1.service
app2@2.service
```

`apps.target` объединяет все необходимые unit-файлы в одну группу:

```text
app1.service
app2@1.service
app2@2.service
```

За счёт этого весь набор приложений можно запустить одной командой:

```bash
sudo systemctl start apps.target
```

## Логика запуска

`app2` зависит от `app1`:

```ini
After=app1.service
Requires=app1.service
```

Поэтому экземпляры `app2` запускаются только после запуска `app1.service`.

В `apps.target` явно указано, что должны быть запущены `app1` и два экземпляра `app2`:

```ini
Requires=app1.service app2@1.service app2@2.service
After=network.target app1.service
```

## Порты

Для `app1` порт задаётся в `app1.env`:

```text
PORT=9001
```

Для `app2` используется шаблонный unit-файл и номер экземпляра:

```ini
Environment="PORT=900%i"
```

Примеры:

```text
app2@1.service -> PORT=9001
app2@2.service -> PORT=9002
```

Если для `app1` и `app2@1` нельзя использовать одинаковый порт, можно запускать экземпляры `app2@2` и `app2@3`, а в `apps.target` заменить строки на:

```ini
Requires=app1.service app2@2.service app2@3.service
```

## Установка через скрипт

```bash
chmod +x install.sh
./install.sh
```

Скрипт:

1. копирует unit-файлы в `/etc/systemd/system/`;
2. копирует env-файлы в `/opt/app1/conf/` и `/opt/app2/conf/`;
3. создаёт системных пользователей `app1` и `app2`, если их ещё нет;
4. выполняет `systemctl daemon-reload`;
5. включает и запускает `apps.target`.

## Ручная установка

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

Создать системных пользователей:

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

Запустить все приложения:

```bash
sudo systemctl start apps.target
```

## Проверка состояния

```bash
systemctl status apps.target
systemctl status app1.service
systemctl status app2@1.service
systemctl status app2@2.service
```

## Просмотр логов

```bash
journalctl -u app1.service -f
journalctl -u app2@1.service -f
journalctl -u app2@2.service -f
```

## Остановка

Остановить весь набор приложений:

```bash
sudo systemctl stop apps.target
```

Остановить конкретный экземпляр `app2`:

```bash
sudo systemctl stop app2@1.service
```

## Добавление нового экземпляра app2

Для добавления нового экземпляра отдельный unit-файл не нужен. Достаточно выбрать номер экземпляра:

```bash
sudo systemctl start app2@3.service
```

В этом случае приложение запустится с портом `9003`.
