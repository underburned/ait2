# Технологии искусственного интеллекта. Семестр 2

© Петров М.В., старший преподаватель кафедры киберфотоники, Самарский университет

## Лекция 4. Клиент-серверное приложение с использованием Docker

### Содержание

1. [Введение](#41-введение)
2. [Клиентская часть](#42-клиентская-часть)
   - [Desktop GUI](#desktop-gui)
   - [Web GUI](#web-gui) ***[TBD]***
   - [Поднятие SSH туннеля с использованием `sshtunnel`](#поднятие-ssh-туннеля-с-использованием-sshtunnel)
3. [Серверная часть](#43-серверная-часть)
   - [Контейнер](#контейнер)
   - [Скрипт с `Dramatiq` и `Redis` на сервере](#скрипт-с-dramatiq-и-redis-на-сервере)

### 4.1 Введение

#### Постановка задачи

Цель &ndash; создание клиент-серверного приложения удаленной обработки данных.  
В качестве тонкого клиента приложения будет выступать десктопный графический интерфейс, реализуемый с использованием фреймворка [Qt](https://www.qt.io/) ([PyQt6](https://pypi.org/project/PyQt6/)) или веб-приложение (Flask, FastAPI). Данное приложение должно реализовать следующий функционал:
- загрузка исходных данных (например, изображения) и их отображение в GUI (веб-интерфейсе)
- передача загруженных данных на сервер для последующей обработки
- получение обработанных данных
- вывод пользователю сообщения о завершении обработки и отображение результатов в GUI (веб-интерфейсе)

Серверная часть должна реализовать следующий функционал внутри докер-контейнера:
- прием данных на обработку
- обработка данных
- передача обработанных данных обратно клиенту  

Концептуальная схема приложения изображена на рисунке 1.

<div align="center">
  <img src="images/client_server_docker_app_1.svg" width="1000" title="Client-server app architecture"/>
  <p style="text-align: center">
    Рисунок 1 &ndash; Концептуальная схема приложения
  </p>
</div>

Взаимодействие между клиентом и сервером должно осуществляться в асинхронном режиме. Для этого будет использоваться ***брокер сообщений***, экземпляры которого будут общаться через SSH туннель. Более подробная схема изображена на рисунке 2.

<div align="center">
  <img src="images/client_server_docker_app_2.svg" width="1000" title="Client-server app architecture"/>
  <p style="text-align: center">
    Рисунок 2 &ndash; Схема взаимодействия основных модулей
  </p>
</div>

#### Библиотеки

Для работы нам понадобится установка библиотек.

Клиент:
- dramatiq
- numpy
- opencv-python
- pyqt6
- sshtunnel

Команда:

```bash
pip install dramatiq[redis] numpy pyqt6 sshtunnel
```

Для работы `sshtunnel` нужен установленный OpenSSH.
> Linux: нужно поставить дополнительно либы:
> ```bash
> sudo apt install libffi-dev libssl-dev python-openssl
> ```
> P.S.: возможно, пакет `python-openssl` здесь лишний.

Сервер (внутри образа контейнера):
- dramatiq
- numpy
- opencv-python
- ...

Рассмотрим каждый из модулей по отдельности.

### 4.2 Клиентская часть

#### Desktop GUI

- [Введение в Qt](qt_intro.md)  
  Альтернативы:
  + [tkinter](https://docs.python.org/3/library/tkinter.html)
  + [wxPython &ndash; wxWidgets на Python](https://wxpython.org/index.html)
  + [Kivy](https://kivy.org/)

#### Web GUI
[TBD]
- [Введение в Flask]
- [Введение в FastAPI](fastapi_intro.md)

#### Поднятие SSH туннеля с использованием `sshtunnel`

Для поднятия SSH туннеля с клиента до сервера будем использовать [sshtunnel](https://github.com/pahaz/sshtunnel/), а именно `SSHTunnelForwarder` для проброса портов.

- [Документация](https://sshtunnel.readthedocs.io/en/latest/index.html)

Установка:

```bash
sudo pip3 install sshtunnel
```

> Наличие библиотек `libffi-dev` и `libssl-dev` необходимо для установки `sshtunnel` в Linux:
> ```bash
> sudo apt-get install -y libffi-dev libssl-dev python-openssl
> ```

Сначала создадим конфигурационный файл для клиента, скажем, `client_connection_config.yaml`:

```yaml
ssh_server_address: itkubrik.ru
ssh_server_port: <порт для SSH подключения>
ssh_server_username: <логин>
ssh_server_pkey: <путь к приватному ключу>
ssh_server_remote_bind_ip_address: <IP адрес запущенного контейнера>
ssh_server_remote_bind_port: <порт, открытый на сервере (проброшенный наружу из контейнера)>
ssh_server_local_bind_ip_address: 127.0.0.1
ssh_server_local_bind_port: <локальный порт на сервере>
ssh_server_local_password: <пароль, заданный в конфиге Redis>
```

В нашем случае в `ssh_server_remote_bind_port` мы впишем порт, который будет слушать `Redis` (6379 по умолчанию, мы впишем 6380).

```python
from sshtunnel import BaseSSHTunnelForwarderError, SSHTunnelForwarder
import yaml

client_connection_config = yaml.safe_load(open('./client_connection_config.yaml'))

ssh_server = SSHTunnelForwarder(
    (client_connection_config['ssh_server_ip'], client_connection_config['ssh_server_port']),
    ssh_username=client_connection_config['ssh_server_username'],
    ssh_pkey=client_connection_config['ssh_server_pkey'],
    remote_bind_address=(client_connection_config['ssh_server_remote_bind_ip_address'],
                         client_connection_config['ssh_server_remote_bind_port']),
    local_bind_address=(client_connection_config['ssh_server_local_bind_ip_address'],
                        client_connection_config['ssh_server_local_bind_port'])
)
ssh_server.daemon_forward_servers = True
```

> Код, связанный с `SSHTunnelForwarder` должен быть объявлен в глобальном контексте чем раньше, тем лучше (в скрипте до объявления классов и т.п.).

Для теста можно запустить и остановить туннель:

```python
ssh_server.start()
print(ssh_server.local_bind_port)  # show assigned local port
ssh_server.stop()
```

#### Распределенная обработка задач и брокер сообщений

Для реализации асинхронного взаимодействия между клиентом и сервером нам понадобится библиотека распределенной обработки задач и брокер сообщений.

[Dramatiq](https://dramatiq.io/) &ndash; библиотека распределенной обработки задач для Python 3.  
[Redis](https://redis.io/) (Remote Dictionary Service) &ndash; это опенсорсный сервер баз данных типа ключ-значение.

Установка:

```bash
sudo pip3 install dramatiq[redis]
```

- [Туториал по Dramatiq](https://dramatiq.io/guide.html)
- [Dramatiq как современная альтернатива Celery: больше нет проблем с версиями и поддержкой Windows](https://habr.com/ru/articles/565990/)

Инициализация:

```python
import dramatiq
from dramatiq.encoder import PickleEncoder
from dramatiq.results import Results
from dramatiq.results.backends import RedisBackend
from dramatiq.brokers.redis import RedisBroker

broker = RedisBroker(host=client_connection_config['ssh_server_local_bind_ip_address'],
                     port=client_connection_config['ssh_server_local_bind_port'], db=0,
                     password=client_connection_config['ssh_server_local_password'])
dramatiq.set_broker(broker)
result_backend = RedisBackend(encoder=PickleEncoder(),
                              password=client_connection_config['ssh_server_local_password'],
                              port=client_connection_config['ssh_server_local_bind_port'])
broker.add_middleware(Results(backend=result_backend))
dramatiq.set_encoder(dramatiq.PickleEncoder())
```

> Данный код должен быть объявлен в глобальном контексте чем раньше, тем лучше (в скрипте до объявления классов и т.п.).

Объявим в нашем классе пару функций:

```python
    def process_image_client(self, image):
        self.image_processed = image
        self.image_process_is_finished.emit()  # сигнал о завершении обработки изображения
        
    def process_image(self):
        messages = []
        messages.append(im_proc.send(self.image))

        for message in messages:
            rimg = message.get_result(block=True)
            self.process_image_client(rimg)
```

Здесь `im_proc` &ndash; функция, объявленная в глобальном контексте после инициализации Dramatiq. Декоратор [Actor](https://dramatiq.io/guide.html#actors) `@dramatiq.actor` превращает функцию в асинхронную:

```python
@dramatiq.actor(store_results=True)
def im_proc(img):
    print("Image {:} is sent to server.".format(img.shape))
    return img
```

Если ее вызвать напрямую, никакого асинхронного чуда не произойдет. Поэтому у функции `im_proc` вызывается метод `send`, в который передается изображение на обработку:

```python
im_proc.send(self.image)
```

Данное сообщение или задачу мы помещаем в массив. `store_results=True` необходим для извлечения результата обработки на клиенте.

Далее в цикле у асинхронной задачи мы вызываем метод `get_result` для получения результата обработки (по аналогии с `futures` в модуле `asyncio` в Питоне):

```python
for message in messages:
    rimg = message.get_result(block=True)
```

Вызов

```python
self.process_image_client(rimg)
```

нужен для сохранения полученного изображения в переменную-член класса и испускания сигнала о завершении обработки. Данный сигнал можно соединить со слотом, в котором будет реализована логика отображения результата обработки в GUI.

#### Брокер сообщений

Изначально Redis был разработан как база данных и кэш для временного хранения данных в оперативной памяти. Но в версию Redis 2.0. создатели включили функцию PUBLISH/SUBSCRIBE, которая позволила использовать Redis в качестве брокера сообщений.

Брокер сообщений упрощает обмен информацией между системами и приложениями, даже если они работают на разных языках и платформах. При небольшом количестве участников обмениваться данными можно напрямую, однако с увеличением количества участников возникает потребность в большей интерактивности, и этот способ становится неэффективным. В таких случаях лучше использовать брокер сообщений, который управляет процессом обмена информацией и является посредником между отправителем и получателем.

Особенно он будет полезен для асинхронного взаимодействия микросервисов. Асинхронная связь не требует ожидания ответа в режиме реального времени. В качестве примера можно привести электронную почту, где пользователи могут отправить письмо и продолжить выполнять другие задачи.

Из `Dramatiq` в нашем случае используется `RedisBroker` в качестве брокера сообщений и `RedisBackend` для сохранения результатов обработки:

```python
broker = RedisBroker(host=client_connection_config['ssh_server_local_bind_ip_address'],
                     port=client_connection_config['ssh_server_local_bind_port'], db=0,
                     password=client_connection_config['ssh_server_local_password'])
dramatiq.set_broker(broker)
result_backend = RedisBackend(encoder=PickleEncoder(),
                              password=client_connection_config['ssh_server_local_password'],
                              port=client_connection_config['ssh_server_local_bind_port'])
broker.add_middleware(Results(backend=result_backend))
dramatiq.set_encoder(dramatiq.PickleEncoder())
```

`PickleEncoder` используется для сериализации/десериализации изображения при обмене сообщениями между клиентом и сервером.

### 4.3 Серверная часть

Серверная часть:
- контейнер с развернутой нейронкой и настроенным брокером сообщений.

#### Контейнер

В образ мы установим и настроим Redis

```dockerfile
FROM <образ с настроенным окружением для запуска нейронки>
RUN apt update && apt install -y libsm6 libxext6 libxrender-dev nano systemd redis-server libffi-dev libssl-dev python-openssl libjpeg-dev libpng-dev libtiff-dev
ADD redis.conf /etc/redis/redis.conf
RUN pip3 install --upgrade pip
RUN pip3 install --upgrade dramatiq[redis,watch] imageio numpy opencv_contrib_python scipy six pandas scikit-image flask sshtunnel jsonpickle
WORKDIR usr/local/cnn
ENTRYPOINT /usr/bin/redis-server /etc/redis/redis.conf --daemonize yes && /bin/bash
CMD [ "bash" ]
```

В [redis.conf](data/redis.conf) необходимо задать порт `port` (по желанию, или оставить 6380) и заменить пароль `requirepass`.

> При изменении порта на другое значение можно также переименовать:
> ```nano
> pidfile /var/run/redis_6380.pid
> ```

Пример запуска контейнера:

```bash
docker container run --name cubesat_doer_unet -v $(pwd)/cnn/:/usr/local/cnn/ --net cnn --ip 172.18.0.2 -p 6380:6380 --runtime=nvidia -it --rm cubesat_doer_unet /bin/bash
```

Здесь `ip` &ndash; IP адрес контейнера. Этот IP должен быть вписан в `ssh_server_remote_bind_ip_address` в конфиге клиента. А порт 6380 (внешний) в `ssh_server_remote_bind_port`.

> Необходимо переделать на Docker Compose.

#### Скрипт с `Dramatiq` и `Redis` на сервере

Для серверной части создадим конфиг `server_connection_config.yaml`:

```yaml
---
ssh_server_remote_bind_ip_address: 127.0.0.1
ssh_server_remote_bind_port: 6379
ssh_server_local_password: <пароль как в redis.conf>
```

Серверный кдо поместим в отдельный скрипт:

```python
import dramatiq
from dramatiq.encoder import PickleEncoder
from dramatiq.results import Results
from dramatiq.results.backends import RedisBackend
from dramatiq.brokers.redis import RedisBroker
from pprint import pprint
import yaml


server_connection_config = yaml.safe_load(open('./server_connection_config.yaml'))

broker = RedisBroker(host=server_connection_config['ssh_server_remote_bind_ip_address'],
                     port=server_connection_config['ssh_server_remote_bind_port'], db=0,
                     password=server_connection_config['ssh_server_local_password'])
dramatiq.set_broker(broker)
pprint(broker.client)
result_backend = RedisBackend(encoder=PickleEncoder(), password=server_connection_config['ssh_server_local_password'])
broker.add_middleware(Results(backend=result_backend))
dramatiq.set_encoder(dramatiq.PickleEncoder())


def process_image_server(img):
    # Код обработки res = process_image(img)

    return res


@dramatiq.actor(store_results=True)
def im_proc(img):
    rimg = process_image_server(img)
    return rimg
```

После старта контейнера необходимо выполнить команду (можно прописать в `CMD` в докер-файле):

```bash
dramatiq <имя скрипта без .py> -p 1 -t 1 --watch .
```

Теперь `Dramatiq` будет ожидать поступление новой задачи.

