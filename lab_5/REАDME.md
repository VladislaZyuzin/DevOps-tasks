# Лабораторная работа №5

## Цель работы
* Сделать мониторинг сервиса поднятого в k8s с помощью Prometheus и Grafana. Показать 2 рабочих графика, прикрепить скрины процесса.

## Ход работы 
Сначала был поднят мой сервис в миникубе, который был взят из 3 лабораторной работы, URL сайта виден, так как кубер поднят. Далее были введены команды для установки helm: 
```bash
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```
После потребовалось установить инструмент для снятия метрик с сайта - Prometheus, для этого вводим команды как на скрине: 
![Снимок экрана от 2025-03-13 12-38-11](https://github.com/user-attachments/assets/7afdc1e3-9264-4b02-8244-557ee3dbc14c)

![Снимок экрана от 2025-03-13 12-38-58](https://github.com/user-attachments/assets/21e4169c-6d02-48c5-beaf-4397f12677ad)

![Снимок экрана от 2025-03-13 12-39-30](https://github.com/user-attachments/assets/ea5d98bd-fa20-4ac4-a368-f454f9e08d16)

![Снимок экрана от 2025-03-13 12-45-33](https://github.com/user-attachments/assets/d04ca714-f870-47e5-ad62-d12028c6cac7)

![Снимок экрана от 2025-03-13 13-12-17](https://github.com/user-attachments/assets/26a06af3-c1eb-478b-8b8b-ff5b4bb2f184)

![Снимок экрана от 2025-03-13 13-23-31](https://github.com/user-attachments/assets/098ae2c4-83c5-4d7f-a74d-9d9d71acf5c0)

![Снимок экрана от 2025-03-13 13-47-52](https://github.com/user-attachments/assets/8163895b-9340-485f-b8c2-03273c268def)

![Снимок экрана от 2025-03-13 13-46-39](https://github.com/user-attachments/assets/bb08f2da-1040-462e-b2e7-1c0f35004ba3)

![Снимок экрана от 2025-03-13 13-46-22](https://github.com/user-attachments/assets/d329e109-ed0a-4e94-b1b8-9d5aaea97b42)

![Снимок экрана от 2025-03-13 13-46-17](https://github.com/user-attachments/assets/4b3b5bd8-5000-4e31-9393-980ef331e8f4)

![Снимок экрана от 2025-03-13 13-46-03](https://github.com/user-attachments/assets/f8126e1b-6ccc-4842-becd-0c3da6025abf)

![Снимок экрана от 2025-03-13 13-44-40](https://github.com/user-attachments/assets/91e387d9-d13f-4658-9c1a-0f92d43cd085)

![Снимок экрана от 2025-03-13 13-50-00](https://github.com/user-attachments/assets/3adfcb7a-a385-4d62-812c-3d13b11b8d5f)

![Снимок экрана от 2025-03-13 13-50-30](https://github.com/user-attachments/assets/d2c653e1-15a6-4180-a001-9323b9302f17)

