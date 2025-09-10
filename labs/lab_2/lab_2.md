# Лабораторная работа №2. Docker Compose

Лекции:
- [SSH](../../lectures/lecture_1/lecture_1.md)
- [Контейнеризация. Docker](../../lectures/lecture_2/lecture_2.md)
- [Мультиконтейнерные приложения. Docker Compose](../../lectures/lecture_3/lecture_3.md)

## Задание

Запустить предобученную нейронку с использованием `pytorch` внутри контейнера. Для создания контейнера использовать `Docker Compose`.

1. Собрать контейнер с установленным PyTorch (CPU или GPU версия).
   > Проще всего собрать контейнер на базе подготовленного образа с Docker Hub, например, 
    [pytorch:2.1.0-cuda11.8-cudnn8-devel](https://hub.docker.com/layers/pytorch/pytorch/2.1.0-cuda11.8-cudnn8-devel/images/sha256-558b78b9a624969d54af2f13bf03fbad27907dbb6f09973ef4415d6ea24c80d9?context=explore).
    Можно и из обычного образа, например, Убунты. Тогда нужно будет установить CUDA определенной версии 
  при сборке контейнера, а на самом хосте поставить [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).  
   > 
   > На сервере **NVIDIA Container Toolkit** *уже установлен*.  
   > Для запуска на сервере, естественно, лучше собрать образ с GPU версией.  
   > 
   > P.S.: PyTorch или TensorFlow, в целом, неважно.
2. Написать [скрипт обработки изображений с использованием нейросети](sub_task_pytorch.md). 
   Можно выбрать любую понравившуюся модель/задачу обработки изображения нейросетью.  
   > У [niconielsen32](https://github.com/niconielsen32) в репах есть целая подборка различных заготовок по 
     [Computer Vision](https://github.com/niconielsen32/ComputerVision), например, 
     [вычисление карты глубин по изображению](https://github.com/niconielsen32/ComputerVision/blob/master/MonocularDepth/midasDepthMap.py).
   > 
3. Запустить контейнер командой:
   ```bash
   docker compose -f <имя_конфига.yaml> up
   ```
4. Запустить скрипт с реализованным алгоритмом в контейнере в примонитрованной внутри контейнера папке. 
   Результат обработки сохранить в локальной директории контейнера.
5. Убедиться в появлении результата в директории хоста.