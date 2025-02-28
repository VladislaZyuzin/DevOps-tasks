# Лабораторная работа №3 (Зюзин Владислав)
## Тeхническое задание
1. Написать “плохой” CI/CD файл, который работает, но в нем есть не менее пяти “bad practices” по написанию CI/CD
2. Написать “хороший” CI/CD, в котором эти плохие практики исправлены
3. В Readme описать каждую из плохих практик в плохом файле, почему она плохая и как в хорошем она была исправлена, как исправление повлияло на результат
## Пара теор моментов
### Что такое CI/CD?
* `CI/CD` — это сокращение от **Continuous Integration (Непрерывная интеграция)** и **Continuous Deployment (Непрерывное развертывание)**. Это подход к разработке программного обеспечения, который помогает автоматизировать процессы сборки, тестирования и развертывания кода.
> Простыми словами - это маленький тимлид, который проверяет то, какой код вы хотите загрузить в систему, проверяет его на правильность, ищет косяки в коде и несостыковки с синтаксисом, правилами, которые описаны в определённом файле и на который ссылается CI/CD в процесе линта (проверки). После успешной проверки CI/CD покажет вам зелёный свет и развернёт вашу приложуху в облаке, чтобы им могли пользоваться другие юзеры. Если нет, то CI/CD скажет, что у тебя кривые руки и тебе нужно внеси исправления в код. 
> Далее в ходе работы я распишу ещё некоторые моменты, но основная база - здесь.
## Структура моего проекта
По хорошему - нужно создать отдельный репозиторий для работы, но мне лень, если потребуется - создам. К чему это я, все основые файлы и диерктории должны быть непосредственно в main в гитхабе. Структура проекта - следующая: 
```
main:
calculator/
    __init__.py
    calculator.py
tests/
    test_calculator.py
requirements.txt
README.md
```
### Распишем остновые файлы: 
### calculator/calculator.py

Я сделал небольшой пет проект калькулятора для нагрядности использования CI/CD 

```
def add(a, b):
    return a + b

def subtract(a, b):
    return a - b

def multiply(a, b):
    return a * b

def divide(a, b):
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b
```
### __init__.py

Сначала я ничего не хотел писать в этот файл, я прочитал, что его нужно оставить просто, чтобы он был на будущее для масштабирования, но так как CI/CD у меня не запускался при пустом конструкторе, то я добавл некоторые полезные штуки сюда.
```
"""
Пакет calculator даёт функции для выполнения базовых мат. операций.
"""

from .calculator import add, subtract, multiply, divide

__all__ = ['add', 'subtract', 'multiply', 'divide']
```
Крч, тут собрание бибилиотек для моего пет проекта. Сделано это для того, чтобы пользователь в случае чего мог обратиться в конструктор и взять те бибилиотеки, которые ему нужны. 

А `__all__ `создано для того, чтобы пользователь при команде `from calculator import *` смог получить все команды.

### tests/test_calculator.py

Тут организуется тестирования, которые выявляют косяки при внесении изменений в `calculator/calculator.py`. Импортируется бибилиотека `unittest` для проведения тестов и функции из `calculator.calculator` далее путём несложных вычислений тестами будут выявлены ошибки, при масштабировании. Это было бы очень полезно при работах с матанализом или линалом.
```
import unittest
from calculator.calculator import add, subtract, multiply, divide

class TestCalculator(unittest.TestCase):
    def test_add(self):
        self.assertEqual(add(1, 2), 3)

    def test_subtract(self):
        self.assertEqual(subtract(5, 3), 2)

    def test_multiply(self):
        self.assertEqual(multiply(2, 3), 6)

    def test_divide(self):
        self.assertEqual(divide(6, 3), 2)
        with self.assertRaises(ValueError):
            divide(1, 0)
```
### requirements.txt
В линтер (своеобразный гост и сборник правил) я внёс `flake8` — это инструмент для проверки стиля и качества кода на Python. Он помогает убедиться, что ваш код соответствует стандартам написания кода, таким как PEP 8 (Python Enhancement Proposal 8), а также находит потенциальные ошибки и проблемы. В линтер можно ещё вписать поправи к `flake8`, но я этого делать не буду, так как там просто строками будут уканы поправки для работы кода. Сам код: 
```
flake8
```
все файлы были обговорены, теперь перейду непосредственно к CI/CD. 
## Плохой CI/CD 
Повторюсь, githab actions запускаются только в директроии main. В этой директроии я создал файл и директрии: `.github/workflows/bad-ci.yml`.

В него внёс следующий скрипт: 
```
name: Bad CI

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2

    - name: Install Python
      run: sudo apt-get install python3.8

    - name: Install dependencies
      run: pip install -r requirements.txt

    - name: Run tests
      run: python -m unittest discover tests

    - name: Run linter
      run: flake8 calculator

    - name: Deploy to production
      run: echo "Deploying to production..."
```

### Расскажу что делает этот CICD: 

1. Название `workflow`:
```
name: CI
```
* Это название вашего workflow (процесса CI/CD). Оно отображается в интерфейсе GitHub Actions.

2. Триггеры для запуска:
```
on: [push]
```
Workflow будет запускаться при создании или обновлении пул-реквеста (запроса на слияние изменений).

