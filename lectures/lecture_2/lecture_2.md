# Технологии искусственного интеллекта. Семестр 2

© Петров М.В., старший преподаватель кафедры суперкомпьютеров и общей информатики, Самарский университет

## Лекция 2. Мультиконтейнерные приложения. Docker Compose

### Содержание

1. [Введение](#21-введение)

### 2.1 Введение

Источники:
 - [YAML за 5 минут: синтаксис и основные возможности](https://tproger.ru/translations/yaml-za-5-minut-sintaksis-i-osnovnye-vozmozhnosti)
 - [Networking overview @ Docker](https://docs.docker.com/engine/network/)
 - [Docker и сети @ Хабр](https://habr.com/ru/companies/otus/articles/730798/)
 - [Compose file reference @ Docker](https://docs.docker.com/reference/compose-file/)

[Docker Compose](https://docs.docker.com/compose/) &ndash; это инструмент для декларативного описания и запуска приложений, состоящих из нескольких контейнеров. Он использует `yaml` файл для настройки сервисов приложения и выполняет процесс создания и запуска всех контейнеров с помощью одной команды. Утилита `docker-compose` позволяет выполнять команды на нескольких контейнерах одновременно &ndash; создавать образы, масштабировать контейнеры, запускать остановленные контейнеры и др.

Одиночные контейнеры хорошо подходят для развертывания простейших приложений, работающих автономно, не зависящих, например, от внешних источников данных или от неких сервисов. На практике же подобные приложения &ndash; редкость. Реальные проекты обычно включают в себя целый набор совместно работающих приложений.  

Как узнать, нужно ли вам, при развёртывании некоего проекта, воспользоваться **Docker Compose**? На самом деле &ndash; очень просто. Если для обеспечения функционирования этого проекта используется несколько сервисов, то **Docker Compose** может вам пригодиться. Например, в ситуации, когда создают веб-сайт, которому, для выполнения аутентификации пользователей, нужно подключиться к базе данных. Подобный проект может состоять из двух сервисов &ndash; того, что обеспечивает работу сайта, и того, который отвечает за поддержку базы данных.

Технология **Docker Compose**, если описывать её упрощённо, позволяет, с помощью одной команды, запускать множество сервисов.

#### Разница между Docker и Docker Compose

Docker применяется для управления отдельными контейнерами (сервисами), из которых состоит приложение.

Docker Compose используется для одновременного управления несколькими контейнерами, входящими в состав приложения. Этот инструмент предлагает те же возможности, что и Docker, но позволяет работать с более сложными приложениями.

<div align="center">
  <img src="images/docker_vs_docker_compose.svg" width="1000" title="Docker vs Docker Compose"/>
  <p style="text-align: center">
    Рисунок 1 &ndash; Docker vs Docker Compose
  </p>
</div>

### 2.2 Docker network

### 2.3 Docker secrets

### 2.4 YAML

**YAML** (***Y****AML* ***A****in't* ***M****arkup* ***L****anguage*) &ndash; это язык для сериализации данных, который отличается простым синтаксисом и позволяет хранить сложноорганизованные данные в компактном и читаемом формате.  

[YAML](https://yaml.org/) &ndash; это язык для хранения информации в формате, понятном человеку. Его название расшифровывается как, "Ещё один язык разметки". Однако, позже расшифровку изменили на "YAML не язык разметки", чтобы отличать его от настоящих языков разметки. Язык похож на XML и JSON, но использует более минималистичный синтаксис при сохранении аналогичных возможностей. YAML обычно применяют для создания конфигурационных файлов в программах типа [Инфраструктура как код](https://ru.wikipedia.org/wiki/%D0%98%D0%BD%D1%84%D1%80%D0%B0%D1%81%D1%82%D1%80%D1%83%D0%BA%D1%82%D1%83%D1%80%D0%B0_%D0%BA%D0%B0%D0%BA_%D0%BA%D0%BE%D0%B4) (Iac), или для управления контейнерами в работе DevOps.  

Особенности YAML:
- понятный человеку код
- минималистичный синтаксис
- заточен под работу с данными
- встроенный стиль, похожий на JSON (YAML является его надмножеством)
- поддерживает комментарии
- поддерживает строки без кавычек
- считается "чище", чем JSON
- дополнительные возможности (расширяемые типы данных, относительные якоря и маппинг типов с сохранением порядка ключей).

#### Пример

```yaml
---
mdg:
  version: some version
  timestamp_date_format: yyyyMMdd
  timestamp_time_format: hhmmsszzz
  mdg_subdir_name_prefix: mdg_
  capture_start_timer_interval_ms: 0 # unused
  # Seconds
  camera_settings_sync_timer_interval: 5
  capturing_shutdown_timer_interval: 5
  # Grabbers to enable
  enable_tis_camera_grabber: yes
tiscg:
  # RadxaZero, RaspberryPi, JetsonNano, Rock3A, RockCM3: 0, 1, 2, 3, 4
  platform: 4
  # GRAY8, BGRx
  pixel_format: GRAY8
  # DFM 42BUC03-ML: 640x480, 1024x768, 1280x960
  # DMM 37UX252-ML: 640x480, 1024x768, 1920x1080, 2048x1536
  frame_width: 1920 # for caps usage only
  frame_height: 1080 # for caps usage only
  # ...
  captured_data_settings:
    frames:
      captured_data_format: jpg
      captured_data_prefix: tis_frame_
    video:
      captured_data_format: mkv
      captured_data_prefix: tis_video
    video_with_frames:
      captured_data_frames_format: jpg
      captured_data_frames_prefix: tis_frame_
      captured_data_video_format: mkv
      captured_data_video_prefix: tis_video
      frame_num: 3
```

Считывание конфига в Python с использованием [PyYAML](https://pypi.org/project/PyYAML/):

```python
def load_settings(self):
    loading_is_ok = True

    try:
        self.config = yaml.safe_load(open(self.config_path))
    except yaml.YAMLError as e:
        loading_is_ok = False
        print(f"Config loading error: {e}")

    if loading_is_ok:
        self.config_mdg = self.config["mdg"]
        self.config_tiscg = self.config["tiscg"]
        self.timestamp_date_format = self.config_mdg["timestamp_date_format"]
        self.timestamp_time_format = self.config_mdg["timestamp_time_format"]
        self.capture_start_timer_interval_ms = self.config_mdg["capture_start_timer_interval_ms"]
        self.camera_settings_sync_timer_interval = self.config_mdg["camera_settings_sync_timer_interval"]
        self.capturing_shutdown_timer_interval = self.config_mdg["capturing_shutdown_timer_interval"]
        self.enable_tis_camera_grabber = self.config_mdg["enable_tis_camera_grabber"]
    
    return loading_is_ok
```

Подробнее про синтаксис: [YAML за 5 минут: синтаксис и основные возможности](https://tproger.ru/translations/yaml-za-5-minut-sintaksis-i-osnovnye-vozmozhnosti).

### 2.5 Пример Docker Compose