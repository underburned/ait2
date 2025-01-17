# Многоступенчатая сборка образа с экспортным слоем (отладка)

Рассмотрим многоступенчатую сборку образа с целью отладки ошибок сборки образа.

Разобьем проблемный докер-файл сначала на 2 этапа сборки:
- подготовительный &ndash; `prep-stage`
- сборки (компиляции) &ndash; `build-stage`

## Подготовительный этап &ndash; `prep-stage`

> В `prep-stage` мы осуществим установку всех компонентов, необходимых для компиляции OpenCV.

В начале докер-файла укажем псевдоним `prep-stage` для первого этапа сборки образа (первое упоминание команды `FROM`).

```dockerfile
ARG ubuntu_ver=22.04
FROM ubuntu:$ubuntu_ver AS prep-stage
ENV DEBIAN_FRONTEND=noninteractive
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
...
```

Далее подправим команду `cmake`, которая конфигурирует компиляцию библиотеки и генерирует `Makefile` с инструкциями для компилятора:

```dockerfile
RUN . /usr/local/Dev/build_env.sh && cmake_command="-D CMAKE_BUILD_TYPE=RELEASE \
-D CMAKE_EXPORT_COMPILE_COMMANDS=on \
-D CMAKE_INSTALL_PREFIX=/usr/local/OpenCV-${ocv_ver} \
-D OPENCV_SKIP_PYTHON_LOADER=OFF \
-D OPENCV_PYTHON3_INSTALL_PATH=/usr/local/OpenCV-${ocv_ver}/lib/python${py3_ver_mm}/site-packages \
-D OPENCV_PYTHON3_VERSION=${py3_ver_mmm} \
-D BUILD_opencv_python2=OFF \
-D BUILD_opencv_python3=ON \
-D BUILD_opencv_python_bindings_generator=ON \
-D PYTHON_DEFAULT_EXECUTABLE=$(which python3) \
-D PYTHON3_EXECUTABLE=$(which python3) \
-D PYTHON3_INCLUDE_DIR=${py3_inc_dir} \
-D PYTHON3_PACKAGES_PATH=${py3_lib_dir} \
-D PYTHON3_LIBRARY=${py3_lib_path} \
-D PYTHON3_NUMPY_INCLUDE_DIRS=${py3_np_inc_dirs} \
-D WITH_OPENCL=ON \
-D WITH_OPENMP=ON \
-D WITH_CUDA=ON \
-D WITH_CUDNN=OFF \
-D WITH_NVCUVID=OFF \
-D WITH_CUBLAS=ON \
-D WITH_GSTREAMER=ON \
-D ENABLE_FAST_MATH=1 \
-D CUDA_FAST_MATH=1 \
-D BUILD_opencv_cudacodec=OFF \
-D INSTALL_PYTHON_EXAMPLES=ON \
-D INSTALL_C_EXAMPLES=ON \
-D OPENCV_ENABLE_NONFREE=ON \
-D OPENCV_EXTRA_MODULES_PATH=/usr/local/Dev/opencv_contrib-${ocv_ver}/modules \
-D BUILD_EXAMPLES=ON .." && echo ${cmake_command} && echo ${cmake_command} > cmake_command.txt && cmake ${cmake_command}
```

> `-D CMAKE_EXPORT_COMPILE_COMMANDS=on` включает режим экспорта команд компиляции в файл формата JSON `compile_commands.json`, который сохраняется в директории сборки (папка `build` в нашем случае). Может оказаться полезным.

`echo ${cmake_command} > cmake_command.txt` сохраняет вышеуказанную команду для `cmake` в текстовый файл.  
Далее допишем еще несколько команд:

```dockerfile
RUN echo $(cmake -LA) > cmake_vars.txt
RUN echo $(sed 's/-D /\\n-D /g' cmake_command.txt) > cmake_command_splitted.txt
RUN echo $(sed 's/ /\\n/g' cmake_vars.txt) > cmake_vars_splitted.txt
```

