# Обработка изображений в OpenCV

1. Выбрать любой алгоритм (или несколько) обработки изображений:
   - гамма-коррекция  
     ```math
     I_{out} = (\frac{I_{in}}{255})^\frac{1}{\gamma} \cdot 255
     ```
   - кривая коррекции, например, логистическая кривая (*S-curve*)
     ```math
     \displaylines{S = \frac{L}{1 + e^{-k \cdot (x - x_0)}} \\
     L = 1, k = 1, x_0 = 0 \\
     S(x) = \frac{1}{1 + e^{-k \cdot x}} \\
     I_{out} = (\frac{I_{in}}{255} \cdot S(x)) \cdot 255}
     ```  
     <div align="center">
        <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/8/88/Logistic-curve.svg/600px-Logistic-curve.svg.png" width="600" title="S-curve"/>
        <p style="text-align: center">
          Рисунок 1 &ndash; <i>S-curve</i>
        </p>
      </div>
   - контрастирование
   ```math
   I_{out} = \alpha \cdot I_{in} + \beta
   ```
   - изменение баланса белого
   - пороговая обработка, *T* &ndash; значение порога
   ```math
   I_{out}(x, y) = 
   \begin{cases}
    255    & \quad \text{если } I_{in}(x, y) > T \\
    0  & \quad \text{иначе}
   \end{cases}
   ```
   - наложение (бленд) изображений
   ```math
   I_{out} = \alpha \cdot I_1 + \beta \cdot I_2
   ```
   - выделение контуров
   - и др.  
  
   > Вариант для желающих повозиться: реализовать поиск ключевых точек на паре изображений с использованием SURF:
   > - Комбо из гайдов 
   >  - [Introduction to SURF (Speeded-Up Robust Features)](https://docs.opencv.org/4.10.0/df/dd2/tutorial_py_surf_intro.html)
   >  - [Feature Matching](https://docs.opencv.org/4.10.0/dc/dc3/tutorial_py_matcher.html)
   >  - [Feature Matching + Homography to find Objects](https://docs.opencv.org/4.x/d1/de0/tutorial_py_feature_homography.html)
   >  - [Features2D + Homography to find a known object](https://docs.opencv.org/4.10.0/d7/dff/tutorial_feature_homography.html).
   > - [Image Feature Extraction in OpenCV: Keypoints and Description Vectors](https://machinelearningmastery.com/opencv_sift_surf_orb_keypoints/)
   > - [Feature Based Image Alignment using OpenCV (C++/Python)](https://learnopencv.com/image-alignment-feature-based-using-opencv-c-python/)
   > - [OpenCV Python – Implementing feature matching between two images using SIFT]()  
   > Исходные данные &ndash; пара фотографий с одним и тем же объектом, но с разных ракурсов.  
   > Результат: изображение с отрисовкой матчей (`drawMatches`). 

2. Применить выбранный алгоритм (алгоритмы) к любому изображению, привести результаты обработки.

Полезные ссылки:
- [OpenCV Image Filtering](https://docs.opencv.org/4.x/d4/d86/group__imgproc__filter.html)
- [OpenCV Color Space Conversions](https://docs.opencv.org/4.x/d8/d01/group__imgproc__color__conversions.html) - 
основной метод `cvtColor` и различные поля `enum cv::ColorConversionCodes`.
- [OpenCV Color conversions](https://docs.opencv.org/4.x/de/d25/imgproc_color_conversions.html)
- [Туторы на питоне](https://docs.opencv.org/4.10.0/d6/d00/tutorial_py_root.html)
- [OpenCV Getting Started with Videos, Python](https://docs.opencv.org/4.7.0/dd/d43/tutorial_py_video_display.html)
