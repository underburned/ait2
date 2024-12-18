# Лабораторная работа №1: Docker. Сборка OpenCV

Лекции:
- [SSH](../../lectures/lecture_0/lecture_0.md)
- [Контейнеризация. Docker](../../lectures/lecture_1/lecture_1.md)

## Задание 0

С использованием пары ключей осуществить подключение к серверу, используя данные в `readme.txt`.

### Опционально

Настроить IDE для удобной работы на удаленной машине:
- [VS Code](vscode_remote.md)
- [PyCharm Pro](pycharm_remote.md)

## Задание 1

На базе образа [Ubuntu 22.04](https://hub.docker.com/_/ubuntu) создать Docker контейнер со сборкой [OpenCV](https://opencv.org/) с non free contrib модулями (пример из лекции).  
Рабочее сочетание версий (можно выбрать посвежее):
- Версия Убунты: 22.04
- OpenCV: 4.8.0
- CUDA: 12.2

Данные для сборки:
- скрипт сборки [build.sh](data/build.sh)
- скрипт [build_env.sh](data/build_env.sh) для задания определенных переменных среды (`environment vars`)
- докер файл [OpenCVDockerFile](data/OpenCVDockerFile.dockerfile)

1. Отредактировать скрипт сборки [build.sh](data/build.sh), заменить значения:
   - `image_tag` &ndash; название тега  
     > Дабы избежать пересечения в тегах, имеет смысл добавить уникальный префикс, пусть будет имя учетной записи: `stud<N>_<что угодно>`, где `<N>` &ndash; номер учетной записи на сервере.
   - `build_thread_count` &ndash; количество потоков для сборки библиотеки  
     > лучше указать $n - 1$, где $n$ &ndash; количество *физических* ядер CPU.
   - Версии Ubuntu, OpenCV, CUDA при желании  
   
   > Скрипт [build_env.sh](data/build_env.sh) использовать как есть, он необходим для установки питонячих путей для компиляции `OpenCV` и последующей установки библиотеки.  

2. C CUDA возможны различные приколы при установке, особенно на старые релизы типа `18.04`. Если в системе нет GPU Nvidia, то установку CUDA можно вырезать из скрипта сборки и докер файла.
   > На сервере GPU есть. Компиляция с использованием CUDA опциональна.  

3. Изменить права доступа, выдать разрешение для запуска скриптов `build.sh`, `build_env.sh`:  
   ```bash
   chmod +x build.sh
   chmod +x build_env.sh
   ```  

4. Дописать в конец [докер файла](data/OpenCVDockerFile.dockerfile) (перед `CMD`) команды для установки необходимых либ Python 3 при необходимости.  
   > Кроме `opencv-python` и `opencv-contrib-python`!  

5. Запустить `build.sh` для сборки контейнера.  

6. Реализовать [алгоритм обработки изображений](sub_task_opencv.md), скрипт на питоне положить в папку на хосте.  

7. Запустить контейнер командой:
   ```bash
   docker run -v <путь на хосте>:<путь внутри контейнера> -it <имя тега>
   ```

8. Запустить скрипт с реализованным алгоритмом в контейнере в примонтированной внутри контейнера папке.  
   Результат обработки сохранить в локальной директории контейнера.  

9. Убедиться в появлении результата в директории хоста (на сервере).

## Примечание

Самостоятельная сборка `OpenCV` из исходников необходима для использования проприетарных "небесплатных" алгоритмов, лицензия которых не совместима с `Apache-2.0 license` основных модулей. Код дополнительных экспериментальных модулей расположен в отдельном репе [Repository for OpenCV's extra modules](https://github.com/opencv/opencv_contrib), в который включены и non-free модули. Например, патент на алгоритм [SIFT](https://docs.opencv.org/4.x/da/df5/tutorial_py_sift_intro.html) истек в 2020 году, и теперь данный алгоритм переехал в основные модули. А патент на [SURF](https://en.wikipedia.org/wiki/Speeded_up_robust_features) действителен, и для коммерческого использования его необходимо [лицензировать](https://github.com/herbertbay/SURF#License-1-ov-file).