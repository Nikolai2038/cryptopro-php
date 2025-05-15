# cryptopro-php

**EN** | [RU](README_RU.md)

Example of CryptoPro integration with PHP.

## 1. Preparations

1. Install Docker;
2. Clone the repository:

    ```sh
    git clone https://github.com/Nikolai2038/cryptopro-php
    ```

3. Create `.env` file from template:

    ```sh
    cp .env.example .env
    ```

4. Depending on the required version (linked to the license), download the CSP archive and put it in the `./cryptopro` directory:

    - [CSP 40r3](https://cryptopro.ru/sites/default/files/private/csp/40/9944/linux-amd64_deb.tgz): `./cryptopro/csp40r3_linux-amd64_deb.tgz`;
    - [CSP 40r4](https://cryptopro.ru/sites/default/files/private/csp/40/9963/linux-amd64_deb.tgz): `./cryptopro/csp40r4_linux-amd64_deb.tgz`;
    - [CSP 50r1](https://cryptopro.ru/sites/default/files/private/csp/50/11455/linux-amd64_deb.tgz): `./cryptopro/csp50r1_linux-amd64_deb.tgz`;
    - [CSP 50r2](https://cryptopro.ru/sites/default/files/private/csp/50/12000/linux-amd64_deb.tgz): `./cryptopro/csp50r2_linux-amd64_deb.tgz`;
    - [CSP 50r3](https://cryptopro.ru/sites/default/files/private/csp/50/13000/linux-amd64_deb.tgz): `./cryptopro/csp50r3_linux-amd64_deb.tgz`;
    - При необходимости доступны [другие версии и архитектуры](https://cryptopro.ru/products/csp/downloads).

5. In the `.env` file specify CSP version in variables:

    - `CSP_VERSION_MAIN`;
    - `CSP_VERSION_REDACTION`.

    For example, for version `50r3`:

    ```env
    CSP_VERSION_MAIN=50
    CSP_VERSION_REDACTION=3
    ```

6. For version before `50r3` (for version `50r3` and above - not needed), you must also download Cades archive and put it into `./cryptopro` directory:

    - [Cades](https://cryptopro.ru/sites/default/files/products/cades/current_release_2_0/cades-linux-amd64.tar.gz): `./cryptopro/cades-linux-amd64.tar.gz`;

7. Put the certificate (for example, `cert.pfx`) in `./certificates` directory;
8. In the `.env` file specify variables values for CryptoPro:

    - `CRYPTOPRO_LICENSE`;
    - `CRYPTOPRO_CERTIFICATE_PFX_FILE_NAME`;
    - `CRYPTOPRO_CERTIFICATE_PFX_FILE_PIN_OLD`;
    - `CRYPTOPRO_CERTIFICATE_PFX_FILE_PIN_NEW`;
    - `CRYPTOPRO_CERTIFICATE_PFX_FILE_HASH`.

## 2. Build

```sh
docker-compose build
```

## 3. Start

```sh
docker-compose up -d
```

## 4. Sign XML-file

```sh
docker-compose exec -it -u www-data cryptopro-php sh -c 'php -f ./src/sign_xml.php ./data/test.xml'
```

After executing this script, if everything is successful, a signed file `./data/test.xml.signed.xml` will be created.

## 5. Contribution

Feel free to contribute via [pull requests](https://github.com/Nikolai2038/cryptopro-php/pulls) or [issues](https://github.com/Nikolai2038/cryptopro-php/issues)!