Данные команды осуществляют следующие операции:
- сохранение результата выполнения команды `cmake -LA` в текстовый файл `cmake_vars.txt`
  > `cmake -LA` возвращает строку со списком всех атрибутов (переменных), которые используются в `CMakeList`'ах и файлах `findPackage`. Это может помочь с обнаружением неправильно установленных или пропущенных (NOTFOUND) путей до различных зависимостей.
- чтение `cmake_command.txt` и сплит по разделителю аргумента `-D` в файл `cmake_command_splitted.txt`
- чтение `cmake_vars.txt` и сплит по разделителю аргумента `-D` в файл `cmake_vars_splitted.txt`

## Этап сборки (компиляции) &ndash; `build-stage`

> В `build-stage` мы траим компиляцию.

Допустим, процесс компиляции завершается с ошибкой. Добавим новый этап `build-stage`, который будет основан на `prep-stage`:

```dockerfile
FROM prep-stage AS build-stage
ARG ocv_ver
ARG ocv_build_dir=/usr/local/Dev/opencv-${ocv_ver}/build/
ARG build_thread_count
ARG py3_ver_mm

RUN make -j${build_thread_count}
```

> Переменные, указываемые с использованием команды `ARG` имеют область видимости внутри конкретного образа, поэтому необходимые на этом шаге переменные среды мы снова прокидываем.

