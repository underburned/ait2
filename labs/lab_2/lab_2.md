# Лабораторная работа №2. Docker. Сборка OpenMVG + OpenMVS

Лекции:
- [SSH](../../lectures/lecture_1/lecture_1.md)
- [Контейнеризация. Docker](../../lectures/lecture_2/lecture_2.md)
- [Мультиконтейнерные приложения. Docker Compose](../../lectures/lecture_3/lecture_3.md)

## Постановка задачи

Цель лабораторной работы &ndash; сборка образа для запуска ПО построения трехмерной сцены по набору изображений. В образ должно быть предустановлено (скомпилировано) следующее ПО:
- [OpenMVG](https://github.com/openMVG/openMVG) (*open Multiple View Geometry*) &ndash; библиотека для построения 3D структуры по набору изображений &ndash; *Structure from Motion* (на выходе облако точек).
- [OpenMVS](https://github.com/cdcseacave/openMVS) (*open Multi-View Stereo*) &ndash; библиотека для реконструкции трехмерной сцены из облака точек.
- NVIDIA CUDA
- Стартовый скрипт для выполнения задачи: `набор разноракурсных изображений` &rarr; `3D модель с текстурами`.

### Требования

1. Входные данные должны лежать вне собранного образа.
2. В контейнер должны монтироваться 2 директории: входные данные и выходные данные.
3. Скрипт запуска всего пайплайна реконструкции 3D сцены должен быть скопирован внутрь образа.
4. Образ должен иметь точку входа (`CMD` или `ENTRYPOINT`), который вызывает скрипт из п. 3.
5. CUDA можно поставить руками или найти образ с предустановленным SDK.
   > Можно в качестве основы взять образ из 1 лабораторной, например.
6. "Plain" Docker или Docker Compose по желанию.

### Рекомендации

Для удобства лучше реализовать многоступенчатую сборку образа, поэтапно:
- CUDA/OpenCV из 1 лабораторной (см. примечание [Установка CUDA и компиляция OpenCV](#установка-cuda-и-компиляция-opencv))
- сборка OpenMVG
- сборка OpenMVS
- финальный образ с бинарниками (***опционально***)
   > Вычистить исходники, папки build и прочие файлы для снижения размера образа.

Рабочее сочетание версий (можно выбрать посвежее):
- Версия Убунты: 22.04
- OpenCV: 4.8.0
- CUDA: 12.2

## Задание 1. Сборка OpenMVG

В репе [OpenMVG](https://github.com/openMVG/openMVG) есть [инструкция](https://github.com/openMVG/openMVG/blob/master/BUILD.md) по компиляции библиотеки, в том числе имеется докер-файл. 

На базе образа [Ubuntu 22.04](https://hub.docker.com/_/ubuntu) или Ubuntu 24 создать Docker образ со сборкой `CUDA + OpenCV + OpenMVG`.
> Кастомный OpenCV &ndash; опционально, но рабочая CUDA нужна. Можно в качестве основы взять образ из 1 лабораторной, либо найти образ с предустановленной CUDA (OpenCV можно оставить системным, то есть поставить через `apt`).

В случае установки CUDA и компиляции OpenCV см. примечание [Установка CUDA и компиляция OpenCV](#установка-cuda-и-компиляция-opencv).

> [Протестированный вариант сборки OpenMVG](#openmvg)

## Задание 2. Сборка OpenMVS

Использовать [инструкцию](https://github.com/openMVG/openMVG/blob/master/BUILD.md) по компиляции библиотеки или

> [Протестированный вариант сборки OpenMVS](#openmvs)

## Задание 3. Скрипт запуска пайплайна OpenMVG + OpenMVS

Адаптировать [Python3 скрипт запуска пайплайна](data/3dr.py). В скрипте глобально прописаны переменные:
- `OPENMVG_BIN` &ndash; путь до папки с бинарниками OpenMVG
- `OPENMVS_BIN` &ndash; путь до папки с бинарниками OpenMVS
- `LD_LIBRARY_PATH` &ndash; в нее прописан путь до скомпилированного OpenCV (для штатного скорее всего эта строчка не нужна)
- `CAMERA_SENSOR_WIDTH_DIRECTORY`

> Если принудительно не указывать пути установки OpenMVG/OpenMVS в ключах cmake, то пути в скрипте можно оставить без изменений.

Хелп:

```bash
$python 3dr.py -h
usage: 3dr.py [-h] [-f FIRST_STEP] [-l LAST_STEP] [--0 0 [0 ...]] [--1 1 [1 ...]] [--2 2 [2 ...]] [--3 3 [3 ...]]
              [--4 4 [4 ...]] [--5 5 [5 ...]] [--6 6 [6 ...]] [--7 7 [7 ...]] [--8 8 [8 ...]] [--9 9 [9 ...]]
              [--10 10 [10 ...]] [--11 11 [11 ...]] [--12 12 [12 ...]] [--13 13 [13 ...]]
              input_dir output_dir

Photogrammetry reconstruction with these steps :
        0. Intrinsics analysis   /usr/local/bin/openMVG_main_SfMInit_ImageListing
        1. Compute features      /usr/local/bin/openMVG_main_ComputeFeatures
        2. Compute matching pairs        /usr/local/bin/openMVG_main_PairGenerator
        3. Compute matches       /usr/local/bin/openMVG_main_ComputeMatches
        4. Filter matches        /usr/local/bin/openMVG_main_GeometricFilter
        5. Sequential/Incremental reconstruction         /usr/local/bin/openMVG_main_SfM
        6. Colorize Structure    /usr/local/bin/openMVG_main_ComputeSfM_DataColor
        7. Structure from Known Poses    /usr/local/bin/openMVG_main_ComputeStructureFromKnownPoses
        8. Colorized robust triangulation        /usr/local/bin/openMVG_main_ComputeSfM_DataColor
        9. Export to openMVS     /usr/local/bin/openMVG_main_openMVG2openMVS
        10. Densify point cloud  /usr/local/bin/OpenMVS/DensifyPointCloud
        11. Reconstruct the mesh         /usr/local/bin/OpenMVS/ReconstructMesh
        12. Refine the mesh      /usr/local/bin/OpenMVS/RefineMesh
        13. Texture the mesh     /usr/local/bin/OpenMVS/TextureMesh

positional arguments:
  input_dir             the directory wich contains the pictures set.
  output_dir            the directory wich will contain the resulting files.

options:
  -h, --help            show this help message and exit
  -f FIRST_STEP, --first_step FIRST_STEP
                        the first step to process
  -l LAST_STEP, --last_step LAST_STEP
                        the last step to process

Passthrough:
  Option to be passed to command lines (remove - in front of option names)
  e.g. --1 p ULTRA to use the ULTRA preset in openMVG_main_ComputeFeatures

  --0 0 [0 ...]
  --1 1 [1 ...]
  --2 2 [2 ...]
  --3 3 [3 ...]
  --4 4 [4 ...]
  --5 5 [5 ...]
  --6 6 [6 ...]
  --7 7 [7 ...]
  --8 8 [8 ...]
  --9 9 [9 ...]
  --10 10 [10 ...]
  --11 11 [11 ...]
  --12 12 [12 ...]
  --13 13 [13 ...]
```

> Перед добавлением команды запуска скрипта в `CMD`/`ENTRYPOINT` рекомендуется проверить работоспособность скрипта: поднять контейнер, вручную запустить скрипт, проверить, что все ок.

Добавить в докер-файл `CMD`/`ENTRYPOINT` с командой запуска скрипта.

## Задание 4. Запуск пайплайна

Датасеты:
- `Château de Sceaux`: папка `/data/ait2/lab2/datasets/Sceaux_Castle/` на сервере.
- `Внутренний двор 1 корпуса`: папка `/data/ait2/lab2/datasets/1k_DJI_0032_out_100/` на сервере.

1. Проверить работоспособность контейнера с тестовыми данными `Château de Sceaux`.
2. Проверить работоспособность контейнера с тестовыми данными `Внутренний двор 1 корпуса`.

Для просмотра построенной 3D модели необходимо установить [Meshlab](https://www.meshlab.net/). Построенная модель лежит в папке `<output dir>/mvs/`. Нас интересуют файлы `scene_dense_mesh_refine_texture.ply` и `scene_dense_mesh_refine_texture.png`. Их необходимо скачать на хост. По умолчанию файл PLY ассоциируется с Meshlab (Windows). В случае если этого не произошло, то в Meshlab необходимо создать пустой проект и перетащить PLY файл.

## Задание 5. Запуск пайплайна на своих данных

Необходимо сделать несколько разноракурсных снимков какого-либо объекта. Объект должен быть контрастным (желательно). Под разными ракурсами понимается съемка с разных точек обзора интересуемого объекта (см. [пример](#пример)).

### Пример

Пример на сервере в `/data/ait2/lab2/example/` или [на Яндекс.Диск](https://disk.yandex.ru/d/henOc3dMPm8Sug)).  
В примере:
- `in` &ndash; папка с исходными изображениями (объект интереса &ndash; сломанное крепление)
- `out/scene_dense_mesh.ply` &ndash; построенная модель (без текстур)
- `out/scene_dense_mesh_180_600_s.ply` &ndash; модель после обработки в Meshlab (сглаживание поверхности в несколько этапов)
- `out/FishingBoat.mp4` &ndash; запись визуализации модели в Meshlab

## Примечания

### Установка CUDA и компиляция OpenCV

Для последующих этапов (компиляция OpenMVG/OpenMVS) необходимо прописать пути к CUDA/OpenCV в переменные среды. Обычно команды прописываются в файл `~/.bashrc` или `~/.bash_profile` (см. [Startup source files](https://en.wikipedia.org/wiki/Bash_(Unix_shell)#Startup_source_files)) для считывания данных переменных при запуске оболочки bash/shell. В докер-файле необходимо воспользоваться `ENV`. Либо использовать способ из 1 лабораторной ([скрипт build_env.sh](../lab_1/data/build_env.sh))

> Пути в переменных среды указываются через двоеточие `:` (в конце добавляется само значение переменной среды):
> ```bash
> PATH="<path 1>:<path 2>:$PATH"
> ```
> Поэтому для CUDA и OpenCV необходимые пути можно добавить в одну команду.

В bash-скрипте это будет выглядеть так:

```bash
export LD_LIBRARY_PATH="<CUDA lib dir>:<OpenCV lib dir>:$LD_LIBRARY_PATH"
```

#### CUDA

Необходимо в `PATH` добавить путь до `<путь установки CUDA>/bin` (в данной директории располагаются компилятор `nvcc` и другие бинарники). Например:

```bash
PATH="/usr/local/cuda-12.2/bin:$PATH"
```

Также необходимо прописать путь до `<путь установки CUDA>/lib64` (в данной директории располагаются библиотеки для линковки). Например:

```bash
LD_LIBRARY_PATH="/usr/local/cuda-12.2/lib64:$LD_LIBRARY_PATH"
```

#### OpenCV

Необходимо прописать путь до `<путь установки OpenCV>/lib` (в данной директории располагаются библиотеки для линковки). Например:

```bash
LD_LIBRARY_PATH="/usr/local/OpenCV-4.8.0/lib:$LD_LIBRARY_PATH"
```

### Сборка CUDA + OpenCV + OpenMVG + OpenMVS

Компиляция на боевой системе (не образа контейнера) с предварительно предустановленной CUDA и скомпилированным из исходников OpenCV.

- ОС: `Ubuntu 22.04 LTS`
- OpenCV 4.8.0
- CUDA 12.2

#### OpenMVG

Зависимости:

```bash
sudo apt -y install libpng-dev libjpeg-dev libtiff-dev libxxf86vm1 libxxf86vm-dev libxi-dev libxrandr-dev
sudo apt -y install graphviz
sudo apt -y install qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools libqt5svg5-dev
```

Клонирование репа и компиляция:

```bash
cd ~/Downloads
git clone --recursive https://github.com/openMVG/openMVG.git
cd openMVG
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=RELEASE -DOpenMVG_BUILD_TESTS=ON ../src/
sudo cmake --build . --target install
make test
ctest --output-on-failure -j
```

#### OpenMVS

Зависимости:

```bash
sudo apt install libboost-all-dev libeigen3-dev libcgal-dev libglew-dev libglfw3-dev
```

VCG library:

```bash
cd ~/Downloads
git clone https://github.com/cnr-isti-vclab/vcglib.git
```

Клонирование репа и компиляция:

```bash
cd ~/Downloads
git clone --recurse-submodules https://github.com/cdcseacave/openMVS.git
cd openMVS
mkdir build_openmvs && cd build_openmvs
cmake .. -DVCG_DIR=~/Downloads/vcglib -DCMAKE_BUILD_TYPE=Release
cmake --build . -j4
sudo cmake --install .
```