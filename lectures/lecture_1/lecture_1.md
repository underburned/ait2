# Технологии искусственного интеллекта. Семестр 2

© Петров М.В., старший преподаватель кафедры суперкомпьютеров и общей информатики, Самарский университет

## Лекция 1. Контейнеризация. Docker

### Содержание

1. [Введение](#11-введение)
2. [Контейнер](#12-контейнер)
3. [Работа с Docker](#13-работа-с-docker)
4. [Хранение данных](#14-хранение-данных)
5. [Создание образа с использованием Dockerfile](#15-создание-образа-с-использованием-dockerfile)
6. [Пример](#16-пример)

### 1.1 Введение

Источники:
 - [Полное практическое руководство по Docker: с нуля до кластера на AWS @ Хабр](https://habr.com/ru/articles/310460/)
 - [Основы контейнеризации (обзор Docker и Podman) @ Хабр](https://habr.com/ru/articles/659049/)
 - [Руководство по Docker Compose для начинающих @ Хабр](https://habr.com/ru/companies/ruvds/articles/450312/)

> [Docker](https://ru.wikipedia.org/wiki/Docker) &ndash; программное обеспечение для автоматизации развёртывания и управления приложениями в средах с поддержкой контейнеризации, контейнеризатор приложений. Позволяет "упаковать" приложение со всем его окружением и зависимостями в контейнер, который может быть развёрнут на любой Linux-системе с поддержкой контрольных групп в ядре, а также предоставляет набор команд для управления этими контейнерами. Изначально использовал возможности `LXC`, с 2015 года начал использовать собственную библиотеку, абстрагирующую виртуализационные возможности ядра Linux &ndash; `libcontainer`. С появлением `Open Container Initiative` начался переход от монолитной к модульной архитектуре. Разрабатывается и поддерживается одноимённой компанией-стартапом, распространяется в двух редакциях &ndash; общественной (Community Edition) по лицензии Apache 2.0 и для организаций (Enterprise Edition) по проприетарной лицензии. Написан на языке `Go`.

Докер это инструмент, который позволяет разработчикам, системным администраторам и другим специалистам деплоить приложения в песочнице (которая называются контейнером), для запуска на целевой операционной системе, например, Linux. Ключевое преимущество докера в том, что он позволяет пользователям упаковывать приложение со всеми его зависимостями в стандартизированный модуль для разработки. В отличие от виртуальных машин, контейнеры не создают такой дополнительной нагрузки, поэтому с ними можно использовать систему и ресурсы более эффективно.

#### История

Идея изоляции пользовательских пространств берет свое начало в 1979 году, когда в ядре UNIX появился системный вызов `chroot`. Он позволял изменить путь каталога корня `/` для группы процессов на новую локацию в файловой системе, то есть фактически создавал новый корневой каталог, который был изолирован от первого. Следующим шагом и логическим продолжением `chroot` стало создание в 2000 году FreeBSD `jails` ("тюрем"), в которых изначально появилась частичная изоляция сетевых интерфейсов. В первой половине нулевых технологии виртуализации на уровне ОС активно развивались &ndash; появились *Linux VServer* (2001), *Solaris Containers* (2004) и *OpenVZ* (2005).

В операционной системе Linux технологии изоляции и виртуализации ресурсов вышли на новый этап в 2002 году, когда в ядро было добавлено первое пространство имен для изоляции файловой системы &ndash; `mount`. В 2006-2007 годах компанией Google был разработан механизм *Process Containers* (позднее переименованный в `cgroups`), который позволил ограничить и изолировать использование группой процессов ЦПУ, ОЗУ и др. аппаратных ресурсов. В 2008 году функционал `cgroups` был добавлен в ядро Linux. Достаточная функциональность для полной изоляции и безопасной работы контейнеров была завершена в 2013 году с добавлением в ядро пространства имен пользователей &ndash; `user`.

В 2008 году была представлена система `LXC` (*LinuX Containers*), которая позволяла запускать несколько изолированных Linux систем (контейнеров) на одном сервере. LXC использовала для работы механизмы изоляции ядра &ndash; `namespaces` и `cgroups`. В 2013 году на свет появилась платформа `Docker`, невиданно популяризовавшая контейнерные технологии за счет простоты использования и широкого функционала. Изначально `Docker` использовал LXC для запуска контейнеров, однако позднее перешел на собственную библиотеку `libcontainer`, также завязанную на функционал ядра Linux. Наконец, в 2015 появился проект *Open Container Initiative* (*OCI*), который регламентирует и стандартизирует развитие контейнерных технологий по сей день.

Подробнее: [Недостающее введение в контейнеризацию @ Хабр](https://habr.com/ru/articles/541288/)

### 1.2 Контейнер

Контейнеризация (виртуализация на уровне ОС) &ndash; технология, которая позволяет запускать программное обеспечение в изолированных на уровне операционной системы пространствах. Контейнеры являются наиболее распространенной формой виртуализации на уровне ОС. С помощью контейнеров можно запустить несколько приложений на одном сервере (хостовой машине), изолируя их друг от друга.

<div align="center">
  <img src="images/docker_vs_vm.svg" width="1000" title="Docker vs VM"/>
  <p style="text-align: center">
    Рисунок 1 &ndash; Сравнение докера с виртуальными машинами
  </p>
</div>

Процесс, запущенный в контейнере, выполняется внутри операционной системы хостовой машины, но при этом он изолирован от остальных процессов. Для самого процесса это выглядит так, будто он единственный работает в системе.

#### Механизмы изоляции контейнеров

Изоляция процессов в контейнерах осуществляется благодаря двум механизмам ядра Linux &ndash; пространствам имен (`namespaces`) и контрольным группам (`cgroups`).
Пространства имен гарантируют, что процесс будет работать с собственным представлением системы. Существует несколько типов пространств имен:
 - файловая система (`mount`, `mnt`) &ndash; изолирует файловую систему
 - UTS (UNIX Time-Sharing, `uts`) &ndash; изолирует имя хоста и доменное имя
 - идентификатор процессов (`process identifier`, `pid`) &ndash; изолирует процессы
 - сеть (`network`, `net`) &ndash; изолирует сетевые интерфейсы
 - межпроцессное взаимодействие (`ipc`) &ndash; изолирует конкурирующее взаимодействие процессами
 - пользовательские идентификаторы (`user`) &ndash; изолирует ID пользователей и групп

Контрольные группы гарантируют, что процесс не будет конкурировать за ресурсы, зарезервированные за другими процессами. Они ограничивают (контролируют) объем ресурсов, который процесс может потреблять &ndash; ЦПУ, ОЗУ, пропускную способность сети и др.

Подробнее:
- [Механизмы контейнеризации: namespaces @ Хабр](https://habr.com/ru/company/selectel/blog/279281/)
- [Механизмы контейнеризации: cgroups @ Хабр](https://habr.com/ru/company/selectel/blog/303190/)

#### Основные понятия

- `Container image` (образ) &ndash; файл, в который упаковано приложение и его среда. Он содержит файловую систему, которая будет доступна приложению, и другие метаданные (например команды, которые должны быть выполнены при запуске контейнера). Образы контейнеров состоят из слоев (как правило один слой &ndash; одна инструкция). Разные образы могут содержать одни и те же слои, поскольку каждый слой надстроен поверх другого образа, а два разных образа могут использовать один и тот же родительский образ в качестве основы. Образы хранятся в `Registry Server` (реестре) и версионируются с помощью `tag` (тегов). Если тег не указан, то по умолчанию используется `latest`. Примеры: [Ubuntu @ DockerHub](https://hub.docker.com/_/ubuntu), [Postgres @ DockerHub](https://hub.docker.com/_/postgres), [NGINX @ DockerHub](https://hub.docker.com/_/nginx).

- `Registry Server` (реестр, хранилище) &ndash; это репозиторий, в котором хранятся образы. После создания образа на локальном компьютере его можно отправить (`push`) в хранилище, а затем извлечь (`pull`) на другом компьютере и запустить его там. Существуют общедоступные и закрытые реестры образов. Примеры: [Docker Hub](https://hub.docker.com/) (репозитории `docker.io`), [RedHat Quay.io](https://quay.io/search) (репозитории `quay.io`).

- `Container` (контейнер) &ndash; это экземпляр образа контейнера. Выполняемый контейнер &ndash; это запущенный процесс, изолированный от других процессов на сервере и ограниченный выделенным объемом ресурсов (ЦПУ, ОЗУ, диска и др.). Выполняемый контейнер сохраняет все слои образа с доступом на чтение и формирует сверху свой исполняемый слой с доступом на запись.

- `Container Engine` (движок контейнеризации) &ndash; это программная платформа для упаковки, распространения и выполнения приложений, которая скачивает образы и с пользовательской точки зрения запускает контейнеры (на самом деле за создание и запуск контейнеров отвечает `Container Runtime`). Примеры: [Docker](https://docs.docker.com/get-started/overview/), [Podman](https://docs.podman.io/en/latest/).

- `Container Runtime` (среда выполнения контейнеров) &ndash; программный компонент для создания и запуска контейнеров. Примеры: [runc](https://github.com/opencontainers/runc) (инструмент командной строки, основанный на упоминавшейся выше библиотеке `libcontainer`), [crun](https://github.com/containers/crun).

- `Host` (хост) &ndash; сервер, на котором запущен `Container Engine` и выполняются контейнеры.

[Open Container Initiative](https://opencontainers.org/) (OCI) &ndash; это проект Linux Foundation, основанный в 2015 году компанией Docker, Inc, целью которого является разработка стандартов контейнеризации. В настоящее время в проекте участвуют такие компании, как Google, RedHat, Microsoft и др. OCI поддерживает спецификации [image-spec](https://github.com/opencontainers/image-spec) (формат образов) и [runtime-speс](https://github.com/opencontainers/runtime-spec) (`Container Runtime`).

<div align="center">
  <img src="images/docker_exchange_schema.svg" width="1000" title="Docker exchange schema"/>
  <p style="text-align: center">
    Рисунок 2 &ndash; Взаимодействие с Docker
  </p>
</div>

#### Подсказки перед практикой

На практике при работе с контейнерами могут быть полезны следующие советы:
- Простейший сценарий &ndash; скачать образ, создать контейнер и запустить его (выполнить команду внутри запущенного контейнера).
- Документацию по запуску контейнера (путь к образу и необходимые команды с ключами) как правило можно найти в реестре образов (например, у `Docker Hub` есть очень удобный поисковик) или в `ReadMe` репозитория с исходным кодом проекта.
  > Создать образ и сохранить его в публичный реестр может практически каждый, поэтому старайтесь пользоваться только официальной документацией и проверенными образами!
- Для скачивания образов используется команда `pull`, однако в целом она необязательна &ndash; при выполнении большинства команд (`create`, `run` и др.) образ скачается автоматически, если не будет обнаружен локально.
- При выполнении команд `pull`, `create`, `run` и др. следует указывать репозиторий и тег образа. Если этого не делать, то будут использоваться значения по умолчанию &ndash; репозиторий как правило `docker.io`, а тег `latest`.
- При запуске контейнера выполняется команда по умолчанию (точка входа), однако можно выполнить и другую команду.

### 1.3 Работа с Docker

Docker &ndash; это открытая платформа для разработки, доставки и запуска приложений. Состоит из утилиты командной строки `docker`, которая вызывает одноименный сервис (сервис является потенциальной единой точкой отказа) и требует права доступа `root`. По умолчанию использует в качестве `Container Runtime` `runc`. Все файлы Docker (образы, контейнеры и др.) по умолчанию хранятся в каталоге `/var/lib/docker`.

Для установки необходимо воспользоваться официальным руководством &ndash; [Download and install Docker](https://docs.docker.com/get-started/#download-and-install-docker), которое содержит подробные инструкции для Linux, Windows и Mac. Стоит сразу отметить, что контейнерам для работы необходимы функции ядра Linux, поэтому они работают нативно под Linux, почти нативно в последних версиях Windows благодаря WSL2 (через `Docker Desktop` или Linux дистрибутив) и не нативно под Mac (используется виртуализация). Рекомендуется использовать в тестовой и особенно в промышленной эксплуатации только Linux.

#### Краткий гайд по установке Docker на Ubuntu

Удаляем старые версии:

```bash
sudo apt remove docker docker-engine docker.io containerd runc
```

Добавляем репозиторий:

```bash
sudo apt update
sudo apt install ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Устанавливаем `Docker Engine`:

```bash
sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

Проверяем работоспособность с использованием образа `hello-world`:

```bash
sudo docker run hello-world
```

Запуск докера без запроса прав рута:
- создаем группу пользователей `docker`
- добавляем себя в эту группу
- устанавливаем владельца файла `.docker` в папке юзера
- устанавливаем права доступа файлу `.docker`

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
sudo chmod g+rwx "$HOME/.docker" -R
```

Необходимо разлогиниться и залогиниться обратно. Проверка:

```bash
docker run hello-world
```

#### Основные команды

Справочная информация:
- Список доступных команд
  ```bash
  docker --help
  ```
- Информация по команде
  ```bash
  docker <command> --help
  ```
- Версия Docker
  ```bash
  docker --version
  ```
- Общая информация о системе
  ```bash
  docker info
  ```
 
#### Работа с образами

- Поиск образов по ключевому слову `debian`
  ```bash
  docker search debian
  ```
- Скачивание последней версии (тег по умолчанию `latest`) официального образа `ubuntu` (издатель не указывается) из репозитория по умолчанию `docker.io/library`
  ```bash
  docker pull ubuntu
  ```
- Скачивание последней версии (`latest`) образа `prometheus` от издателя `prom` из репозитория `docker.io/prom`
  ```bash
  docker pull prom/prometheus
  ```
- Скачивание из репозитория `docker.io` официального образа `ubuntu` с тегом `18.04`
  ```bash
  docker pull docker.io/library/ubuntu:18.04
  ```
- Просмотр локальных образов
  ```bash
  docker images
  ```
- Удаление образа
  ```bash
  docker rmi image_name:tag
  ```
  > Вместо `image_name:tag` можно указать `image_id`. Для удаления образа все контейнеры на его основе должны быть как минимум остановлены.
- Удаление всех образов
  ```bash
  docker rmi $(docker images -aq)
  ```
 
#### Работа с контейнерами

- Запуск `Hello, world!` в мире контейнеров
  ```bash
  docker run hello-world
  ```
- Запуск контейнера `ubuntu` и выполнение команды `bash` в интерактивном режиме
  ```bash
  docker run -it ubuntu bash
  ```
- Запуск контейнера `getting-started` с отображением (маппингом) порта $8080$ хоста на порт $80$ внутрь контейнера
  ```bash
  docker run --name docker-getting-started --publish 8080:80 docker/getting-started
  ```
- Запуск контейнера `mongodb` с именем `mongodb` в фоновом режиме
  ```bash
  docker run --detach --name mongodb docker.io/library/mongo:4.4.10
  ```
  > Данные будут удалены при удалении контейнера!
- Просмотр запущенных контейнеров
  ```bash
  docker ps
  ```
- Просмотр всех контейнеров (в том числе остановленных)
  ```bash
  docker ps -a
  ```
- Просмотр статистики
  ```bash
  docker stats --no-stream
  ```
- Создание контейнера из образа alpine
  ```bash
  docker start alpine
  ```
- Запуск созданного контейнера
  ```bash
  docker start container_name
  ```
  > Вместо `container_name` можно указать `container_id`
- Запуск всех созданных контейнеров
  ```bash
  docker start $(docker ps -a -q)
  ```
- Остановка контейнера
  ```bash
  docker stop container_name
  ```
  > Вместо `container_name` можно указать `container_id`.
- Остановка всех контейнеров
  ```bash
  docker stop $(docker ps -a -q)
  ```
- Удаление контейнера
  ```bash
  docker rm container_name
  ```
  > Вместо <container_name> можно указать `container_id`.
- Удаление всех контейнеров
  ```bash
  docker rm $(docker ps -a -q)
  ```
 
#### Информация о системе

- Общая информация о системе (соответствует `docker info`)
  ```bash
  docker system info
  ```
- Занятое место на диске
  ```bash
  docker system df
  ```
- Удаление неиспользуемых данных и очистка диска
  ```bash
  docker system prune -af
  ```

### 1.4 Хранение данных

При запуске контейнер получает доступ на чтение ко всем слоям образа, а также создает свой исполняемый слой с возможностью создавать, обновлять и удалять файлы. Все эти изменения не будут видны для файловой системы хоста и других контейнеров, даже если они используют тот же базовый образ. При удалении контейнера все измененные данные так же будут удалены. В большинстве случаев это предпочтительное поведение, однако иногда данные необходимо расшарить между несколькими контейнерами или просто сохранить.

Рассмотрим два способа хранения данных контейнеров:
 - [named volumes](https://docs.docker.com/get-started/05_persisting_data/) &ndash; именованные тома хранения данных.  
   Позволяет сохранять данные в именованный том, который располагается в каталоге `/var/lib/docker/volumes` и не удаляется при удалении контейнера. Том может быть подключен к нескольким контейнерам.
 - [bind mount](https://docs.docker.com/get-started/06_bind_mounts/) &ndash; монтирование каталога с хоста.  
   Позволяет монтировать файл или каталог с хоста в контейнер. На практике используется для проброса конфигурационных файлов или каталога БД внутрь контейнера (БД живет в файловой системе хоста).

Справочная информация об использовании `command`:

```bash
docker command --help
```

#### Пример использования `named volume`

- Запуск контейнера `jenkins` с подключением каталога `/var/jenkins_home` как тома `jenkins_home`
  ```bash
  docker run --detach --name jenkins --publish 80:8080 --volume=jenkins_home:/var/jenkins_home/ jenkins/jenkins:lts-jdk11
  ```
- Просмотр томов
  ```bash
  docker volume ls
  ```
- Удаление неиспользуемых томов и очистка диска
  ```bash
  docker volume prune
  ```
  > Для удаления тома все контейнеры, в которых он подключен, должны быть остановлены и удалены.

#### Пример использования `bind mount`

- Запуск контейнера `node-exporter` с монтированием каталогов внутрь контейнера в режиме `read only`: `/proc` хоста прокидывается в `/host/proc:ro` внутрь контейнера, `/sys` &ndash; в `/host/sys:ro`, а `/` &ndash; в `/rootfs:ro`
  ```bash
  docker run \
  -p 9100:9100 \
  -v "/proc:/host/proc:ro" \
  -v "/sys:/host/sys:ro" \
  -v "/:/rootfs:ro" \
  --name node-exporter prom/node-exporter:v1.1.2
  ```

Подробнее: [Хранение данных в Docker](https://habr.com/ru/company/southbridge/blog/534334/)

### 1.5 Создание образа с использованием Dockerfile

Создание и распространение образов &ndash; одна из основных задач Docker. Рассмотрим два способа создания образа:
 - commit изменений из контейнера.  
   Необходимо запустить контейнер из базового образа в интерактивном режиме, внести изменения и сохранить результат в образ с помощью команды `commit`. На практике способ удобен для небольших быстрых доработок.
 - декларативное описание через `Dockerfile`.  
   Основной способ создания образов. Необходимо создать файл `Dockerfile` с декларативным описанием в формате `yaml` через текстовый редактор и запустить сборку образа командой `build`.

#### Пример с использованием `commit`

- Запуск контейнера из образа `ubuntu` в интерактивном режиме, установка утилиты `ping` и коммит образа под именем `ubuntu-ping:20.04`
  ```bash
  docker run -it --name ubuntu-ping ubuntu:20.04 bash
  apt update && apt install -y iputils-ping
  exit
  docker commit ubuntu-ping ubuntu-ping:20.04
  docker images
  ```

#### Пример с использованием `Dockerfile`

Содержимое `Dockerfile`:

```dockerfile
# Dockerfile
FROM ubuntu:20.04
RUN apt update && apt install -y iputils-ping
```

Запуск команды `build` из каталога с `Dockerfile` для создания образа `ubuntu-ping:20.04`:

```bash
docker build -t ubuntu-ping:20.04 .
docker images
```

Создание из локального образа `ubuntu-ping:20.04` тега с репозиторием для издателя `alex`:

```bash
# tag, login, push
docker tag ubuntu-ping:20.04 alex/ubuntu-ping:20.04 # 
docker images
```

Вход в репозиторий `docker.io` под пользователем `alex` и публикование образа:

```bash
docker login -u alex docker.io
docker push alex/ubuntu-ping:20.04
```

Подробнее: [Изучаем Docker, часть 3: файлы Dockerfile](https://habr.com/ru/company/ruvds/blog/439980/)

### 1.6 Пример

Сборка OpenCV из исходников.

Скрипт для установки переменных `build_env.sh`:

```bash
#!/bin/sh
# Read in the file of environment settings

export py3_ver_mm_wod=$(python3 -c "import sys; print(\"\".join(map(str, sys.version_info[:2])))")
export py3_ver_mm=$(python3 -c "import sys; print(\".\".join(map(str, sys.version_info[:2])))")
export py3_ver_mmm=$(python3 -c "import sys; print(\".\".join(map(str, sys.version_info[:3])))")
echo "Environment vars for OpenCV build: ${py3_ver_mm_wod} ${py3_ver_mm} ${py3_ver_mmm}"

# Then run the CMD
# exec "$@"
```

Добавим права на выполнение:

```bash
chmod +x build_env.sh
```

Докер-файл `OpenCVDockerFile`:

```dockerfile
FROM ubuntu:20.04
WORKDIR /
# Update and upgrade
RUN apt update && apt -y upgrade

# Create dir

RUN mkdir /usr/local/Dev

# Python 3
RUN apt install -y curl python3-testresources python3-dev wget gnupg2 software-properties-common
WORKDIR /usr/local/Dev/
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
RUN python3 get-pip.py

# OpenCV x.x.x with non free modules

RUN echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections

## GStreamer

RUN apt -y install libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-doc gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio
RUN apt -y install ubuntu-restricted-extras libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-bad1.0-dev libgstreamer-plugins-bad1.0-0 libgstreamer-plugins-base1.0-0 libgstreamer-plugins-base1.0-dev

## OpenCV build dependencies

RUN apt -y install build-essential
RUN apt -y install cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev
RUN apt -y install python-dev python-numpy libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev
RUN apt -y install python3-pip python3-numpy

## OpenCV

RUN apt -y install build-essential cmake unzip pkg-config
RUN apt -y install libjpeg-dev libpng-dev libtiff-dev
RUN apt -y install libavcodec-dev libavformat-dev libswscale-dev libv4l-dev
RUN apt -y install libxvidcore-dev libx264-dev
RUN apt -y install libgtk-3-dev
RUN apt -y install libatlas-base-dev gfortran
RUN apt -y install python3-dev

ARG ocv_ver

RUN wget -O opencv.zip https://github.com/opencv/opencv/archive/${ocv_ver}.zip
RUN wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/${ocv_ver}.zip
RUN unzip opencv.zip
RUN unzip opencv_contrib.zip

COPY build_env.sh /usr/local/Dev
RUN chmod +x /usr/local/Dev/build_env.sh
RUN cd /usr/local/Dev/ && ./build_env.sh

WORKDIR /usr/local/Dev/opencv-${ocv_ver}
RUN mkdir build
WORKDIR /usr/local/Dev/opencv-${ocv_ver}/build

### Update numpy

RUN pip3 install -U numpy

RUN . /usr/local/Dev/build_env.sh && cmake -D CMAKE_BUILD_TYPE=RELEASE \
-D CMAKE_INSTALL_PREFIX=/usr/local/OpenCV-${ocv_ver} \
-D OPENCV_SKIP_PYTHON_LOADER=OFF \
-D OPENCV_PYTHON3_INSTALL_PATH=/usr/local/OpenCV-${ocv_ver}/lib/python${py3_ver_mm}/site-packages \
-D OPENCV_PYTHON3_VERSION=${py3_ver_mmm} \
-D BUILD_opencv_python2=OFF \
-D BUILD_opencv_python3=ON \
-D BUILD_opencv_python_bindings_generator=ON \
-D PYTHON_DEFAULT_EXECUTABLE=$(which python3) \
-D PYTHON3_EXECUTABLE=$(which python3) \
-D PYTHON3_INCLUDE_DIR=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
-D PYTHON3_PACKAGES_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
-D PYTHON3_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython${py3_ver_mmm}.so \
-D PYTHON3_NUMPY_INCLUDE_DIRS=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")/numpy/core/include \
-D WITH_OPENCL=ON \
-D WITH_OPENMP=ON \
-D WITH_CUDA=OFF \
-D WITH_CUDNN=OFF \
-D WITH_NVCUVID=OFF \
-D WITH_CUBLAS=OFF \
-D WITH_GSTREAMER=ON \
-D ENABLE_FAST_MATH=1 \
-D CUDA_FAST_MATH=0 \
-D BUILD_opencv_cudacodec=OFF \
-D INSTALL_PYTHON_EXAMPLES=ON \
-D INSTALL_C_EXAMPLES=ON \
-D OPENCV_ENABLE_NONFREE=ON \
-D OPENCV_EXTRA_MODULES_PATH=/usr/local/Dev/opencv_contrib-${ocv_ver}/modules \
-D BUILD_EXAMPLES=ON ..

RUN make -j${build_thread_count}
RUN make install
RUN ldconfig

RUN . /usr/local/Dev/build_env.sh && ln -sf /usr/local/OpenCV-${ocv_ver}/lib/python$py3_ver_mm/site-packages/cv2/python-${py3_ver_mm}/$(ls /usr/local/OpenCV-${ocv_ver}/lib/python$py3_ver_mm/site-packages/cv2/python-${py3_ver_mm}/) /usr/local/lib/python${py3_ver_mm}/dist-packages/cv2.so

RUN echo $(python3 -c "import cv2 as cv; print(cv.__version__)")

CMD [ "bash" ]
```

Скрипт для сборки `build_ocv_ubuntu_20.04.sh` (`chmod +x`):

```bash
echo Setting env vars

export ocv_ver=4.5.0

echo Building docker
docker build --tag ocv_ubuntu_20.04 --build-arg ocv_ver=$ocv_ver --build-arg build_thread_count=8 -f OpenCVDockerFile .
```

Запускаем процесс сборки:

```bash
./build_ocv_ubuntu_20.04.sh
```