# cryptopro-php

Пример интеграции CryptoPro с PHP.

## 1. Подготовка

1. Установить Docker;
2. Склонировать проект:

    ```sh
    git clone https://github.com/Nikolai2038/cryptopro-php
    ```

3. Создать файл `.env` из шаблона:

    ```sh
    cp .env.example .env
    ```

4. В зависимости от необходимой версии (привязана к лицензии), скачать архив CSP и положить его в папку `./cryptopro`:

    - [CSP 40r3](https://cryptopro.ru/sites/default/files/private/csp/40/9944/linux-amd64_deb.tgz): `./cryptopro/csp40r3_linux-amd64_deb.tgz`;
    - [CSP 40r4](https://cryptopro.ru/sites/default/files/private/csp/40/9963/linux-amd64_deb.tgz): `./cryptopro/csp40r4_linux-amd64_deb.tgz`;
    - [CSP 50r1](https://cryptopro.ru/sites/default/files/private/csp/50/11455/linux-amd64_deb.tgz): `./cryptopro/csp50r1_linux-amd64_deb.tgz`;
    - [CSP 50r2](https://cryptopro.ru/sites/default/files/private/csp/50/12000/linux-amd64_deb.tgz): `./cryptopro/csp50r2_linux-amd64_deb.tgz`;
    - [CSP 50r3](https://cryptopro.ru/sites/default/files/private/csp/50/13000/linux-amd64_deb.tgz): `./cryptopro/csp50r3_linux-amd64_deb.tgz`;
    - При необходимости доступны [другие версии и архитектуры](https://cryptopro.ru/products/csp/downloads).

5. В файле `.env` указать выбранную версию CSP в переменных:

    - `CSP_VERSION_MAIN`;
    - `CSP_VERSION_REDACTION`.

    Например, для версии `50r3`:

    ```env
    CSP_VERSION_MAIN=50
    CSP_VERSION_REDACTION=3
    ```

6. Для версий до `50r3` (для версии `50r3` и выше - не нужно), также необходимо скачать архив Cades и положить его в папку `./cryptopro`:

    - [Cades](https://cryptopro.ru/sites/default/files/products/cades/current_release_2_0/cades-linux-amd64.tar.gz): `./cryptopro/cades-linux-amd64.tar.gz`;

## 2. Сборка

```sh
docker-compose build
```

## 3. Запуск

```sh
docker-compose up -d
```

## 4. Зайти в контейнер

```sh
docker-compose exec -it cryptopro-php bash
```
