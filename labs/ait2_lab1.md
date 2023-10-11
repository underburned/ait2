# Лабораторная работа №1. Перцептрон

[Лекция](../lectures/ait2_lec1.ipynb)

0. Выбрать любой подходящий датасет для классификации, например [digits dataset из sklearn](https://scikit-learn.org/stable/modules/generated/sklearn.datasets.load_digits.html)
или [MNIST из keras](https://keras.io/api/datasets/mnist/).
1. Реализовать однослойный перцептрон без использования библиотек.
   - Выбрать функцию активации, например, сигмоиду.
   - Реализовать прямой проход.
   - Вычислить ошибку.
   - Реализовать обратный проход, скорректировать веса НС.
   - Реализовать функцию обучения НС с параметром количества эпох (итераций).
   - Вывести метрики, построить сопутствующие графики.
2. Сравнить результаты с использованием [однослойного перцептрона из sklearn](https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.Perceptron.html).
3. Сравнить результаты с использованием [многослойного перцептрона из sklearn](https://scikit-learn.org/stable/modules/generated/sklearn.neural_network.MLPClassifier.html).