3. Определение `jobs`:
```
jobs:
```
* В этом разделе определяются задачи (jobs), которые будут выполняться в рамках workflow.

4. Название job:
```
  build:
```
* Это название задачи (job). Вы можете назвать его как угодно, например, test, lint, или deploy.

5. ОС для выполнения `job`:
```
    runs-on: ubuntu-latest
```
* Указывает, на какой операционной системе будет выполняться job. В данном случае используется последняя версия `Ubuntu`.

6. Шаги выполнения job:
```
    steps:
```
* В этом разделе определяются шаги, которые будут выполняться в рамках job.

7. Клонирование репозитория:
```
    - uses: actions/checkout@v2
```
* Этот шаг клонирует ваш репозиторий на виртуальную машину, где выполняется job. Без этого шага у вас не будет доступа к вашему коду.

8. Установка Python:
```
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.8'
```
* name: Название шага (отображается в логах GitHub Actions).

* uses: Использует действие actions/setup-python@v2 для установки Python.

* with: Параметры для действия. В данном случае указывается версия Python (3.8).

9. Установка зависимостей:
```
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
```
* name: Название шага.

* run: Выполняет команды в shell. В данном случае:

Обновляет pip до последней версии.

Устанавливает зависимости из файла requirements.txt.

10. Запуск тестов:
```
    - name: Run tests
      run: python -m unittest discover tests
```
* name: Название шага.

* run: Запускает тесты с помощью модуля unittest. Команда discover tests автоматически находит и запускает все тесты в папке tests.

11. Запуск линтера:
```
    - name: Run linter
      run: flake8 calculator
```
* name: Название шага.

* run: Запускает flake8 для проверки стиля кода в папке calculator.

### Результат работы: 

![image](https://github.com/user-attachments/assets/71dfb5b3-f4cd-479d-a15b-5efe6cf52092)

## Хороший CI/CD
По аналогии с плохим CI/CD мы разместим хороший в директории .github/workflows/good-ci.yml. Туда внесём скрипт:
```
name: Good CI

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2

    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.8'

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt

    - name: Run tests
      run: python -m unittest discover tests

    - name: Run linter
      run: flake8 calculator

    - name: Notify on success
      if: success()
      run: echo "All tests and linting passed!"
```
### Расскажу что делает этот CICD:

1.  **Название `workflow`:**

    ```yaml
    name: Good CI
    ```

    *   Это название вашего workflow. Оно отображается в интерфейсе GitHub Actions.

2.  **Триггеры для запуска:**

    ```yaml
    on:
      push:
        branches:
          - main
      pull_request:
        branches:
          - main
    ```

    Workflow будет запускаться:

    *   При каждом пуше (изменении кода) в ветку `main`.
    *   При создании или обновлении пул-реквеста (запроса на слияние изменений) в ветку `main`.

3.  **Определение `jobs`:**

    ```yaml
    jobs:
      build:
    ```

    *   В этом разделе определяются задачи (jobs), которые будут выполняться в рамках workflow.

4.  **Название job:**

    *   `build`

    *   Это название задачи (job).

5.  **ОС для выполнения `job`:**

    ```yaml
    runs-on: ubuntu-latest
    ```

    *   Указывает, на какой операционной системе будет выполняться job. В данном случае используется последняя версия `Ubuntu`.

6.  **Шаги выполнения job:**

    ```yaml
    steps:
    ```

    *   В этом разделе определяются шаги, которые будут выполняться в рамках job.

7.  **Клонирование репозитория:**

    ```yaml
    - uses: actions/checkout@v2
    ```

    *   Этот шаг клонирует ваш репозиторий на виртуальную машину, где выполняется job. Без этого шага у вас не будет доступа к вашему коду.

8.  **Установка Python:**

    ```yaml
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.8'
    ```

    *   `name`: Название шага (отображается в логах GitHub Actions).
    *   `uses`: Использует действие `actions/setup-python@v2` для установки Python.
    *   `with`: Параметры для действия. В данном случае указывается версия Python (3.8).

9.  **Установка зависимостей:**

    ```yaml
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
    ```

    *   `name`: Название шага.
    *   `run`: Выполняет команды в shell. В данном случае:

        *   Обновляет pip до последней версии.
        *   Устанавливает зависимости из файла `requirements.txt`.

10. **Запуск тестов:**

    ```yaml
    - name: Run tests
      run: python -m unittest discover tests
    ```

    *   `name`: Название шага.
    *   `run`: Запускает тесты с помощью модуля `unittest`. Команда `discover tests` автоматически находит и запускает все тесты в папке `tests`.

11. **Запуск линтера:**

    ```yaml
    - name: Run linter
      run: flake8 calculator
    ```

    *   `name`: Название шага.
    *   `run`: Запускает `flake8` для проверки стиля кода в папке `calculator`.

12. **Уведомление об успешном завершении:**

    ```yaml
    - name: Notify on success
      if: success()
      run: echo "All tests and linting passed!"
    ```

    *   `name`: Название шага.
    *   `if`: Условие для выполнения шага. `success()` означает, что шаг выполнится только в случае успешного завершения предыдущих шагов.
    *   `run`: Выполняет команду в shell. В данном случае выводит сообщение "All tests and linting passed!" в лог. Это полезно для получения обратной связи об успешном прохождении CI.