Так как `RUN make -j${build_thread_count}` завершается с ошибкой, то слой образа ***не записывается***. Это можно обойти [следующим образом](https://stackoverflow.com/questions/30716937/dockerfile-build-possible-to-ignore-error) &ndash; имитация успешного завершения команды `RUN`:

```dockerfile
RUN make -j${build_thread_count}; exit 0
```

или

```dockerfile
RUN make -j${build_thread_count} || true
```

Финальный вид:

```dockerfile
FROM prep-stage AS build-stage
ARG ocv_ver
ARG ocv_build_dir=/usr/local/Dev/opencv-${ocv_ver}/build/
ARG build_thread_count
ARG py3_ver_mm

RUN make -j${build_thread_count}; exit 0
```

Теперь у нас есть этап с частично успешной компиляцией. Допустим, мы хотим вытащить некоторые файлы для проверки логов и т.п. Нам поможет экспортный этап `export-stage`.

## Этап экспорта &ndash; `export-stage`

Добавляем в докер-файл следующие команды:

```dockerfile
FROM scratch AS export-stage
ARG ocv_ver
ARG ocv_build_dir=/usr/local/Dev/opencv-${ocv_ver}/build/
COPY --from=prep-stage ${ocv_build_dir}cmake_command.txt .
COPY --from=prep-stage ${ocv_build_dir}cmake_command_splitted.txt .
COPY --from=prep-stage ${ocv_build_dir}cmake_vars.txt .
COPY --from=prep-stage ${ocv_build_dir}cmake_vars_splitted.txt .
```

Здесь `scratch` &ndash; это пустой образ по умолчанию.  
Команды `COPY` с указанием параметра `--from=<имя этапа сборки>` позволяют копировать файлы из предыдущего этапа сборки в текущий или даже на хост. Из `prep-stage` мы скопируем файлы на хост. Команда для сборки образа будет выглядеть следующим образом:

```bash
echo Building docker
docker build --no-cache-filter export-stage --progress=plain --tag $image_tag \
             --build-arg ubuntu_ver=$ubuntu_ver \
    		 --build-arg cuda_ver=$cuda_ver \
    		 --build-arg cuda_distro=$cuda_distro \
    		 --build-arg cuda_arch=$cuda_arch \
    		 --build-arg ocv_ver=$ocv_ver \
    		 --build-arg build_thread_count=$build_thread_count \
    		 -f $dockerfile --output out .
```

Здесь:
- `--no-cache-filter` отключает кэширование слоев для определенных этапов сборки, в данном случае `export-stage` (если этапов несколько, то они указываются через запятую).
- `--output out` указывает директорию (в данном случае на хосте, но можно указать тип экспорта и путь в одной команде) &ndash; папка `out` в той же директории, из которой и запускается команда `docker build`. Подробнее: [Set the export action for the build result (-o, --output)](https://docs.docker.com/reference/cli/docker/buildx/build/#output)

> В случае применения `--output` для экспорта файловой системы ***финального образа*** экспортируются все файлы! Поэтому `export-stage` из пустого образа лучше сделать финальным или использовать аргумент `--target` для указания финального этапа сборки (все этапы, идущие после указанного в `--target` скипаются): [Specifying target build stage (--target)](https://docs.docker.com/reference/cli/docker/buildx/build/#target). В целом, можно экспортировать финальный слой образа в TAR-архив.

Пример вывода:

```bash
#42 [prep-stage 16/40] RUN rm -rf /var/lib/apt/lists/*
#42 CACHED

#43 [prep-stage 39/40] RUN echo $(sed 's/ /\\n/g' cmake_vars.txt) > cmake_vars_splitted.txt
#43 CACHED

#44 [export-stage 1/4] COPY --from=prep-stage /usr/local/Dev/opencv-4.8.0/build/cmake_command.txt .
#44 DONE 0.0s

#45 [export-stage 2/4] COPY --from=prep-stage /usr/local/Dev/opencv-4.8.0/build/cmake_command_splitted.txt .
#45 DONE 0.0s

#46 [export-stage 3/4] COPY --from=prep-stage /usr/local/Dev/opencv-4.8.0/build/cmake_vars.txt .
#46 DONE 0.0s

#47 [export-stage 4/4] COPY --from=prep-stage /usr/local/Dev/opencv-4.8.0/build/cmake_vars_splitted.txt .
#47 DONE 0.0s

#48 exporting to client directory
#48 copying files 53.20kB done
#48 DONE 0.0s
```

Допустим, экспортированные файлы нам помогли и мы исправили ошибки. Убираем экспортный шаг, возвращаем компиляцию:

```dockerfile
FROM prep-stage AS build-stage
ARG ocv_ver
ARG ocv_build_dir=/usr/local/Dev/opencv-${ocv_ver}/build/
ARG build_thread_count
ARG py3_ver_mm

RUN make -j${build_thread_count}
RUN make install
RUN ldconfig

RUN . /usr/local/Dev/build_env.sh && ln -sf /usr/local/OpenCV-${ocv_ver}/lib/python${py3_ver_mm}/site-packages/cv2/python-${py3_ver_mm}/$(ls /usr/local/OpenCV-${ocv_ver}/lib/python${py3_ver_mm}/site-packages/cv2/python-${py3_ver_mm}/) /usr/local/lib/python${py3_ver_mm}/dist-packages/cv2.so

RUN echo $(python3 -c "import cv2 as cv; print(cv.__version__)")

#RUN pip3 install <libs>

CMD [ "bash" ]
```

## Пример отладки

Процесс компиляции `OpenCV` с CUDA падает с ошибкой:

```bash
#42 2183.5 [ 85%] Building CXX object samples/cpp/CMakeFiles/example_cpp_camshiftdemo.dir/camshiftdemo.cpp.o
#42 2183.5 [ 85%] Building CXX object samples/cpp/CMakeFiles/example_cpp_cloning_gui.dir/cloning_gui.cpp.o
#42 2183.6 In file included from /usr/local/Dev/opencv-4.8.0/modules/python/src2/cv2.cpp:5:
#42 2183.6 /usr/local/Dev/opencv-4.8.0/modules/python/src2/cv2.hpp:36:10: fatal error: numpy/ndarrayobject.h: No such file or directory
#42 2183.6    36 | #include <numpy/ndarrayobject.h>
#42 2183.6       |          ^~~~~~~~~~~~~~~~~~~~~~~
#42 2183.6 compilation terminated.
#42 2183.6 make[2]: *** [modules/python3/CMakeFiles/opencv_python3.dir/build.make:76: modules/python3/CMakeFiles/opencv_python3.dir/__/src2/cv2.cpp.o] Error 1
#42 2183.6 make[1]: *** [CMakeFiles/Makefile2:20230: modules/python3/CMakeFiles/opencv_python3.dir/all] Error 2
#42 2183.6 make[1]: *** Waiting for unfinished jobs....
...
#42 2186.1 [ 86%] Built target opencv_test_videostab
#42 2186.1 make: *** [Makefile:166: all] Error 2
#42 ERROR: process "/bin/sh -c make -j${build_thread_count}" did not complete successfully: exit code: 2
...
#42 2185.9 [ 86%] Built target example_videostab_videostab
#42 2186.1 [ 86%] Built target opencv_test_videostab
#42 2186.1 make: *** [Makefile:166: all] Error 2
#42 ERROR: process "/bin/sh -c make -j${build_thread_count}" did not complete successfully: exit code: 2
------
 > [build-stage 1/5] RUN make -j14:
2185.2 [ 86%] Linking CXX executable ../../bin/example_cpp_calibration
2185.2 [ 86%] Built target example_cpp_3calibration
2185.4 [ 86%] Linking CXX executable ../../bin/example_cpp_audio_spectrogram
2185.5 [ 86%] Built target example_cpp_calibration
2185.7 [ 86%] Linking CXX executable ../../bin/example_videostab_videostab
2185.7 [ 86%] Built target example_cpp_audio_spectrogram
2185.9 [ 86%] Linking CXX executable ../../bin/opencv_test_videostab
2185.9 [ 86%] Built target example_videostab_videostab
2186.1 [ 86%] Built target opencv_test_videostab
2186.1 make: *** [Makefile:166: all] Error 2
------
OpenCVDockerFile.dockerfile:139
--------------------
 137 |     ARG py3_ver_mm
 138 |     
 139 | >>> RUN make -j${build_thread_count}
 140 |     RUN make install
```

Ключевая ошибка:
```bash
/usr/local/Dev/opencv-4.8.0/modules/python/src2/cv2.hpp:36:10: fatal error: numpy/ndarrayobject.h: No such file or directory
#42 2183.6    36 | #include <numpy/ndarrayobject.h>
```

> Причина возникновения ошибки и ее решение в [разделе Troubleshooting](lab_1.md#troubleshooting) к заданию на лабораторную работу 1.

Пример all-in-one докер-файла и shell-скрипта его сборки:
- [OpenCVDockerFileDebug.dockerfile](data/OpenCVDockerFileDebug.dockerfile)
- [build_debug.sh](data/build_debug.sh)

В данный докер-файл добавлен этап `test-stage` с повторной компиляцией (заведомо успешной после фикса ошибок) с выводом версии собранного OpenCV и версии numpy в файл:

```dockerfile
RUN echo $(python3 -c "import cv2 as cv; print(f'Compiled OpenCV version: {cv.__version__}')") > opencv_version.txt
RUN echo $(pip3 list | grep numpy) > pip3_numpy_version.txt
```

Финальный экспортный слой:

```dockerfile
FROM scratch AS export-stage
ARG ocv_ver
ARG ocv_build_dir=/usr/local/Dev/opencv-${ocv_ver}/build/
COPY --from=test-stage ${ocv_build_dir}cmake_command.txt .
COPY --from=prep-stage ${ocv_build_dir}cmake_command_splitted.txt .
COPY --from=prep-stage ${ocv_build_dir}cmake_vars.txt .
COPY --from=prep-stage ${ocv_build_dir}cmake_vars_splitted.txt .
COPY --from=prep-stage ${ocv_build_dir}apt_cache_cuda.txt .
COPY --from=build-stage ${ocv_build_dir}compile_commands.json .
COPY --from=test-stage ${ocv_build_dir}opencv_version.txt .
COPY --from=test-stage ${ocv_build_dir}pip3_numpy_version.txt .
```

Buildkit докера использует граф зависимости (dependency graph). Если промежуточный этап сборки далее нигде не используется, то он будет пропущен при сборке: [Dockerfile not executing second stage](https://stackoverflow.com/questions/65235815/dockerfile-not-executing-second-stage). Поэтому в `COPY` командах используются имена всех предыдущих этапов сборки.

Пример вывода инструкций для компиляции из `compile_commands.json` (параметр `-D CMAKE_EXPORT_COMPILE_COMMANDS=on` `cmake`'а):

```json
[
  {
    "directory": "/usr/local/Dev/opencv-4.8.0/build",
    "command": "/usr/bin/c++  -I/usr/local/Dev/opencv-4.8.0/build/3rdparty/ippicv/ippicv_lnx/icv/include -I/usr/local/Dev/opencv-4.8.0/build/3rdparty/ippicv/ippicv_lnx/iw/include -I/usr/local/Dev/opencv-4.8.0/build -I/usr/local/Dev/opencv-4.8.0/build/3rdparty/ade/ade-0.1.2a/sources/ade/include    -fsigned-char -ffast-math -W -Wall -Wreturn-type -Wnon-virtual-dtor -Waddress -Wsequence-point -Wformat -Wformat-security -Wmissing-declarations -Wundef -Winit-self -Wpointer-arith -Wshadow -Wsign-promo -Wuninitialized -Wsuggest-override -Wno-delete-non-virtual-dtor -Wno-comment -Wimplicit-fallthrough=3 -Wno-strict-overflow -fdiagnostics-show-option -Wno-long-long -pthread -fomit-frame-pointer -ffunction-sections -fdata-sections  -msse -msse2 -msse3 -fvisibility=hidden -fvisibility-inlines-hidden -fopenmp -O3 -DNDEBUG  -DNDEBUG -fPIC -std=c++11 -o CMakeFiles/ade.dir/3rdparty/ade/ade-0.1.2a/sources/ade/source/alloc.cpp.o -c /usr/local/Dev/opencv-4.8.0/build/3rdparty/ade/ade-0.1.2a/sources/ade/source/alloc.cpp",
    "file": "/usr/local/Dev/opencv-4.8.0/build/3rdparty/ade/ade-0.1.2a/sources/ade/source/alloc.cpp"
  },
  {
    "directory": "/usr/local/Dev/opencv-4.8.0/build",
    "command": "/usr/bin/c++  -I/usr/local/Dev/opencv-4.8.0/build/3rdparty/ippicv/ippicv_lnx/icv/include -I/usr/local/Dev/opencv-4.8.0/build/3rdparty/ippicv/ippicv_lnx/iw/include -I/usr/local/Dev/opencv-4.8.0/build -I/usr/local/Dev/opencv-4.8.0/build/3rdparty/ade/ade-0.1.2a/sources/ade/include    -fsigned-char -ffast-math -W -Wall -Wreturn-type -Wnon-virtual-dtor -Waddress -Wsequence-point -Wformat -Wformat-security -Wmissing-declarations -Wundef -Winit-self -Wpointer-arith -Wshadow -Wsign-promo -Wuninitialized -Wsuggest-override -Wno-delete-non-virtual-dtor -Wno-comment -Wimplicit-fallthrough=3 -Wno-strict-overflow -fdiagnostics-show-option -Wno-long-long -pthread -fomit-frame-pointer -ffunction-sections -fdata-sections  -msse -msse2 -msse3 -fvisibility=hidden -fvisibility-inlines-hidden -fopenmp -O3 -DNDEBUG  -DNDEBUG -fPIC -std=c++11 -o CMakeFiles/ade.dir/3rdparty/ade/ade-0.1.2a/sources/ade/source/assert.cpp.o -c /usr/local/Dev/opencv-4.8.0/build/3rdparty/ade/ade-0.1.2a/sources/ade/source/assert.cpp",
    "file": "/usr/local/Dev/opencv-4.8.0/build/3rdparty/ade/ade-0.1.2a/sources/ade/source/assert.cpp"
  }
]
```