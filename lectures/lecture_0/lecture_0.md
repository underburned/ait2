# Технологии искусственного интеллекта. Семестр 2

© Петров М.В., старший преподаватель кафедры суперкомпьютеров и общей информатики, Самарский университет

## Лекция 0. SSH

### Содержание

1. [Введение](#01-введение)
2. [SSH-сервер](#02-ssh-сервер)
3. [SSH-клиенты](#03-ssh-клиенты)
4. [Файлы настроек SSH](#04-файлы-настроек-ssh)
5. [Генерация ключей](#05-генерация-ключей)
6. 

### 0.1 Введение

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

3 режима аутентификации:
- Аутентификация по паролю.  
  Наиболее распространенный вариант. Вводить пароль необходтио при каждом подключении. Пароль передается в зашифрованном виде.  
- Аутентификация по ключевой паре.  
  Предварительно генерируется публичный (открытый) и приватный (закрытый) ключи (`pulic key` и `private key`) для определённого пользователя. На машине, с которой требуется произвести подключение, хранится приватный и публичный ключи, а на удалённой машине &ndash; публичный. Эти файлы не передаются при аутентификации, система лишь проверяет, что владелец публичного ключа также владеет и приватным. При данном подходе, как правило, настраивается автоматический вход от имени конкретного пользователя в ОС.
- Аутентификация по IP-адресу.  
  Аутентификация по IP-адресу небезопасна из-за риска подмены адреса, эту возможность чаще всего отключают.  

<div align="center">
  <img src="images/SSH_schema.svg" width="800" title="SSH"/>
  <p style="text-align: center">
    Рисунок 1 &ndash; SSH соединения
  </p>
</div>

SSH обеспечивает безопасность соединения с удалённой машиной с использованием современных алгоритмов шифрования. Вся пересылаемая информация между узлами находится внутри зашифрованного туннеля.

### 0.2 SSH-сервер

В Linux системах обычно используется ***OpenSSH***, где сервер обозначается ***sshd***, что означает *SSH демон* (*SSH Daemon*). Клиент SSH &ndash; ***ssh***. Все необходимые настройки для клиента и сервера в Linux системах обычно хранятся в директории `/etc/ssh/`. По префиксу имени файла можно догадаться, к клиенту или серверу имеет отношение файл настройки. Все настройки имеют глобальный характер, т.е. актуальны для всех пользователей устройства.

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

В случае отсутствия установленного OpenSSH в ОС необходимо добавить SSH-сервер в автозагрузку. При следующем запуске сервера операционная система выполнит автоматический запуск SSH-сервера. Как и в случае с другими сервисами, `systemd` позволяет управлять параметрами запуска, автозагрузки и рестарта демона OpenSSH. Включим автозапуск:

```bash
sudo systemctl enable sshd
```

Проверка работы SSH:

```bash
systemctl status sshd
```

Пример вывода:

```bash
ruser@palitpc:~$ systemctl status sshd
● ssh.service - OpenBSD Secure Shell server
     Loaded: loaded (/lib/systemd/system/ssh.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2024-07-04 15:32:42 +04; 2 months 13 days ago
       Docs: man:sshd(8)
             man:sshd_config(5)
   Main PID: 1237 (sshd)
      Tasks: 1 (limit: 76769)
     Memory: 8.1M
        CPU: 470ms
     CGroup: /system.slice/ssh.service
             └─1237 "sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups"

Warning: some journal files were not opened due to insufficient permissions.
```

#### Установка в Windows

Пакет OpenSSH Server включен в современные версии Windows 10 (начиная с 1803), Windows 11 и Windows Server в виде Feature on Demand (FoD).

 - Способ 1. `PowerShell`  
   Для установки сервера OpenSSH достаточно выполнить в `PowerShell` команду (`PowerShell` необходимо запустить с правами администратора):
   ```powershell
   Get-WindowsCapability -Online | Where-Object Name -like ‘OpenSSH.Server*’ | Add-WindowsCapability –Online
   ```
 - Способ 2. Командная строка (терминал)  
   В командной строке или терминале выполнить следующую команду (тоже с правами администратора):
   ```batch
   dism /Online /Add-Capability /CapabilityName:OpenSSH.Server~~~~0.0.1.0
   ```
 - Способ 3. Параметры  
   Также возможно установить сервер OpenSSH в Windows через современную панель Параметры (Settings -> Apps and features -> Optional features -> Add a feature, Приложения -> Управление дополнительными компонентами -> Добавить компонент. Найдите в списке OpenSSH Server и нажмите кнопку Install).
   > В инкрементальных мажорных обновлениях Windows 11 легко запутаться, некоторые настройки запрятаны в интуитивно непонятных (user unfriendly) разделах, так что проще использовать команды.

### 0.3 SSH-клиенты

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
  Бесплатный клиент для протоколов SSH/SFTP/Shell/Telnet/Serial. WindTerm полностью бесплатнен как для коммерческого, так и некоммерческого использования. Весь опубликованный на текущий момент исходный код предоставляются на условиях лицензии Apache-2.0. Исключение составляет код сторонних разработчиков. WindTerm является проектом с частично открытым исходным кодом, и исходный код будет постепенно открываться.  
    
  <div align="center">
    <br>
    <img src="images/WindTerm.png" width="1228" title="WindTerm"/>
      <p style="text-align: center">
          Рисунок 9 &ndash; WindTerm
      </p>
  </div>

### 0.4 Файлы настроек SSH

- Файл `config` &ndash; файл настройки клиента. Позволяет настраивать параметры соединений, чтобы не было необходимости каждый раз указывать опции для каждого конкретного сервера. Список возможных параметров можно посмотреть здесь: [SSH config file for OpenSSH client](https://www.ssh.com/academy/ssh/config).
- Файл `authorized_keys` содержит список публичных ключей для доступа к серверу sshd на этой машине (SSH-сервер).
- Файл `known_hosts` содержит список ключей для хостов, к которым ранее уже было произведено подключение. Это один из инструментов безопасности. При первом подключении к серверу клиент получает подпись его ключа доступа, которую в дальнейшем будет использоваться для проверки легитимности хоста. При повторном подключении эти данные позволяют проверить, что это именно тот сервер, к которому клиент подключался ранее.
- Файлы `id_*` содержат приватные ключи доступа для текущего устройства. Вместо * в имени файла как правило присутствует имя используемого алгоритма шифрования. Ключей может быть несколько, для каждого запрошенного алгоритма шифрования. Эти файлы должны храниться в полной секретности. Никому их передавать нельзя. На ключи доступа можно установить пароль, без которого невозможно будет воспользоваться этим ключом. В таком случае даже в случае утечки ключа воспользоваться им будет невозможно без знания пароля.
- Файлы `id_*.pub` содержат публичные ключи доступа, которые используются для подключения к другим устройствам. Вместо * в имени файла присутствует имя используемого алгоритма шифрования, которые предоставляет удалённое устройство при подключении. Ключей может быть несколько, для каждого доступного алгоритма шифрования.

Вообще, имена публичных ключей шифрования могут быть любыми. В этом случае при подключении нужно прямо указать путь к ключу при подключении к удалённой машине. Сделать это можно через параметры командной строки или через файл конфигурации `config`.

### 0.5 Генерация ключей

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
> В случае использования RSA ключей рекомендуется устанавливать длину ключа при его генерации равной $2048$ бит. Ключи длиной $<1024$ бит [потенциально небезопасны](https://crypto.stackexchange.com/a/1982) в смысле взломостойкости. С увеличением длины ключа взломостойкость растет, как и накладные расходы для шифрования и дешифрования.

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
=== $F ==="
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
> openssl speed rsa1024 rsa2048 rsa4096 ecdsap256 ed25519
> ```
> Пример вывода:
> ```bash
>                               sign    verify    sign/s  verify/s
> rsa 1024 bits              0.000109s 0.000007s   9213.7 141987.6
> rsa 2048 bits              0.000526s 0.000023s   1902.3  42704.8
> rsa 4096 bits              0.005714s 0.000087s    175.0  11517.2
> 256 bits ecdsa (nistp256)  0.0000s   0.0001s    39504.5  12626.9
> 253 bits EdDSA (Ed25519)   0.0000s   0.0001s    23596.9   9114.5
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

Пример вывода (ключ `-l` выводит цифровой отпечаток - хэш ключа):

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

### 0.6 Настройка сервера и клиента

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

Если данные манпуляции выполняются из-под другой учетной записи (не `alex`), то нужно изменить владельца всей папки `.ssh`:

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

Сохраняем изменения (Ctrl-O) и выходим (Ctrl-X):

<div align="center">
  <br>
  <img src="images/nano_sshd.png" width="800" title="nano"/>
    <p style="text-align: center">
        Рисунок 10 &ndash; Редактор nano
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
- `PasswordAuthentication no`  
  Запрет режима доступа по паролю.
- `KbdInteractiveAuthentication no`  
  Запрет интерактивного ввода с использованием клавиатуры.
- `UsePAM no`
  > C PAM разобраться сложнее, ежели интересно, можно начать отсюда:
  > - [PasswordAuthentication yes или UsePAM yes](https://www.linux.org.ru/forum/admin/14884566)
  > - [Непонятное в SSH](https://www.linux.org.ru/forum/admin/12826308)

Перезапускаем службу:

```bash
systemctl reload sshd.service
```

#### Настройка клиента