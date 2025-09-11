# Технологии искусственного интеллекта. Семестр 2

© Петров М.В., старший преподаватель кафедры киберфотоники, Самарский университет

## Лекция 1. Организация удаленного доступа с использованием SSH

### Содержание

1. [Введение](#11-введение)
2. [SSH-сервер](#12-ssh-сервер)
3. [SSH-клиенты](#13-ssh-клиенты)
4. [Файлы настроек SSH](#14-файлы-настроек-ssh)
5. [Генерация ключей](#15-генерация-ключей)
6. [Настройка сервера и клиента](#16-настройка-сервера-и-клиента)
7. [Настройка файервола UFW](#17-настройка-файервола-ufw)
8. [Туннелирование SSH](#18-туннелирование-ssh)
9. [Обратное туннелирование SSH](#19-обратное-туннелирование-ssh)
10. [Файл конфигурации config](#110-файл-конфигурации-config)
11. [Разное](#111-разное)

### 1.1 Введение

Источники:
- [SSH @ Википедия](https://ru.wikipedia.org/wiki/SSH)
- [OpenSSH @ Википедия](https://ru.wikipedia.org/wiki/OpenSSH)
- [Знакомство с SSH @ Хабр](https://habr.com/ru/articles/802179/)
- [Памятка пользователям ssh @ Хабр](https://habr.com/ru/articles/122445/)
- [Настройка SSH сервера в Windows](https://winitpro.ru/index.php/2019/10/17/windows-openssh-server/)
- [Как установить и настроить SSH](https://help.reg.ru/support/servery-vps/oblachnyye-servery/rabota-s-serverom/kak-ustanovit-i-nastroit-ssh)
- [Лучшие SSH-клиенты для Windows, Linux и macOS](https://timeweb.com/ru/community/articles/luchshie-ssh-klienty-dlya-windows-linux-i-macos)

***SSH*** (***Secure Shell*** &ndash; "безопасная оболочка") &ndash; сетевой протокол прикладного уровня, позволяющий производить удалённое управление операционной системой и туннелирование *TCP*-соединений (например, для передачи файлов). Схож по функциональности с протоколами *Telnet* и *rlogin*, но, в отличие от них, шифрует весь трафик, включая и передаваемые пароли. SSH допускает выбор различных алгоритмов шифрования. SSH-клиенты и SSH-серверы доступны для большинства сетевых операционных систем.  

SSH-сервер обычно прослушивает соединения на TCP-порту $22$. Для аутентификации сервера в SSH используется протокол аутентификации сторон на основе алгоритмов электронно-цифровой подписи, но допускается также аутентификация при помощи пароля (режим обратной совместимости с Telnet) и даже IP-адреса хоста (режим обратной совместимости с rlogin).  

Поддерживается 3 режима аутентификации:
- Аутентификация по паролю.  
  Наиболее распространенный вариант. Вводить пароль необходимо при каждом подключении. Пароль передается в зашифрованном виде.  
- Аутентификация по ключевой паре.  
  Предварительно генерируется *публичный (открытый)* и *приватный (закрытый)* ключи (`pulic key` и `private key`) для определённого пользователя. На машине, с которой требуется произвести подключение к удаленному хосту, хранится приватный и публичный ключи, а на удалённой машине &ndash; только публичный. Эти файлы не передаются при аутентификации, система лишь проверяет, что владелец публичного ключа также владеет и приватным. При данном подходе, как правило, настраивается автоматический вход от имени конкретного пользователя в ОС.
- Аутентификация по IP-адресу.  
  Аутентификация по IP-адресу небезопасна из-за риска подмены адреса, эту возможность чаще всего отключают.  

<div align="center">
  <img src="images/SSH_schema.svg" width="800" title="SSH"/>
  <p style="text-align: center">
    Рисунок 1 &ndash; SSH соединения
  </p>
</div>

SSH обеспечивает безопасность соединения с удалённой машиной с использованием современных алгоритмов шифрования. Вся пересылаемая информация между узлами находится внутри зашифрованного туннеля.

### 1.2 SSH-сервер

В Linux системах обычно используется пакет ***OpenSSH***, где сервер обозначается ***sshd***, что означает *SSH демон* (*SSH Daemon*). Клиент SSH &ndash; ***ssh***. Все необходимые настройки для клиента и сервера в Linux системах обычно хранятся в директории `/etc/ssh/`. По префиксу имени файла можно догадаться, к клиенту или серверу имеет отношение файл настройки. Все настройки имеют глобальный характер, т.е. актуальны для всех пользователей устройства.

> *Де́мон (daemon)* &ndash; компьютерная программа в UNIX-подобных системах, запускаемая самой системой и работающая в фоновом режиме без прямого взаимодействия с пользователем. Типичные задачи демонов: серверы сетевых протоколов (HTTP, FTP, электронная почта и др.), управление оборудованием, поддержка очередей печати, управление выполнением заданий по расписанию и т. д. В техническом смысле демоном считается процесс, который не имеет управляющего терминала.

> ***OpenSSH*** (*Open Secure Shell* &ndash; открытая безопасная оболочка) &ndash; набор программ, предоставляющих шифрование сеансов связи по компьютерным сетям с использованием протокола SSH. Он был создан под руководством Тео де Раадта как открытая альтернатива проприетарного ПО от SSH Communications Security.

Кроме глобальных настроек, каждый из пользователей может хранить свою конфигурацию в домашней директории в папке `~/.ssh/`. Файлы используются как клиентом SSH, так и при подключении к серверу из папки пользователя, который указан при подключении.

Стандартный конфиг `/etc/ssh/sshd_config` для ОС `Ubuntu 22.04`:
```bash

# This is the sshd server system-wide configuration file.  See
# sshd_config(5) for more information.

# This sshd was compiled with PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games

# The strategy used for options in the default sshd_config shipped with
# OpenSSH is to specify options with their default value where
# possible, but leave them commented.  Uncommented options override the
# default value.

Include /etc/ssh/sshd_config.d/*.conf

#Port 22
#AddressFamily any
#ListenAddress 0.0.0.0
#ListenAddress ::

#HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_ecdsa_key
#HostKey /etc/ssh/ssh_host_ed25519_key

# Ciphers and keying
#RekeyLimit default none

# Logging
#SyslogFacility AUTH
#LogLevel INFO

# Authentication:

#LoginGraceTime 2m
#PermitRootLogin prohibit-password
#StrictModes yes
#MaxAuthTries 6
#MaxSessions 10

#PubkeyAuthentication yes

# Expect .ssh/authorized_keys2 to be disregarded by default in future.
#AuthorizedKeysFile	.ssh/authorized_keys .ssh/authorized_keys2

#AuthorizedPrincipalsFile none

#AuthorizedKeysCommand none
#AuthorizedKeysCommandUser nobody

# For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
#HostbasedAuthentication no
# Change to yes if you don't trust ~/.ssh/known_hosts for
# HostbasedAuthentication
#IgnoreUserKnownHosts no
# Don't read the user's ~/.rhosts and ~/.shosts files
#IgnoreRhosts yes

# To disable tunneled clear text passwords, change to no here!
#PasswordAuthentication yes
#PermitEmptyPasswords no

# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
KbdInteractiveAuthentication no

# Kerberos options
#KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
#KerberosGetAFSToken no

# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes
#GSSAPIStrictAcceptorCheck yes
#GSSAPIKeyExchange no

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the KbdInteractiveAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via KbdInteractiveAuthentication may bypass
# the setting of "PermitRootLogin without-password".
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and KbdInteractiveAuthentication to 'no'.
UsePAM yes

#AllowAgentForwarding yes
#AllowTcpForwarding yes
#GatewayPorts no
X11Forwarding yes
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes
PrintMotd no
#PrintLastLog yes
#TCPKeepAlive yes
#PermitUserEnvironment no
#Compression delayed
#ClientAliveInterval 0
#ClientAliveCountMax 3
#UseDNS no
#PidFile /run/sshd.pid
#MaxStartups 10:30:100
#PermitTunnel no
#ChrootDirectory none
#VersionAddendum none

# no default banner path
#Banner none

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

# override default of no subsystems
Subsystem	sftp	/usr/lib/openssh/sftp-server

# Example of overriding settings on a per-user basis
#Match User anoncvs
#	X11Forwarding no
#	AllowTcpForwarding no
#	PermitTTY no
#	ForceCommand cvs server
```

В состав OpenSSH входят следующие компоненты:
- `ssh`  
  Замена для rlogin и telnet.
- `scp`  
  Замена для rcp, использующая в современных версиях OpenSSH протокол ***SFTP*** (ранее использовался менее надёжный и гибкий *SCP*).
- `sftp`  
  Замена для FTP-клиента, использующая протокол SFTP.
- `sshd` 
  Демон, собственно предоставляющий защищённый доступ к ресурсам. Включает реализацию серверной части SFTP, пригодную для организации chroot-доступа для пользователей без необходимости копирования каких-либо файлов внутрь `chroot`.
- `sftp-server`  
  Отдельная реализация подсистемы SFTP (серверная часть). Обладает бо́льшими возможностями, чем встроенная в sshd.
- `ssh-keygen`  
  Генератор пар ключей.
- `ssh-keysign`  
  Утилита для проверки ключей хостов. Задействуется при использовании аутентификации по хостам (аналогично `rsh`) вместо проводимой по умолчанию аутентификации по пользователям.
- `ssh-keyscan`  
  Вспомогательная утилита. Позволяет собирать публичные ключи с других хостов.
- `ssh-agent`  
  Вспомогательная утилита. Поддерживает кэш закрытых ключей. Кэширование позволяет избегать частого ввода пароля для расшифровки ключей перед их использованием.
- `ssh-add`  
  Вспомогательная утилита. Добавляет ключи в кэш `ssh-agent`.

#### Установка в Linux

В большинстве дистрибутивов OpenSSH-сервер уже присутствует в системе, и его установка не требуется. В случае отсутствия OpenSSH в терминале необходимо выполнить следующую команду:

```bash
sudo apt install openssh-server -y
```

В случае отсутствия установленного OpenSSH в ОС необходимо добавить SSH-сервер в автозагрузку. При следующем запуске сервера операционная система выполнит автоматический запуск SSH-сервера. Как и в случае с другими сервисами, `systemd` позволяет управлять параметрами запуска, автозагрузки и рестарта демона OpenSSH.

> `systemd` &ndash; подсистема инициализации и управления службами в Linux. Основная особенность &ndash; интенсивное распараллеливание запуска служб в процессе загрузки системы, что позволяет существенно ускорить запуск операционной системы. Основная единица управления &ndash; модуль, одним из типов модулей являются «службы» (service) &ndash; аналог демонов &ndash; наборы процессов, запускаемые и управляемые средствами подсистемы и изолируемые контрольными группами.

Включим автозапуск:

```bash
sudo systemctl enable sshd
```

Проверка работы SSH:

```bash
systemctl status sshd
```

Пример вывода:

```bash
ud@srv340:~$ systemctl status sshd
● ssh.service - OpenBSD Secure Shell server
     Loaded: loaded (/usr/lib/systemd/system/ssh.service; enabled; preset: enabled)
     Active: active (running) since Thu 2025-08-28 22:57:12 +04; 1 week 5 days ago
TriggeredBy: ● ssh.socket
       Docs: man:sshd(8)
             man:sshd_config(5)
   Main PID: 1859 (sshd)
      Tasks: 1 (limit: 76646)
     Memory: 6.1M (peak: 7.9M)
        CPU: 411ms
     CGroup: /system.slice/ssh.service
             └─1859 "sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups"
```

#### Установка в Windows

Пакет OpenSSH Server включен в современные версии Windows 10 (начиная с 1803), Windows 11 и Windows Server в виде Feature on Demand (FoD).

 - Способ 1. С использованием `PowerShell`  
   Для установки сервера OpenSSH достаточно выполнить в `PowerShell` команду (`PowerShell` необходимо запустить с правами администратора):
   ```powershell
   Get-WindowsCapability -Online | Where-Object Name -like ‘OpenSSH.Server*’ | Add-WindowsCapability –Online
   ```
 - Способ 2. С использованием командной строки (терминала)  
   В командной строке или терминале выполнить следующую команду (тоже с правами администратора):
   ```batch
   dism /Online /Add-Capability /CapabilityName:OpenSSH.Server~~~~0.0.1.0
   ```
 - Способ 3. С использованием панели Параметры  
   Также возможно установить сервер OpenSSH в Windows через современную панель Параметры: Приложения &rarr; Управление дополнительными компонентами &rarr; Добавить компонент ((Settings &rarr; Apps and features &rarr; Optional features &rarr; Add a feature). Необходимо найти в списке OpenSSH Server и нажать кнопку Установить (Install).
   > В инкрементальных мажорных обновлениях Windows 11 легко запутаться, некоторые настройки запрятаны в интуитивно непонятных (user unfriendly) разделах, так что проще использовать команды в cmd/powershell.

### 1.3 SSH-клиенты

Существует множество различных SSH-клиентов и комбайнов под разные семейства ОС.  

#### Windows

В Windows наиболее популярными клиентами являются:
- [PuTTY](https://www.putty.org/).  
  Свободно распространяемый клиент для различных протоколов удалённого доступа, включая SSH, Telnet, rlogin. Также имеется возможность работы через последовательный порт.  
  
  <div align="center">
    <br>
    <img src="images/PuTTY.png" width="452" title="PuTTY"/>
      <p style="text-align: center">
          Рисунок 2 &ndash; PuTTY
      </p>
  </div>
- [WinSCP](https://winscp.net/eng/docs/lang:ru)  
  Свободный графический клиент протоколов SFTP и SCP, предназначенный для Windows. Распространяется по лицензии GNU GPL. Обеспечивает защищённое копирование файлов между компьютером и серверами, поддерживающими эти протоколы.
    
  <div align="center">
    <br>
    <img src="images/WinSCP.png" width="946" title="WinSCP"/>
      <p style="text-align: center">
          Рисунок 3 &ndash; WinSCP
      </p>
  </div>
- [MobaXterm](https://mobaxterm.mobatek.net/)  
  Многофункциональный SSH-клиент, полюбившийся пользователям за высокую скорость работы, комфортный интерфейс и кучу дополнительных функций, отсутствующих у конкурентов. В нем есть браузер файлов, встроенный XServer для управления графическим интерфейсом на удаленном компьютере, масса плагинов, расширяющих возможности клиента, и portable-версия, работающая без установки. Проект условно-бесплатный, в бесплатной версии (Home Edition) присутствует множество ограничений, например, максимально допустимое количество сохраняемых сессий &ndash; $12$.

  <div align="center">
    <br>
    <img src="images/MobaXterm.png" width="1184" title="MobaXterm"/>
      <p style="text-align: center">
          Рисунок 4 &ndash; MobaXterm
      </p>
  </div>

#### Linux

В UNIX-подобных операционных системах есть встроенная поддержка OpenSSH. Можно использовать базовый терминал для подключения к удаленному серверу и управлению им.  
Одним из распространенных комбайнов является [Remmina](https://remmina.org/). Поддерживает множество дистрибутивов: [How to install Remmina](https://remmina.org/how-to-install-remmina/).

#### MacOS

macOS поддерживает подключение по протоколу SSH прямо из встроенного терминала.

#### Кроссплатформа

- [Hyper](https://hyper.is/)  
  В отличие от других SSH-клиентов, этот не отличается какой-то специфичной функциональностью. Напротив, он практически полностью повторяет функциональность базовой командной строки. Поэтому пользователям он нравится не за обилие возможностей, а за простоту и симпатичный внешний облик. По словам разработчиков, это попытка создать максимально быстрый и надежный терминал. Это был их приоритет при разработке. При этом он построен на базе фреймворка Electron, что делает его универсальным и расширяемым.  
    
  <div align="center">
    <br>
    <img src="images/Hyper.png" width="540" title="Hyper"/>
      <p style="text-align: center">
          Рисунок 5 &ndash; Hyper
      </p>
  </div>
- [Tabby](https://tabby.sh/)  
  Терминал нового поколения (как его называют разработчики). Кроссплатформенный эмулятор терминала с поддержкой WSL, PowerShell, Cygwin, Clink, cmder, git-bash и десятка других технологий. Есть полезные опции, такие как восстановление закрытых вкладок из предыдущей сессии и кликабельные пути к директориям. Интерфейс Tabby можно настроить под себя с помощью разметки CSS. То же касается и функциональной составляющей. Ее можно расширить за счет сторонних плагинов, число которых постепенно растет.  

  <div align="center">
    <br>
    <img src="images/Tabby_1.png" width="800" title="Tabby"/>
      <p style="text-align: center">
          Рисунок 6 &ndash; Tabby
      </p>
    <br>
    <img src="images/Tabby_2.png" width="800" title="Tabby"/>
      <p style="text-align: center">
          Рисунок 7 &ndash; Tabby: SFTP
      </p>
    <br>
    <img src="images/Tabby_3.png" width="800" title="Tabby"/>
      <p style="text-align: center">
          Рисунок 8 &ndash; Tabby: автоматическое чтение настроек из "~/.ssh/config"
      </p>
  </div>
- [WindTerm](https://kingtoolbox.github.io/)  
  Бесплатный клиент для протоколов SSH/SFTP/Shell/Telnet/Serial. WindTerm полностью бесплатен как для коммерческого, так и некоммерческого использования. Весь опубликованный на текущий момент исходный код предоставляются на условиях лицензии Apache-2.0. Исключение составляет код сторонних разработчиков. WindTerm является проектом с частично открытым исходным кодом, и исходный код будет постепенно открываться.  
    
  <div align="center">
    <br>
    <img src="images/WindTerm_1.png" width="1228" title="WindTerm"/>
      <p style="text-align: center">
          Рисунок 9 &ndash; WindTerm
      </p>
    <br>
    <img src="images/WindTerm_2.png" width="1810" title="WindTerm"/>
      <p style="text-align: center">
          Рисунок 10 &ndash; WindTerm
      </p>
  </div>

### 1.4 Файлы настроек SSH

- Файл `config` &ndash; файл настройки клиента. Позволяет настраивать параметры соединений, чтобы не было необходимости каждый раз указывать опции для каждого конкретного сервера. Список возможных параметров можно посмотреть здесь: [SSH config file for OpenSSH client](https://www.ssh.com/academy/ssh/config).
- Файл `authorized_keys` содержит список публичных ключей для доступа к серверу sshd на этой машине (SSH-сервер).
- Файл `known_hosts` содержит список ключей для хостов, к которым ранее уже было произведено подключение. Это один из инструментов безопасности. При первом подключении к серверу клиент получает подпись его ключа доступа, которая в дальнейшем будет использоваться для проверки легитимности хоста. При повторном подключении эти данные позволяют проверить, что это именно тот сервер, к которому клиент подключался ранее.
- Файлы `id_*` (без расширения) содержат приватные ключи доступа для текущего устройства. Вместо `*` в имени файла как правило присутствует имя используемого алгоритма шифрования. Ключей может быть несколько, для каждого запрошенного алгоритма шифрования. Эти файлы должны храниться в полной секретности. Никому их передавать нельзя. На ключи доступа можно установить пароль, без которого невозможно будет воспользоваться этим ключом. В таком случае даже при утечке ключа воспользоваться им будет невозможно без знания пароля.
- Файлы `id_*.pub` содержат публичные ключи доступа, которые используются для подключения к другим устройствам. Вместо `*` в имени файла присутствует имя используемого алгоритма шифрования, которые предоставляет удалённое устройство при подключении. Ключей может быть несколько, например, для каждого доступного алгоритма шифрования.

Вообще, имена публичных ключей шифрования могут быть любыми. В этом случае при подключении нужно прямо указать путь к ключу при подключении к удалённой машине. Сделать это можно через параметры командной строки или через файл конфигурации `config`.

### 1.5 Генерация ключей

Свой ключ можно сгенерировать с помощью команды `ssh-keygen`:

```bash
usage: ssh-keygen [-q] [-a rounds] [-b bits] [-C comment] [-f output_keyfile]
                  [-m format] [-N new_passphrase] [-O option]
                  [-t dsa | ecdsa | ecdsa-sk | ed25519 | ed25519-sk | rsa]
                  [-w provider] [-Z cipher]
       ssh-keygen -p [-a rounds] [-f keyfile] [-m format] [-N new_passphrase]
                   [-P old_passphrase] [-Z cipher]
       ssh-keygen -i [-f input_keyfile] [-m key_format]
       ssh-keygen -e [-f input_keyfile] [-m key_format]
       ssh-keygen -y [-f input_keyfile]
       ssh-keygen -c [-a rounds] [-C comment] [-f keyfile] [-P passphrase]
       ssh-keygen -l [-v] [-E fingerprint_hash] [-f input_keyfile]
       ssh-keygen -B [-f input_keyfile]
       ssh-keygen -D pkcs11
       ssh-keygen -F hostname [-lv] [-f known_hosts_file]
       ssh-keygen -H [-f known_hosts_file]
       ssh-keygen -K [-a rounds] [-w provider]
       ssh-keygen -R hostname [-f known_hosts_file]
       ssh-keygen -r hostname [-g] [-f input_keyfile]
       ssh-keygen -M generate [-O option] output_file
       ssh-keygen -M screen [-f input_file] [-O option] output_file
       ssh-keygen -I certificate_identity -s ca_key [-hU] [-D pkcs11_provider]
                  [-n principals] [-O option] [-V validity_interval]
                  [-z serial_number] file ...
       ssh-keygen -L [-f input_keyfile]
       ssh-keygen -A [-a rounds] [-f prefix_path]
       ssh-keygen -k -f krl_file [-u] [-s ca_public] [-z version_number]
                  file ...
       ssh-keygen -Q [-l] -f krl_file [file ...]
       ssh-keygen -Y find-principals -s signature_file -f allowed_signers_file
       ssh-keygen -Y match-principals -I signer_identity -f allowed_signers_file
       ssh-keygen -Y check-novalidate -n namespace -s signature_file
       ssh-keygen -Y sign -f key_file -n namespace file [-O option] ...
       ssh-keygen -Y verify -f allowed_signers_file -I signer_identity
                  -n namespace -s signature_file [-r krl_file] [-O option]
```

Список поддерживаемых алгоритмов генерации ключей можно получить следующей командой:

```bash
ssh -Q key
```

Пример вывода:

```bash
$ ssh -Q key
ssh-ed25519
ssh-ed25519-cert-v01@openssh.com
sk-ssh-ed25519@openssh.com
sk-ssh-ed25519-cert-v01@openssh.com
ssh-rsa
ssh-dss
ecdsa-sha2-nistp256
ecdsa-sha2-nistp384
ecdsa-sha2-nistp521
sk-ecdsa-sha2-nistp256@openssh.com
ssh-rsa-cert-v01@openssh.com
ssh-dss-cert-v01@openssh.com
ecdsa-sha2-nistp256-cert-v01@openssh.com
ecdsa-sha2-nistp384-cert-v01@openssh.com
ecdsa-sha2-nistp521-cert-v01@openssh.com
sk-ecdsa-sha2-nistp256-cert-v01@openssh.com
```

> С выходом OpenSSH версии 8.2 алгоритм цифровой подписи SHA-1 для ключей `ssh-rsa` признан небезопасным, и ключи с такой подписью будут отвергаться SSH-сервером. Подробнее [здесь](https://www.openssh.com/txt/release-8.2) и на [StackExchange](https://security.stackexchange.com/questions/226131/openssh-declares-ssh-rsa-deprecated-what-do-i-do-next). При этом генерация RSA ключей с подписью SHA-2 вполне валидна (rsa-sha2-256/512).
> 
> В случае использования RSA ключей рекомендуется устанавливать длину ключа при его генерации не менее $2048$ бит. Ключи длиной $<1024$ бит [потенциально небезопасны](https://crypto.stackexchange.com/a/1982) в смысле взломостойкости. С увеличением длины ключа взломостойкость растет, как и накладные расходы для шифрования и дешифрования.

Список поддерживаемых алгоритмов обмена ключами (`key exchange algorithm`, он же `kex algorithm`) можно получить следующей командой:

```bash
ssh -Q kex
```

Пример вывода:

```bash
$ ssh -Q kex
diffie-hellman-group1-sha1
diffie-hellman-group14-sha1
diffie-hellman-group14-sha256
diffie-hellman-group16-sha512
diffie-hellman-group18-sha512
diffie-hellman-group-exchange-sha1
diffie-hellman-group-exchange-sha256
ecdh-sha2-nistp256
ecdh-sha2-nistp384
ecdh-sha2-nistp521
curve25519-sha256
curve25519-sha256@libssh.org
sntrup761x25519-sha512@openssh.com
```

Можно использовать следующий bash скрипт для вывода всей информации об установленном SSH сервере в консоль:

```bash
for F in $(ssh -Q help); do 
  printf "=== $F ===\n"
  ssh -Q $F
  echo ""
done
```

Или в файл:

```bash
#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
rm $SCRIPT_DIR/ssh_info.txt;
for F in $(ssh -Q help); do 
  cat <<EOF >> $SCRIPT_DIR/ssh_info.txt;
=== $F ===
$(ssh -Q $F);

EOF
done
```

Полный вывод: [файл](data/ssh_info.txt).

#### Генерация ключей

Для формирования пары ключей используется утилита `ssh-keygen`. По умолчанию она создаёт ключи формата `rsa`. На данный момент рекомендуется использовать ключи формата `ed25519`. Они более компактные и обеспечивают достаточный уровень защищённости:
- [SSH Key Algorithms: RSA vs ECDSA vs Ed25519](https://vulnerx.com/ssh-key-algorithms/)
- [SSH Key: Ed25519 vs RSA](https://security.stackexchange.com/questions/90077/ssh-key-ed25519-vs-rsa)
- [SSH keys: ed25519 vs RSA performance demystified](https://serverfault.com/a/1081277)
- [Is it bad that my ed25519 key is so short compared to a RSA key?](https://security.stackexchange.com/a/101045)
- [Ключи для SSH: ED25519 vs RSA](https://www.linux.org.ru/forum/general/16860562)

> Протестировать скорость генерации и верификации различных ключей можно с использованием [следующей команды](https://serverfault.com/a/1081277):
> ```bash
> openssl speed rsa1024 rsa2048 rsa3072 rsa4096 ecdsap256 ed25519
> ```
> Пример вывода:
> ```bash
>                               sign     verify    sign/s   verify/s
> rsa 1024 bits              0.000051s  0.000003s  19519.2  343435.5
> rsa 2048 bits              0.000330s  0.000010s   3033.5  101304.3
> rsa 3072 bits              0.001014s  0.000021s    986.0   47039.3
> rsa 4096 bits              0.002322s  0.000037s    430.6   26987.2
> 256 bits ecdsa (nistp256)  0.0000s    0.0000s    77459.1   25029.1
> 253 bits EdDSA (Ed25519)   0.0000s    0.0001s    47258.9   17520.1
> ```
 
> Алгоритм генерации ключа и алгоритм шифрования трафика в SSH туннеле не одно и то же! См. `ssh -Q cipher`.

Генерация ключа по умолчанию без параметров:

```bash
$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/home/ud/.ssh/id_rsa):
# При нажатии Enter используется путь и имя по умолчанию
Enter passphrase (empty for no passphrase):
# Можно запаролить ключ, тогда при аутентификации по ключу необходимо будет ввести еще и пароль
Enter same passphrase again:
# Повторный ввод пароля
Your identification has been saved in /home/ud/.ssh/id_rsa
Your public key has been saved in /home/ud/.ssh/id_rsa.pub
The key fingerprint is:
SHA256:4ZFo22kSiZjqTCJFEtTrgTM44pSiW6kc+Xp3mZqRVAI ud@udupc
The key's randomart image is:
+---[RSA 3072]----+
|+ooE             |
| o +.. o .       |
|. * o.=.+        |
|=O o .o= +       |
|Xo=...o S        |
|B+o.. .o         |
|.*o  o  o        |
|o. o .o+         |
| .o .oo          |
+----[SHA256]-----+
```

Генерация `RSA` ключа без использования интерактивного ввода (пустой пароль):

```bash
ssh-keygen -b 4096 -t rsa -f ~/.ssh/id_rsa_test -q -N ""
```

> - `-q` &ndash; "quiet" режим, отключает интерактивный ввод и вывод информации
> - `-N` &ndash; задает парольную фразу (поэтому в нашем случае вслед за аргументом указана пустая строка)

Генерация `ED25519` ключа без использования интерактивного ввода (пустой пароль):

```bash
ssh-keygen -t ed25519 -C me@gmail.com -f ~/.ssh/id_ed25519_test -q -N ""
```

> `-C` используется для записи комментария в публичный ключ с целью упрощения процесса сопровождения ключей, когда их много. Это может быть любая информация (назначение, имя хоста, id юзера). Часто в это поле записывают электронный адрес почты, чтобы различать пользователей, соединяющихся с сервером.

#### Просмотр информации о ключах

Публичный ключ:

```bash
ssh-keygen -lf ~/.ssh/id_ed25519_test.pub
```

Пример вывода (ключ `-l` выводит цифровой отпечаток &ndash; хэш ключа):

```bash
$ ssh-keygen -lf ~/.ssh/id_ed25519_test.pub
256 SHA256:vPOSokFEn0NE0Iii+cin23Ka6vASU46kGbXd0Qpg/2g me@gmail.com (ED25519)
```

`cat` просто выведет содержимое ключа в текстовом виде:

```bash
cat ~/.ssh/id_ed25519_test.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAFT2Q75/bUcDKvxcituNxg7D0l1Vjn7oKPleuzwXXbL me@gmail.com
```

`cat` для приватного ключа:

```bash
cat ~/.ssh/id_ed25519_test
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACABU9kO+f21HAyr8XIrbjcYOw9JdVY5+6Cj5Xrs8F12ywAAAJDXtDQN17Q0
DQAAAAtzc2gtZWQyNTUxOQAAACABU9kO+f21HAyr8XIrbjcYOw9JdVY5+6Cj5Xrs8F12yw
AAAEDxUG5NMEa4elb59N62EUBsL4OBxkx5S6BEvvM7/CEw5gFT2Q75/bUcDKvxcituNxg7
D0l1Vjn7oKPleuzwXXbLAAAADG1lQGdtYWlsLmNvbQE=
-----END OPENSSH PRIVATE KEY-----
```

Существуют [различные кодировки](https://www.ssl.com/guide/pem-der-crt-and-cer-x-509-encodings-and-conversions/) для ключей и сертификатов.

### 1.6 Настройка сервера и клиента

Рассмотрим настройку SSH на сервере и клиенте. Для сервера отключим возможность аутентификации с использованием пароля учетной записи, оставим возможность доступа только по SSH ключу. 

#### Настройка сервера

##### Шаг 1

Допустим, сервер в плане доступа через SSH настроен по умолчанию, т.е. допускается аутентификация с использованием пароля. Пусть имя юзера `alex`, имя хоста сервера `al-srv`. Проверим соединение командой `ssh <имя юзера>@<имя или IP хоста>`:

```bash
ssh alex@al-srv
```

Необходимо ввести пароль. Если успех, переходим к следующему шагу.

##### Шаг 2

Сгенерированный публичный ключ необходимо добавить на сервер. Для этого в домашней директории пользователя на сервере необходимо создать папку `.ssh` и установить права доступа к папке (`chmod`):

```bash
mkdir /home/alex/.ssh/
chmod 700 /home/ud/.ssh/
```

Публичный ключ с хоста клиента на сервер можно скопировать с помощью команды:

```bash
ssh-copy-id user@host
```

Если имеется несколько пар ключей, то можно указать какой конкретно ключ необходимо использовать:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519 user@host
```

Или скопировать через SFTP/SCP вручную.

Далее необходимо создать файл `~/.ssh/authorized_keys` и установить права доступа к нему:

```bash
cat /home/alex/.ssh/id_ed25519_alex.pub >> /home/alex/.ssh/authorized_keys
chmod 600 /home/alex/.ssh/authorized_keys
```

Если данные манипуляции выполняются из-под другой учетной записи (не `alex`), то нужно изменить владельца всей папки `.ssh`:

```bash
chown -R alex:alex /home/alex/.ssh/
```

##### Шаг 3

Далее необходимо отключить доступ по паролю на сервере. Отредактируем конфиг `sshd_config`.

> Изменение конфига, перезапуск службы `sshd` и прочие манипуляции по изменению параметров SSH не влияют на текущую SSH сессию. Прежде чем ее прерывать, следует убедиться, что все настроено правильно (осуществить проверку подключения через другую сессию). Иначе удаленный доступ к серверу будет потерян, придется перенастраивать SSH уже с непосредственным физическим доступом к нему.

Редактируем `sshd_config`:

```bash
sudo nano /etc/ssh/sshd_config
```

Содержимое:
```nano
Port 2222
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile /home/alex/.ssh/authorized_keys
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM no
```

Сохраняем изменения `Ctrl-O` и выходим `Ctrl-X`:

<div align="center">
  <br>
  <img src="images/nano_sshd.png" width="800" title="nano"/>
    <p style="text-align: center">
        Рисунок 11 &ndash; Редактор nano
    </p>
</div>

- `Port 2222`  
  Номер SSH порта рекомендуется изменить на любой нестандартный (стандартный &ndash; $22$).
- `PermitRootLogin no`  
  Запрет на подключение через SSH для учетной записи `root`.
  > С целью увеличения безопасности рекомендуется установить запрет на подключение через SSH учетной записи `root`, дабы не предоставлять `root`-доступ к серверу напрямую.
- `PubkeyAuthentication yes`  
  Включение режима аутентификации с использованием публичного ключа.
- `AuthorizedKeysFile /home/alex/.ssh/authorized_keys`  
  Путь к файлу `authorized_keys`.  
  > По умолчанию `sshd` просматривает пути `~/.ssh/authorized_keys` и `~/.ssh/authorized_keys2` в домашней директории пользователя. Если явно задать `AuthorizedKeysFile` с абсолютным путем, то в данный файл необходимо добавить *все необходимые ключи доступа для других пользователей*, ибо конфиг глобальный. Более тонкая настройка глобального конфига для разных пользователей: [Конфиг демона `sshd`](#конфиг-демона-sshd).
- `PasswordAuthentication no`  
  Запрет режима доступа по паролю.
- `KbdInteractiveAuthentication no`  
  Запрет интерактивного ввода с использованием клавиатуры.
- `UsePAM no`
  > C PAM разобраться сложнее, ежели интересно, можно начать отсюда:
  > - [PasswordAuthentication yes или UsePAM yes](https://www.linux.org.ru/forum/admin/14884566)
  > - [Непонятное в SSH](https://www.linux.org.ru/forum/admin/12826308)

> Порт на сервере необходимо открыть. Если в ОС установлен файерволл, необходимо разрешить подключение через выбранный порт, например, с использованием `UFW` в Убунте:
> ```bash
> sudo ufw allow 2222
> ```
> *UFW (Uncomplicated Firewall)* &ndash; удобный интерфейс для управления политиками безопасности межсетевого экрана.

Перезапускаем службу:

```bash
systemctl reload sshd.service
```

#### Настройка клиента

##### Linux

В домашней директории пользователя необходимо создать папку `.ssh` и поместить в нее пару ключей:

```bash
mkdir /home/alex/.ssh/
chmod 700 /home/ud/.ssh/
chown -R alex:alex /home/alex/.ssh/
```

При этом у приватного ключа права доступа должны иметь значение $600$ или `-rw-------`, у публичного ключа &ndash; $644$ или `-rw-r--r--`.

> Для просмотра прав доступа к файлу можно воспользоваться утилитой `ls` для отображения прав доступа в human readable формате или `stat` для вывода в восьмеричном виде (octal notation):
> ```bash
> ls -l ~/.ssh/id_rsa_gitlab.pub
> stat -c "%a %n" ~/.ssh/id_rsa_gitlab.pub
> ```

##### Windows

В домашней директории пользователя необходимо создать папку `.ssh` и поместить в нее пару ключей.

#### Проверка соединения

Например, имеются следующие данные для SSH соединения:
- Имя хоста: `relay-server.net`
- Имя учетной записи: `ruser`
- Порт для SSH: `7777`
- Имя приватного ключа: `id_ed25519_ruser`

Тогда команда для подключения будет выглядеть следующим образом:

```commandline
ssh -p 7777 ruser@relay-server -i C:\Users\UD\.ssh\id_ed25519_ruser
```

Если все прошло успешно, то в SSH клиенте мы увидим консоль (терминал) сервера:

<div align="center">
  <br>
  <img src="images/SSH_success.png" width="800" title="SSH OK"/>
    <p style="text-align: center">
        Рисунок 12 &ndash; Успешное соединение через SSH
    </p>
</div>

Если неуспех, то необходимо провести отладку.

> При первом подключении к неизвестному хосту клиент выведет сообщение с хешем публичного ключа:
> 
> <div align="center">
>  <br>
>  <img src="images/Host_key_fingerprint_Tabby.png" width="800" title="SSH fingerprint"/>
>    <p style="text-align: center">
>        Рисунок 13 &ndash; Первое подключение к неизвестному хосту
>    </p>
> </div>

#### Отладка на стороне клиента

Самой распространенной причиной возникновения ошибки при соединении с сервером через SSH являются разрешения (права доступа). Необходимо проверить владельца папки `.ssh`, установленные права для публичного и приватного ключей. Пример ошибки:

<div align="center">
  <br>
  <img src="images/Bad_permissions_1.png" width="800" title="SSH bad permissions 1"/>
    <p style="text-align: center">
        Рисунок 14 &ndash; Ошибка при подключении через SSH с использованием ключей
    </p>
</div>

В данном случае причина ошибки очевидна: `Bad permissions`, `Permissions for 'C:\\Users\\UD\\.ssh\\id_ed25519_pc340_ruser' are too open. It is required that your private key files are NOT accessible by others.`

Данный ключ был создан на сервере под Убунтой, в атрибутах в списке владельцев на стороне клиента (Windows) присутствует неизвестная учетная запись. Подсказано решение: убрать учетную запись `UNKNOWN\\UNKNOWN (S-1-5-21-298041677-3583488911-3265851412-1001)` из списка владельцев. Для этого в свойствах файла (приватный ключ в данном случае) на вкладке `Безопасность` нужно нажать на кнопку `Дополнительно`:

<div align="center">
  <br>
  <img src="images/Bad_permissions_2.png" width="767" title="SSH bad permissions 2"/>
    <p style="text-align: center">
        Рисунок 15 &ndash; Дополнительные параметры безопасности
    </p>
</div>

В открывшемся окне необходимо удалить неизвестную учетную запись. Если нажать удалить, то выведется сообщение об ошибке:

<div align="center">
  <br>
  <img src="images/Bad_permissions_3.png" width="406" title="SSH bad permissions 3"/>
    <p style="text-align: center">
        Рисунок 16 &ndash; Дополнительные параметры безопасности
    </p>
</div>

Сначала необходимо отключить наследование с преобразованием унаследованных разрешений в явные:

<div align="center">
  <br>
  <img src="images/Bad_permissions_4.png" width="542" title="SSH bad permissions 4"/>
    <p style="text-align: center">
        Рисунок 17 &ndash; Дополнительные параметры безопасности
    </p>
</div>

И затем удалить неизвестную учетную запись. После нажать `Применить` и/или `OK`. Повторно осуществить попытку подключения:

<div align="center">
  <br>
  <img src="images/Bad_permissions_5.png" width="800" title="SSH bad permissions 5"/>
    <p style="text-align: center">
        Рисунок 18 &ndash; Дополнительные параметры безопасности
    </p>
</div>

> Если ошибка неочевидная, можно вывести отладочную информацию при подключении с использованием флага `-v` (`verbose`; `-vv` &ndash; второй уровень, `-vvv` &ndash; третий и т.д.):
> ```bash
> ssh -v -p 7777 ruser@relay_server.net -i C:\Users\UD\.ssh\id_ed25519_pc340_ruser
> ```

Пример:

<div align="center">
  <br>
  <img src="images/SSH_debug_1.png" width="800" title="SSH debug 1"/>
    <p style="text-align: center">
        Рисунок 19 &ndash; Отладка SSH подключения на клиенте
    </p>
</div>

#### Отладка на стороне сервера

Для отладки SSH на стороне сервера необходимо включить вывод отладочной информации `sshd` в логи. Для этого в `sshd_config` необходимо раскомментировать или добавить следующие строки:

```nano
#SyslogFacility AUTH
#LogLevel INFO
```

При этом в `LogLevel` прописать значение `DEBUG3` (3 &ndash; уровень дебага). Сохранить конфиг и перезапустить службу.

Для просмотра системных сообщений в журнале необходимо воспользоваться утилитой `journalctl`:

```bash
journalctl -n 100 --no-pager -xu ssh
```

Данная команда выведет последние 100 записей, связанных с ssh.

Пример вывода:

```bash
сен 28 00:37:26 udupc sshd[2234841]: Failed password for invalid user admin from 92.255.85.253 port 44051 ssh2
сен 28 00:37:27 udupc sshd[2234841]: Connection reset by invalid user admin 92.255.85.253 port 44051 [preauth]
сен 28 00:45:18 udupc sshd[2239642]: error: kex_protocol_error: type 20 seq 2 [preauth]
сен 28 00:45:18 udupc sshd[2239642]: error: kex_protocol_error: type 30 seq 3 [preauth]
сен 28 00:45:19 udupc sshd[2239642]: error: kex_protocol_error: type 20 seq 4 [preauth]
сен 28 00:45:19 udupc sshd[2239642]: error: kex_protocol_error: type 30 seq 5 [preauth]
сен 28 00:45:21 udupc sshd[2239642]: error: kex_protocol_error: type 20 seq 6 [preauth]
сен 28 00:45:21 udupc sshd[2239642]: error: kex_protocol_error: type 30 seq 7 [preauth]
сен 28 00:45:49 udupc sshd[2239642]: Connection reset by 139.59.36.72 port 6116 [preauth]
сен 28 00:47:07 udupc sshd[2240739]: Invalid user reboot from 185.234.216.97 port 11356
сен 28 00:47:07 udupc sshd[2240739]: pam_unix(sshd:auth): check pass; user unknown
сен 28 00:47:07 udupc sshd[2240739]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=185.234.216.97
сен 28 00:47:09 udupc sshd[2240739]: Failed password for invalid user reboot from 185.234.216.97 port 11356 ssh2
сен 28 00:47:09 udupc sshd[2240739]: Received disconnect from 185.234.216.97 port 11356:11: Client disconnecting normally [preauth]
сен 28 00:47:09 udupc sshd[2240739]: Disconnected from invalid user reboot 185.234.216.97 port 11356 [preauth]
```

> В тестовом режиме данная машина через службу DDNS была доступна извне, по логу видно, что авторизоваться пытались с учетными записями `admin`, `reboot` и др.

Так выглядит пример журнала с включенным дебагом SSH соединения на сервере:

```bash
Sep 27 20:57:14 vm860617 sshd[917749]: debug3: fd 7 is O_NONBLOCK
Sep 27 20:57:14 vm860617 sshd[917749]: debug3: send packet: type 99
Sep 27 20:57:14 vm860617 sshd[917779]: debug1: Setting controlling tty using TIOCSCTTY.
Sep 27 20:57:14 vm860617 sshd[917779]: debug3: Normalising mapped IPv4 in IPv6 address
Sep 27 20:57:14 vm860617 sshd[917749]: debug3: receive packet: type 98
Sep 27 20:57:14 vm860617 sshd[917749]: debug1: server_input_channel_req: channel 1 request window-change reply 0
Sep 27 20:57:14 vm860617 sshd[917749]: debug1: session_by_channel: session 1 channel 1
Sep 27 20:57:14 vm860617 sshd[917749]: debug1: session_input_channel_req: session 1 req window-change
Sep 27 20:57:15 vm860617 sshd[917749]: debug3: receive packet: type 98
Sep 27 20:57:15 vm860617 sshd[917749]: debug1: server_input_channel_req: channel 1 request window-change reply 0
Sep 27 20:57:15 vm860617 sshd[917749]: debug1: session_by_channel: session 1 channel 1
Sep 27 20:57:15 vm860617 sshd[917749]: debug1: session_input_channel_req: session 1 req window-change
Sep 27 20:57:19 vm860617 sshd[917749]: debug3: receive packet: type 80
Sep 27 20:57:19 vm860617 sshd[917749]: debug1: server_input_global_request: rtype keepalive@openssh.com want_reply 1
Sep 27 20:57:19 vm860617 sshd[917749]: debug3: send packet: type 82
Sep 27 20:57:24 vm860617 sshd[917749]: debug3: receive packet: type 80
Sep 27 20:57:24 vm860617 sshd[917749]: debug1: server_input_global_request: rtype keepalive@openssh.com want_reply 1
Sep 27 20:57:24 vm860617 sshd[917749]: debug3: send packet: type 82
```

По сообщениям в журнале можно понять, на каком этапе возникает "неуспех" и отладить.

### 1.7 Настройка файервола UFW

Источник: [Настройка фаервола в Ubuntu с помощью утилиты UFW](https://selectel.ru/blog/tutorials/how-to-configure-firewall-with-ufw-on-ubuntu-20/)

Установка:

```bash
sudo apt install ufw
```

Проверка состояния UFW с помощью команды:

```bash
sudo ufw status verbose
```

По умолчанию UFW отключен, так что вы должны увидеть что-то вроде этого:
```bash
Status: inactive
```

Пример с включенным UFW:

```bash
ud@udupc:~$ sudo ufw status verbose
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), deny (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp (OpenSSH)           ALLOW IN    Anywhere                  
9000/tcp                   ALLOW IN    Anywhere                  
80/tcp (Nginx HTTP)        ALLOW IN    Anywhere                  
443                        ALLOW IN    Anywhere                  
22/tcp (OpenSSH (v6))      ALLOW IN    Anywhere (v6)             
9000/tcp (v6)              ALLOW IN    Anywhere (v6)             
80/tcp (Nginx HTTP (v6))   ALLOW IN    Anywhere (v6)             
443 (v6)                   ALLOW IN    Anywhere (v6
```

#### Начальная настройка

По умолчанию настройки UFW запрещают все входящие соединения и разрешают все исходящие. Это значит, что если кто-то попытается подключиться к серверу, он не сможет этого сделать, в то время как любое приложение на сервере имеет доступ к внешним соединениям.

Соответствующие правила фаервола прописываются так:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

##### SSH

Чтобы разрешить входящие SSH-соединения, необходимо выполнить команду:

```bash
sudo ufw allow ssh
```

SSH демон по умолчанию прослушивает $22$ порт. UFW знает об именах распространенных служб (ssh, sftp, http, https), поэтому можно использовать их вместо номера порта.

Если SSH-демон использует другой порт, то необходимо указать его в явном виде, например:

```bash
sudo ufw allow 2222
```

#### Запуск UFW

Чтобы включить UFW, необходимо выполнить следующую команду:

```bash
sudo ufw enable
```

Появится похожее предупреждение:

```bash
Command may disrupt existing ssh connections. Proceed with operation (y|n)?
```

Это означает, что запуск этого сервиса может разорвать текущее SSH соединение.

#### Добавление диапазонов портов

```bash
sudo ufw allow 3000:3100
```

Также можно указать конкретный протокол:

```bash
sudo ufw allow 3000:3100/tcp
sudo ufw allow 3000:3100/udp
```

#### Добавление IP-адресов

Можно указать IP-адрес, которому будет разрешен доступ ко всем портам сервера:

```bash
sudo ufw allow from 123.45.67.89
```

Или к конкретному порту:

```bash
sudo ufw allow from 123.45.67.89 to any port 22
```

Аналогичным образом можно добавить правила для диапазонов IP-адресов:

```bash
sudo ufw allow from 123.45.67.89/24
sudo ufw allow from 123.45.67.89/24 to any port 22
```

#### Ограничение подключений

Команды аналогичны разрешающим правилам:

```bash
sudo ufw deny http
sudo ufw deny from 123.45.67.89
```

#### Удаление правил

Существует два способа удаления правил:
- По номеру правила
- По фактическому правилу

Для вывода пронумерованных правил необходимо выполнить команду:

```bash
sudo ufw status numbered
```

Пример вывода:

```bash
$ sudo ufw status numbered
Status: active

     To                         Action      From
     --                         ------      ----
[ 1] OpenSSH                    ALLOW IN    Anywhere                  
[ 2] 9000/tcp                   ALLOW IN    Anywhere                  
[ 3] Nginx HTTP                 ALLOW IN    Anywhere                  
[ 4] 443                        ALLOW IN    Anywhere                  
[ 5] OpenSSH (v6)               ALLOW IN    Anywhere (v6)             
[ 6] 9000/tcp (v6)              ALLOW IN    Anywhere (v6)             
[ 7] Nginx HTTP (v6)            ALLOW IN    Anywhere (v6)             
[ 8] 443 (v6)                   ALLOW IN    Anywhere (v6
```

Пример удаления по номеру:

```bash
sudo ufw delete 2
```

Пример удаления по фактическому правилу:

```bash
sudo ufw delete allow 80
```

#### Отключение UFW

```bash
sudo ufw disable
```

#### Сброс правил

```bash
sudo ufw reset
```

#### Логи

В UFW есть опция сохранения логов &ndash; журнал событий. Для запуска необходимо выполнить команду:

```bash
sudo ufw logging on
```

UFW поддерживает несколько уровней логирования:
- `off` &ndash; отключен.
- `low` &ndash; регистрирует все заблокированные пакеты, не соответствующие заданной политике (с ограничением скорости), а также пакеты, соответствующие зарегистрированным правилам.
- `medium` &ndash; все то, что при значении `low`. Плюс все разрешенные пакеты, не соответствующие заданной политике, все недопустимые пакеты, и все новые соединения. Все записи ведутся с ограничением скорости.
- `high` &ndash; работает так же, как и `medium`. Плюс все пакеты с ограничением скорости.
- `full` &ndash; так же, как и `high`, но без ограничения скорости. 

Чтобы задать уровень, необходимо указать его как параметр:

```bash
sudo ufw logging high
```

По умолчанию используется уровень `low`.

Для просмотра списка файлов-логов UFW необходимо выполнить команду:

```bash
ls /var/log/ufw*
```

Пример вывода:

```bash
$ ls /var/log/ufw*
/var/log/ufw.log  /var/log/ufw.log.1  /var/log/ufw.log.2.gz  /var/log/ufw.log.3.gz  /var/log/ufw.log.4.gz
```

Просмотр содержимого лога:

```bash
cat /var/log/ufw.log
```

### 1.8 Туннелирование SSH

Источники:
- [Наглядное руководство по SSH-туннелям @ Хабр](https://habr.com/ru/companies/flant/articles/691388/)
- [How to Set up SSH Tunneling (Port Forwarding)](https://linuxize.com/post/how-to-setup-ssh-tunneling/)
- [Что такое ssh agent forwarding](https://dvmn.org/encyclopedia/deploy/ssh-agent-forwarding/)

Туннели SSH &ndash; это зашифрованные TCP-соединения между клиентами и серверами SSH. Трафик входит с одной стороны туннеля и прозрачно выходит с другой. Изначально этот термин относился к туннелям на виртуальных сетевых интерфейсах TUN/TAP, однако сейчас так обычно называют проброс портов SSH.

Сценарии использования туннелей:
- Предоставление зашифрованных каналов для протоколов, передающих данные "открытым текстом" (без шифрования).
- Открытие бэкдоров в частные сети.
- Обход межсетевых экранов (NAT).

#### Проброс портов

Перенаправляет порт из одной системы (локальной или удаленной) в другую.

#### Проброс локального порта

Проброс локальных портов позволяет перенаправить трафик с SSH-клиента на целевой хост через SSH-сервер. Другими словами, можно получить доступ к удаленным сервисам по зашифрованному соединению так, как будто они локальные.

<div align="center">
  <br>
  <img src="images/SSH_port_forward_local.svg" width="530" title="SSH port forward local"/>
    <p style="text-align: center">
        Рисунок 20 &ndash; Проброс локального порта
    </p>
</div>

Примеры использования:
- доступ к удаленному сервису (Redis, Memcached и т.д.) по внутреннему IP-адресу
- локальный доступ к ресурсам, размещенным в частной сети
- прозрачное проксирование запроса к удаленному сервису

```bash
ssh -L [LOCAL_IP:]LOCAL_PORT:DESTINATION:DESTINATION_PORT [USER@]SSH_SERVER
```

Параметры:
- `[LOCAL_IP:]LOCAL_PORT` &ndash; IP-адрес и номер порта локальной машины (клиента). Если `LOCAL_IP` не указан, то используется привязка к `localhost`.
- `DESTINATION:DESTINATION_PORT` &ndash; IP-адрес (или имя хоста) и порт удаленной машины (пункта назначения).
- `[USER@]SERVER_IP` &ndash; имя учетной записи и IP-адрес сервера.

> Если в конфиге SSH демона установлено значение порта, отличающееся от $22$, то в команду необходимо добавить флаг `-p <номер SSH порта>`:
> ```bash
> ssh -L [LOCAL_IP:]LOCAL_PORT:DESTINATION:DESTINATION_PORT [USER@]SSH_SERVER -p PORT_NUM
> ```

##### Конфиг SSH

В конфиге SSH демона `/etc/ssh/sshd_config` должна быть включена переадресация TCP (по умолчанию так и должно быть):

```nano
AllowTcpForwarding yes
```

> При переадресации портов на интерфейсы, отличные от `127.0.0.1`, в локальной системе необходимо включить GatewayPorts:
> ```nano
> GatewayPorts yes
> ```

#### Проброс удаленного порта

Проброс удаленного порта позволяет направить трафик с SSH-сервера в пункт назначения либо через SSH-клиент, либо через другой удаленный хост. Открывает пользователям в публичных сетях доступ к ресурсам в частных сетях.

<div align="center">
  <br>
  <img src="images/SSH_port_forward_remote.svg" width="530" title="SSH port forward remote"/>
    <p style="text-align: center">
        Рисунок 21 &ndash; Проброс удаленного порта
    </p>
</div>

Примеры использования:
- открытие доступа к локальному серверу разработки через публичную сеть
- предоставление доступа с ограничением по IP-адресу к удаленному ресурсу в частной сети

> В данном примере на сервере локально поднят сайт на 80 порту, например. Извне он недоступен. Однако, при пробросе внешнего порта 8080 в локальный 80 данный сайт станет доступен извне по адресу `<IP сервера>:8080`.

```bash
ssh -R [REMOTE:]REMOTE_PORT:DESTINATION:DESTINATION_PORT [USER@]SSH_SERVER
```

Параметры:
- `[REMOTE:]REMOTE_PORT` &ndash; IP-адрес и номер порта удаленной машины (сервера). Если `REMOTE` не указан, то используется привязка ко всем адресам.
- `DESTINATION:DESTINATION_PORT` &ndash; IP-адрес (или имя хоста) и порт пункта назначения.
- `[USER@]SERVER_IP` &ndash; имя учетной записи и IP-адрес сервера.

> Если в конфиге SSH демона установлено значение порта, отличающееся от $22$, то в команду необходимо добавить флаг `-p <номер SSH порта>`:
> ```bash
> ssh -R [REMOTE:]REMOTE_PORT:DESTINATION:DESTINATION_PORT [USER@]SSH_SERVER -p PORT_NUM
> ```

##### Конфиг SSH

По умолчанию переадресуемые порты недоступны для доступа из интернета. Для переадресации публичного интернет-трафика на локальный компьютер в `sshd_config` на удаленном сервере необходимо прописать такую строку:

```nano
GatewayPorts yes
```

В таком случае переадресуемый порт будет открыт для ***всех адресов***. Если же доступ к порту нужно открыть для определенных адресов, то в конфиге необходимо прописать:

```nano
GatewayPorts clientspecified
```

В таком случае, если в качестве `REMOTE` выступает `localhost`, то нужно указать "пустое место":

```bash
ssh -R :22223:localhost:22 me@server -p 2222
```

#### Динамический проброс портов

При динамической переадресации портов на SSH-клиенте поднимается SOCKS-прокси для перенаправления TCP-трафика через SSH-сервер на удаленный хост.

<div align="center">
  <br>
  <img src="images/SSH_port_forward_dynamic.svg" width="530" title="SSH port forward dynamic"/>
    <p style="text-align: center">
        Рисунок 22 &ndash; Динамический проброс портов
    </p>
</div>

```bash
ssh -D [LOCAL_IP:]LOCAL_PORT [USER@]SSH_SERVER
```

Параметры:
- `[LOCAL_IP:]LOCAL_PORT` &ndash; IP-адрес и номер порта локальной машины (клиента). Если `LOCAL_IP` не указан, то используется привязка к `localhost`.
- `[USER@]SERVER_IP` &ndash; имя учетной записи и IP-адрес сервера.

> Если в конфиге SSH демона установлено значение порта, отличающееся от $22$, то в команду необходимо добавить флаг `-p <номер SSH порта>`:
> ```bash
> ssh -D [LOCAL_IP:]LOCAL_PORT [USER@]SSH_SERVER -p PORT_NUM
> ```

##### Конфиг SSH

Для открытия доступа другим интерфейсам к SOCKS-прокси необходимо включить `GatewayPorts` в системе:

```bash
GatewayPorts yes
```

Поскольку `GatewayPorts` конфигурируется на SSH-клиенте, вместо `ssh_config` для настройки можно использовать параметры командной строки:

```bash
ssh -o GatewayPorts=yes -D 7777 ssh_server
```

#### Проброс системных (privileged) портов

Для пересылки трафика с системных портов ($1$–$1023$) необходимо запустить SSH с правами суперпользователя в системе, на которой открывается порт.

```bash
sudo ssh -L 80:example.com:80 ssh-server
```

#### Jump-хосты

Прозрачное подключение к удаленному хосту через промежуточные:

```bash
ssh -J user1@jump_host user2@remote_host
```

```bash
ssh -o "ProxyJump user1@jump_host" user2@remote_host
```

<div align="center">
  <br>
  <img src="images/SSH_port_forward_jump.svg" width="550" title="SSH jump hosts"/>
    <p style="text-align: center">
        Рисунок 23 &ndash; Jump-хосты
    </p>
</div>

Устанавливает SSH-соединение с jump-хостом и переадресуют трафик на удаленный хост.

Подключается к удаленному хосту через промежуточный jump-хост. Приведенная выше команда должна сработать сразу, если у jump-хоста уже есть SSH-доступ к удаленному хосту. Если нет, можно использовать `agent forwarding` для проброса SSH-ключа с локального компьютера на удаленный хост.

Для этого в конфиг необходимо добавить:

```nano
ForwardAgent yes
```

Как только произойдет отключение от сервера, ключи "пропадут" с сервера.

### 1.9 Обратное туннелирование SSH

Источники:
- [Как получить доступ к серверу Linux за NAT через обратный туннель SSH](https://rus-linux.net/MyLDP/sec/reverse-SSH-tunnel.html)
- [How to Set up SSH Tunneling (Port Forwarding)](https://linuxize.com/post/how-to-setup-ssh-tunneling/)
- [Directions for setting up a reverse ssh tunnel as a systemd service in Linux](https://github.com/axthosarouris/reverse-ssh-tunnel)

Допустим, Linux-сервер размещен в домашней или в рабочей сети, которая находится за NAT маршрутизатора или защищена брандмауэром. То есть извне доступа к этой машине нет, а доступ к машине нужен. Как это настроить? Возможным вариантом будет, безусловно, перенаправление на порт SSH. Однако, перенаправление портов может оказаться более сложным в случае, если среда с несколькими вложенными NAT. Кроме того, на выбранное решение могут оказывать влияние различные ограничения, устанавливаемые интернет-провайдерами, например, ограничительные брандмауэры провайдеров, которые блокируют перенаправление портов или NAT с трансляцией адресов, что позволяет пользователям одновременно пользоваться одними и теми же адресами IPv4.

> **NAT** (***Network Address Translation*** &ndash; "преобразование сетевых адресов") &ndash; это механизм в сетях TCP/IP, позволяющий преобразовывать IP-адреса транзитных пакетов.

Одной из альтернатив перенаправлению портов SSH является ***обратное туннелирование SSH***. Концепция реверсного туннелирования SSH сравнительно проста. Для этого понадобится еще один хост (так называемый "хост релея"), находящийся за пределами защищенной сети, к которому можно подключиться через SSH из защищенной сети и сети, в которой находится клиент. В качестве хоста релея может выступать отдельный экземпляр виртуального частного сервера VPS, использующего публичный IP-адрес. Далее нужно настроить постоянный SSH туннель от сервера в защищенной сети на хост общественного релея. Благодаря этому возможно подключаться "в обратном направлении" к серверу в защищенной сети с хоста релея (именно поэтому такой туннель называется "обратным"). До тех пор пока хост релея доступен, существует возможность подключения к искомому серверу из любого места, причем независимо от того, используется ли в сети ограничивающий NAT или брандмауэр.

<div align="center">
  <br>
  <img src="images/SSH_port_forward_reverse.svg" width="490" title="SSH reverse tunnel"/>
    <p style="text-align: center">
        Рисунок 24 &ndash; Обратное туннелирование SSH
    </p>
</div>

#### Настройка сервера

На сервере вместо утилиты `ssh` воспользуемся утилитой `autossh`. `autossh` отслеживает SSH соединение, и если оно разрывается, переподключает. Установка:

```bash
sudo apt install autossh
```

Для автоматического подключения сервера к серверу-релею необходимо создать службу в `/etc/systemd/system`. Назовем её `rtunnel.service`. Содержимое `/etc/systemd/system/rtunnel.service`:

```nano
[Unit]
Description = Reverse ssh tunnel
After =  network-online.target
#Requires

[Service]
User = root
#Type = forking
Environment=AUTOSSH_GATETIME=0
ExecStart = /usr/bin/autossh -M 0 -q -N -o "PubKeyAuthentication=yes" -o "StrictHostKeyChecking=false" -o "PasswordAuthentication=no" -o "ExitOnForwardFailure=yes" -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3"  -i /home/ruser/.ssh/id_ed25519_ruser -R relay-server.net:10222:localhost:4444 ruser@relay-server.net -p 7777
ExecStop= /usr/bin/killall autossh
RestartSec=5
Restart=always

[Install]
WantedBy = multi-user.target
```

Параметры `autossh`:
- `-M 0`: номер порта на сервере-релее, для которого будет осуществляться мониторинг. Данный порт будет использоваться для обмена тестовыми данными при контроле сессии SSH. Этот порт на сервере-релее не должен использоваться какой-либо другой программой.
- `-q`: режим `quiet mode`, отключает вывод диагностических сообщений и предупреждений.
- `-N`: отключает выполнение удаленной команды. Используется для проброса портов.
- `-o`: указывает параметр, для которого не предусмотрен флаг в `ssh` утилите. Используется синтаксис как в конфигурационном файле демона `sshd`.

Параметры сервера-релея:
- Адрес: `relay-server.net`
- SSH порт: `7777`
- Имя учетной записи: `ruser`

Параметры сервера:
- Имя учетной записи: `ruser`
- SSH порт: `4444`
- Пробрасываемый удаленный SSH порт: `10222`
- SSH ключ для соединения с сервером-релеем: `id_ed25519_ruser`

В качестве сервера-релея выступает сервер по адресу `relay-server.net`, на который мы стучимся под учетной записью `ruser` через порт `7777` с использованием ключа `/home/ruser/.ssh/id_ed25519_ruser`. Мы пробрасываем удаленный порт `10222` с `relay-server.net` в `localhost` на порт `4444` (`localhost` в данном случае &ndash; искомый сервер, находящийся за NAT и не имеющий публичный IP, к которому внутри защищенной сети можно подключиться через SSH на порт `4444`). Поэтому когда мы (клиент) будем подключаться к серверу-релею через порт `10222`, сервер-релей перенаправит (обратно) SSH соединение на искомый сервер на порт `4444`. В данном случае для простоты публичный ключ `id_ed25519_ruser` находится на сервере и сервере-релее, так же он прописан в `authorized_keys` на обоих серверах.

Если на серверах установлен UFW, то необходимо открыть соответствующие порты.

После создания службы необходимо перезапустить системный демон:

```bash
sudo systemctl daemon-reload
```

Запустить службу `rtunnel`:

```bash
sudo systemctl start rtunnel
```

Проверить подключение:

```bash
ssh -p 10222 ruser@relay-server.net -i C:\Users\<имя юзера>\.ssh\id_ed25519_ruser
```

Если соединение установлено, то можно включить автозапуск службы при загрузке ОС:

```bash
sudo systemctl enable rtunnel
```

> В службу `rtunnel` можно прописать несколько пробросов удаленных портов: для каждого подключения с разных учетных записей на сервере (искомый, за NAT) необходимо пробросить отдельный удаленный порт. Другими словами, нельзя подключиться через один и тот же удаленный порт с разных учетных записей сервера за NAT.
> <div align="center">
>  <br>
>  <img src="images/SSH_port_forward_reverse_multiple.svg" width="780" title="SSH reverse tunnel multiple"/>
>    <p style="text-align: center">
>        Рисунок 25 &ndash; Обратное туннелирование SSH, несколько туннелей
>    </p>
> </div>
>
> Публичные ключи `user1` и `user2` должны быть прописаны в `authorized_keys` на сервере `secret-server`, публичный ключ `ruser` должен быть прописан в `authorized_keys` на сервере `relay-server`.

### 1.10 Файл конфигурации config

Для организации множества подключений к различным хостам можно использовать конфигурационный файл `config`, который необходимо создать в папке `.ssh`. Файл конфигурации SSH клиента представляет собой текстовый файл, в котором перечисляются настройки для различных хостов.

Пример содержимого:

```nano
Host *
  ForwardAgent yes
  ForwardX11 yes
  ForwardX11Trusted yes
Host gitlab.com
  IdentityFile ~/.ssh/id_rsa_gitlab
  User git
  Port 22
Host github.com
  IdentityFile ~/.ssh/id_rsa_github
  User git
  Port 22
Host Nano
  HostName jnano
  Port 2222
  User ud
  IdentityFile ~/.ssh/id_rsa_jnano
Host udrpi3, 10.0.0.29
  HostName udrpi3
  User pi
  IdentityFile ~/.ssh/id_rsa_udrpi3
```

Первый блок устанавливает параметры для всех подключений:
- `ForwardAgent`: уже знакомый параметр проброса ключа через промежуточные хосты.
- `ForwardX11`: проброс "иксов" &ndash; графического окружения для вывода графических приложений. Аналогично использованию ключа `-X`: `ssh -X your_user@your_server`.
- `ForwardX11Trusted`: понижает уровень безопасности или, другими словами, повышает уровень доверия к клиенту &ndash; "trusted client". В "untrusted" варианте, если проброшенное приложение нарушает настройки безопасности (например, осуществляет захват экрана &ndash; скриншоты, логирование нажатий клавиш клавиатуры и т.п.), то выскочит ошибка. В доверенном варианте такие действия не отлавливаются. Аналогично использованию ключа `-Y`: `ssh -Y your_user@your_server`.

> X11 forwarding &ndash; это механизм, позволяющий отображать на локальном клиентском компьютере графические интерфейсы X11 программ, запущенных на удаленном Unix/Linux сервере. SSH имеет возможность безопасного туннелирования X11 соединений, так что сеансы X11 forwarding-а шифруются и инкапсулируются.  
> 
> Обычно не рекомендуется всегда работать с «ForwardX11 yes». Поэтому, если вы хотите использовать свои SSH-соединения с повышенной безопасностью, лучше всего сделать следующее:
> - Не прописывать «ForwardX11 yes» в `~/.ssh/config` файл.
> - Использовать "ForwardingX11" только когда это необходимо, в явном виде `ssh -X your_user@your_server`.
> Подробнее здесь: [What is the difference between `ssh -Y` (trusted X11 forwarding) and `ssh -X` (untrusted X11 forwarding)?](https://askubuntu.com/questions/35512/what-is-the-difference-between-ssh-y-trusted-x11-forwarding-and-ssh-x-u)/

```nano
Host gitlab.com
  IdentityFile ~/.ssh/id_rsa_gitlab
  User git
  Port 22
```

Параметры:
- `Host`: указывает, что далее идут настройки для определённого хоста или нескольких хостов (псевдоним или метка).
- `HostName`: реальное имя хоста (имя домена или IP-адрес).
- `IdentityFile`: путь к приватному ключу.
- `User`: имя учетной записи на удаленном хосте для подключения.
- `Port`: номер SSH порта.

Для примера выше можно проверить SSH подключение:

```bash
ssh -T gitlab.com
```

### 1.11 Разное

#### Форматы ключей

При попытке подключения в PuTTY или WinSCP с использованием ключей, сгенерированных через OpenSSH, выскочит следующее сообщение:

<div align="center">
  <br>
  <img src="images/OpenSSH_PuTTY_ppk.png" width="482" title="SSH key convertion"/>
    <p style="text-align: center">
        Рисунок 26 &ndash; Конвертация ключа из формата OpenSSH в PPK
    </p>
</div>

#### Конфиг демона `sshd`

В конфиге помимо глобальных настроек можно указать настройки для отдельных учетных записей, переопределяющие глобальные. Для этого в синтаксисе конфига используется конструкция `Match`:

```nano
...
AuthorizedKeysFile /home/ud/.ssh/authorized_keys
...
Match User ruser
  AuthorizedKeysFile /home/ruser/.ssh/authorized_keys
```

`Match` означает условный блок, который переопределяет параметры при выполнении условия. Критерии, которые можно использовать в блоке `Match`: `User`, `Group`, `Host`, `LocalAddress`, `LocalPort`, `RDomain`, `Address`.

Подробнее можно посмотреть в руководстве `man sshd_config` ([sshd_config(5) — Linux manual page](https://man7.org/linux/man-pages/man5/sshd_config.5.html)) и `man ssh_config` ([ssh_config(5) — Linux manual page](https://www.man7.org/linux/man-pages/man5/ssh_config.5.html)).

#### Вывод активных сетевых соединений и открытых портов

`iproute2` &ndash; набор утилит для управления параметрами сетевых устройств в ядре Linux.

Набор утилит включает в себя три основные программы:
- `ip` &ndash; утилита для просмотра параметров и конфигурирования сетевых интерфейсов, сетевых адресов, таблиц маршрутизации, правил маршрутизации, arp‐таблиц, IP‐туннелей, адресов multicast рассылки, маршрутизацией multicast пакетов.
- `tc` &ndash; утилита для просмотра и конфигурирования параметров управления трафиком (tc &ndash; аббревиатура от *traffic control*). Позволяет управлять классификацией трафика, дисциплинами управления очередями для различных классов трафика либо целиком для сетевого интерфейса (корневые дисциплины), что, в свою очередь, позволяет реализовать QoS в нужном для системы объёме:
  + разделение разных типов трафика по классам (не только по битам ToS в IP‐пакете, но и по другим данным из заголовка IP‐пакета)
  + назначение разных дисциплин обработки очередей трафика с разным приоритетом, механизмами прохождения очереди, ограничениями по скорости и т.п.
- `ss` &ndash; утилита для просмотра текущих соединений и открытых портов. Аналог традиционной утилиты `netstat`.

Например, выполнение `ss` со следующими ключами:

```bash
ss -antp
```

- `-a` &ndash; вывести все сокеты
- `-n` &ndash; "не разрешать имена служб" или "не выполнять разрешение имен служб", программа не должна использовать DNS-серверы или другие механизмы для преобразования названий служб (например, в сети) в IP-адреса или другие машиночитаемые идентификаторы
- `-t` &ndash; вывести только TCP сокеты
- `-p` &ndash; вывести имена процессов, использующих сокеты