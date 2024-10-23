# Настройка remote development в PyCharm Pro

> Поддержка Remote development есть только в платной версии PyCharm: [PyCharm Professional vs. Community Edition](https://www.jetbrains.com/pycharm/editions/).

Для запуска локального кода на удаленной машине (сервере) необходимо сначала добавить интерпретатор Python через SSH туннель. Для этого можно кликнуть по текущему интерпретатору проекта в основном окне IDE с открытым текущим проектом:  

<div align="center">
  <img src="data/images/pycharm_remote_1.png" width="1280" title="PyCharm Pro: add SSH interpreter"/>
  <p style="text-align: center">
    Рисунок 1 &ndash; Добавление интерпретатора Python через SSH туннель
  </p>
</div>

В меню выбрать существующий интерпретатора Python через SSH туннель или новый `Add New Interpreter`:  

<div align="center">
  <img src="data/images/pycharm_remote_2.png" width="652" title="PyCharm Pro: add SSH interpreter"/>
  <br>
  <img src="data/images/pycharm_remote_3.png" width="203" title="PyCharm Pro: add SSH interpreter"/>
  <br>
  <p style="text-align: center">
    Рисунок 2 &ndash; Добавление интерпретатора Python через SSH туннель
  </p>
</div>

Далее необходимо ввести имя хоста (сервера), номер SSH порта и имя учетной записи для подключения к серверу:  

<div align="center">
  <img src="data/images/pycharm_remote_4.png" width="448" title="PyCharm Pro: add SSH interpreter"/>
  <p style="text-align: center">
    Рисунок 3 &ndash; Добавление интерпретатора Python через SSH туннель: данные для подключения
  </p>
</div>

Далее в следующем окне wizard'а вместо пароля `Password` необходимо выбрать ключевую пару `Key pair` и указать путь к приватному ключу. Поле `Passphrase` оставить пустым:  

<div align="center">
  <img src="data/images/pycharm_remote_5.png" width="448" title="PyCharm Pro: add SSH interpreter"/>
  <p style="text-align: center">
    Рисунок 4 &ndash; Добавление интерпретатора Python через SSH туннель: данные для подключения
  </p>
</div>

После успешного подключения нужно выбрать, какой интерпретатор использовать: системный или виртуальное окружение. Выбираем виртуальное окружение:  

<div align="center">
  <img src="data/images/pycharm_remote_6.png" width="1108" title="PyCharm Pro: add SSH interpreter"/>
  <p style="text-align: center">
    Рисунок 5 &ndash; Добавление интерпретатора Python через SSH туннель: данные для подключения
  </p>
</div>

В поле `Location` указывается папка с виртуальным окружением. По умолчанию имя конечной папки &ndash; название текущего открытого проекта. В данной папке будет храниться виртуальное окружение, изолированное от системного интерпретатора. В поле `Sync folders` жмем на кнопку выбора путей:  

<div align="center">
  <img src="data/images/pycharm_remote_7.png" width="718" title="PyCharm Pro: sync folders"/>
  <p style="text-align: center">
    Рисунок 6 &ndash; Добавление интерпретатора Python через SSH туннель: выбор путей для синхронизации проекта между локальной и удаленной машиной
  </p>
</div>

`Local Path` &ndash; путь к папке с текущим проектом на локальной машине. `Remote Path` &ndash; путь к папке с текущим проектом на удаленной машине. В поле `Remote Path` жмем на кнопку выбора, откроется окно выбора директории:  

<div align="center">
  <img src="data/images/pycharm_remote_8.png" width="586" title="PyCharm Pro: sync folders"/>
  <p style="text-align: center">
    Рисунок 7 &ndash; Добавление интерпретатора Python через SSH туннель: выбор путей для синхронизации проекта между локальной и удаленной машиной
  </p>
</div>

В данном примере выбрана папка в домашнем каталоге учетной записи пользователя. Жмем `OK`. `PyCharm` начнет установку параметров виртуального окружения, индексировать либы и т.п.

Теперь можно залить весь проект на сервер:  

<div align="center">
  <img src="data/images/pycharm_remote_9.png" width="1280" title="PyCharm Pro: project deployment"/>
  <p style="text-align: center">
    Рисунок 8 &ndash; Deploy проекта на сервер
  </p>
</div>

Также можно залить на удаленную машину любой файл проекта:  

<div align="center">
  <img src="data/images/pycharm_remote_10.png" width="1280" title="PyCharm Pro: file upload"/>
  <p style="text-align: center">
    Рисунок 9 &ndash; Upload файла на сервер
  </p>
</div>

Или скачать с удаленной машины на локальный ПК:  

<div align="center">
  <img src="data/images/pycharm_remote_11.png" width="1280" title="PyCharm Pro: file download"/>
  <p style="text-align: center">
    Рисунок 10 &ndash; Download файла на сервер
  </p>
</div>

По клику на таб `Terminal` открывается панель с консолью, в данном случае локальной машины:  

<div align="center">
  <img src="data/images/pycharm_remote_12.png" width="1280" title="PyCharm Pro: local terminal"/>
  <p style="text-align: center">
    Рисунок 11 &ndash; Вкладка <b>Terminal</b>: консоль локальной машины
  </p>
</div>

Однако, можно открыть терминал и на удаленной машине. Для этого в меню `Tools` &rarr; `Start SSH Session...` необходимо выбрать новую сессию вида `user@server:port`:  

<div align="center">
  <img src="data/images/pycharm_remote_13.png" width="1280" title="PyCharm Pro: start SSH session"/>
  <br>
  <img src="data/images/pycharm_remote_14.png" width="622" title="PyCharm Pro: start SSH session"/>
  <br>
  <p style="text-align: center">
    Рисунок 12 &ndash; Запуск новой сессии SSH
  </p>
</div>

Откроется терминал удаленной машины:

<div align="center">
  <img src="data/images/pycharm_remote_15.png" width="1280" title="PyCharm Pro: remote terminal"/>
  <p style="text-align: center">
    Рисунок 13 &ndash; Вкладка <b>Terminal</b>: консоль удаленной машины
  </p>
</div>

Profit! :sunglasses: