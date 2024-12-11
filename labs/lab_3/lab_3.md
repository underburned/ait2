# Лабораторная работа №3. Клиент-серверное приложение с использованием Docker

Лекции:
- [SSH](../../lectures/lecture_0/lecture_0.md)
- [Контейнеризация. Docker](../../lectures/lecture_1/lecture_1.md)
- [Мультиконтейнерные приложения. Docker Compose](../../lectures/lecture_2/lecture_2.md)
- [Клиент-серверное приложение с использованием Docker](lectures/lecture_3/lecture_3.md) **[WIP]**

## Задание

### Подготовительный этап.

Пробрасывание порта из контейнера можно потестить TCP-соединением через `exposed port`: поднять простенький контейнер (с установленным `net-tools`; через docker или docker compose) с заданной сетью, на самом сервере в терминале выполнить команду:

```bash
nmap -p <exposed port> <container local IP>
```

Если ок, то попробовать пинги со своей машины до itkubrik.ru:<exposed port> (эти порты должны быть открыты, но все равно можно проверить).

> Локальный порт внутри контейнера может быть любой, как и IP адрес. Exposed порт и remote port совпадают, дабы не было путаницы.

Пример успешного вывода (Linux):

```bash
$ nmap -p <port> itkubrik.ru
Starting Nmap 7.80 ( https://nmap.org ) at 2024-12-11 09:19 UTC
Nmap scan report for itkubrik.ru (xxx.xxx.xxx.xxx)
Host is up (0.046s latency).

PORT      STATE SERVICE
<port>/tcp open  unknown

Nmap done: 1 IP address (1 host up) scanned in 0.54 seconds
```

Ключевое &ndash; ***state: open***. В случае неуспеха (порт закрыт) значение `state` будет `closed`.

В Windows можно воспользоваться PowerShell'ом:

```powershell
Test-NetConnection -Port <exposed port> -ComputerName itkubrik.ru -InformationLevel Detailed

ComputerName            : itkubrik.ru
RemoteAddress           : xxx.xxx.xxx.xxx
RemotePort              : xxxxx
NameResolutionResults   : xxx.xxx.xxx.xxx
MatchingIPsecRules      :
NetworkIsolationContext : Internet
IsAdmin                 : False
InterfaceAlias          : Ethernet
SourceAddress           : 10.0.0.2
NetRoute (NextHop)      : 10.0.0.1
TcpTestSucceeded        : True
```

Желаемый результат: `TcpTestSucceeded: True`. Если порт закрыт, то `False`.

### Боевая задача.

Цель &ndash; создание клиент-серверного приложения удаленной обработки данных.  
В качестве тонкого клиента приложения будет выступать десктопный графический интерфейс, реализуемый с использованием фреймворка Qt (PyQt6). Данное приложение должно реализовать следующий функционал:
- загрузка исходных данных (например, изображения) и их отображение в GUI
- передача загруженных данных на сервер для последующей обработки
- получение обработанных данных
- вывод пользователю сообщения о завершении обработки и отображение результатов в GUI

Серверная часть должна реализовать следующий функционал внутри докер-контейнера:
- прием данных на обработку
- обработка данных
- передача обработанных данных обратно клиенту  

Концептуальная схема приложения изображена на рисунке 1.

<div align="center">
  <img src="../../lectures/lecture_3/images/client_server_docker_app_1.svg" width="1000" title="Client-server app architecture"/>
  <p style="text-align: center">
    Рисунок 1 &ndash; Концептуальная схема приложения
  </p>
</div>

Взаимодействие между клиентом и сервером должно осуществляться в асинхронном режиме. Для этого будет использоваться ***брокер сообщений***, экземпляры которого будут общаться через SSH туннель. Более подробная схема изображена на рисунке 2.

<div align="center">
  <img src="../../lectures/lecture_3/images/client_server_docker_app_2.svg" width="1000" title="Client-server app architecture"/>
  <p style="text-align: center">
    Рисунок 2 &ndash; Схема взаимодействия основных модулей
  </p>
</div>

> Вместо десктопного GUI и/или схемы с брокером сообщений можно реализовать Web-интерфейс с использованием REST API. Серверная часть должна быть реализована в докер-образе и запущена в контейнере.