ARG CONTAINER_REGISTRY
ARG DEBIAN_VERSION="latest"

FROM ${CONTAINER_REGISTRY}debian:${DEBIAN_VERSION}

# Обновление системы
RUN apt-get update && \
    apt-get dist-upgrade -y

# ========================================
# Приготовления
# ========================================
# Установка необходимых пакетов
RUN apt-get update && \
    apt-get install -y \
      # Для скачивания исходного кода PHP
      wget \
      # Для клонирования PHP Cades
      git

# Временная директория для загрузки файлов, распаковок и прочего - только на время сборки
ARG TEMP_WORK_DIRECTORY="/temp/work-directory"
# ========================================

# ========================================
# Установка PHP
# ========================================
ARG PHP_VERSION_MAJOR
ARG PHP_VERSION_MINOR
ARG PHP_VERSION_PATCH
RUN if [ -z "${PHP_VERSION_MAJOR}" ] || [ -z "${PHP_VERSION_MINOR}" ] || [ -z "${PHP_VERSION_PATCH}" ]; then \
      echo "Необходимо указать переменные PHP_VERSION_MAJOR, PHP_VERSION_MINOR и PHP_VERSION_PATCH!"; \
      exit 1; \
    fi
ARG PHP_VERSION_FULL="${PHP_VERSION_MAJOR}.${PHP_VERSION_MINOR}.${PHP_VERSION_PATCH}"

# Директория с php.ini.
# Обязательно называем именно так, и экспортируем как env-переменную
ARG PHP_INI_DIR="/etc/php/${PHP_VERSION}/fpm"
ENV PHP_INI_DIR="${PHP_INI_DIR}"

# Директория, в которой будем работать
WORKDIR "${TEMP_WORK_DIRECTORY}"
# Скачивание исходных кодов
RUN wget "https://www.php.net/distributions/php-${PHP_VERSION_FULL}.tar.gz"
# Распаковка
RUN tar -xzvf "php-${PHP_VERSION_FULL}.tar.gz"
RUN rm "php-${PHP_VERSION_FULL}.tar.gz"
# Заходим в образовавшуюся папку
WORKDIR "${TEMP_WORK_DIRECTORY}/php-${PHP_VERSION_FULL}"

# Установка необходимых пакетов
RUN apt-get update && \
    apt-get install -y \
      autoconf \
      build-essential \
      curl \
      libtool \
      libssl-dev \
      libcurl4-openssl-dev \
      libxml2-dev \
      libreadline-dev \
      libzip-dev \
      openssl \
      pkg-config \
      zlib1g-dev \
      libsqlite3-dev \
      libonig-dev \
      libpq-dev \
      libpng-dev \
      libjpeg-dev \
      libwebp-dev \
      libxpm-dev

# Пользователь и группа
ARG PHP_USER_NAME="www-data"
ARG PHP_USER_GROUP="www-data"

# Настройка расширений PHP
RUN ./configure \
      --sysconfdir="${PHP_INI_DIR}" \
      --with-config-file-path="${PHP_INI_DIR}" \
      --with-config-file-scan-dir="${PHP_INI_DIR}/conf.d" \
      --with-pdo-mysql \
      --with-pdo-mysql=mysqlnd \
      --with-pdo-pgsql="/usr/bin/pg_config" \
      --with-fpm-user="${PHP_USER_NAME}" \
      --with-fpm-group="${PHP_USER_GROUP}" \
      --with-zlib \
      --with-curl \
      --with-pear \
      --with-openssl \
      --with-readline \
      --with-jpeg \
      --enable-mysqlnd \
      --enable-bcmath \
      --enable-fpm \
      --enable-mbstring \
      --enable-phpdbg \
      --enable-shmop \
      --enable-sockets \
      --enable-sysvmsg \
      --enable-sysvsem \
      --enable-sysvshm \
      --enable-pcntl \
      --enable-gd
RUN make
RUN make install

# Проверка установки
RUN php -v
RUN php-fpm -v
RUN php-config --version
# ========================================

# ========================================
# Настройка PHP
# ========================================
# Директория, в которой будем работать
WORKDIR "${TEMP_WORK_DIRECTORY}/php-${PHP_VERSION_FULL}"

# Копирование файлов конфигурации
RUN mkdir --parents "${PHP_INI_DIR}"
RUN cp -T "php.ini-development" "${PHP_INI_DIR}/php.ini"
RUN cp -T "${PHP_INI_DIR}/php-fpm.conf.default" "${PHP_INI_DIR}/php-fpm.conf"
RUN cp -T "${PHP_INI_DIR}/php-fpm.d/www.conf.default" "${PHP_INI_DIR}/php-fpm.d/www.conf"
# ========================================

# ========================================
# Установка CSP и Cades.
# - Версии CSP до 5.0 R3 не содержат Cades - поэтому для них ставим эти пакеты из отдельного архива;
# - "cprocsp-pki-cades" нужен для исправления ошибки "fatal error: CPPCadesCollections.h: No such file or directory" при сборке расширения PHP.
# ========================================

COPY "./cryptopro" "${TEMP_WORK_DIRECTORY}/cryptopro"

ARG CSP_VERSION_MAIN
ARG CSP_VERSION_REDACTION
RUN if [ -z "${CSP_VERSION_MAIN}" ] || [ -z "${CSP_VERSION_REDACTION}" ]; then \
      echo "Необходимо указать переменные CSP_VERSION_MAIN и CSP_VERSION_REDACTION!"; \
      exit 1; \
    fi

ARG CSP_EXTRACT_NAME="linux-amd64_deb"
ARG CSP_FILE_NAME="csp${CSP_VERSION_MAIN}r${CSP_VERSION_REDACTION}_${CSP_EXTRACT_NAME}.tgz"
ARG CSP_FILE_PATH="${TEMP_WORK_DIRECTORY}/cryptopro/${CSP_FILE_NAME}"
ARG CSP_EXTRACT_PATH="${TEMP_WORK_DIRECTORY}/${CSP_EXTRACT_NAME}"

# ----------------------------------------
# Распаковка CSP
# ----------------------------------------
RUN if [ ! -f "${CSP_FILE_PATH}" ]; then \
      echo "Файл \"${CSP_FILE_NAME}\" не найден в директории \"./cryptopro\"! Найденные файлы:"; \
      ls -al "${TEMP_WORK_DIRECTORY}/cryptopro"; \
      exit 1; \
    fi && \
    tar --extract --gzip --file="${CSP_FILE_PATH}" --directory="${TEMP_WORK_DIRECTORY}" && \
    if [ ! -d "${CSP_EXTRACT_PATH}" ]; then \
      echo "Директория \"${CSP_EXTRACT_PATH}\" не найдена! Вероятно, имя директории в архиве отличается от \"${CSP_EXTRACT_NAME}\". Найденные директории:"; \
      ls -al "${TEMP_WORK_DIRECTORY}"; \
      exit 1; \
    fi
# ----------------------------------------

ARG CADES_EXTRACT_NAME="cades-linux-amd64"
ARG CADES_FILE_NAME="${CADES_EXTRACT_NAME}.tar.gz"
ARG CADES_FILE_PATH="${TEMP_WORK_DIRECTORY}/cryptopro/${CADES_FILE_NAME}"
ARG CADES_EXTRACT_PATH="${TEMP_WORK_DIRECTORY}/${CADES_EXTRACT_NAME}"

# Нужно ли устанавливать PHP Cades из репозитория GitHub или установить его из архива CSP:
# - 0: установка из архива CSP.
# - 1: установка из репозитория GitHub.
ARG INSTALL_PHP_CADES_FROM_REPO=0

RUN if { [ "${CSP_VERSION_MAIN}" -eq "50" ] && [ "${CSP_VERSION_REDACTION}" -ge "3" ] ; } || [ "${CSP_VERSION_MAIN}" -gt "50" ]; then \
      cd "${CSP_EXTRACT_PATH}" && \
      # ----------------------------------------
      # Установка CSP и Cades
      # ----------------------------------------
      ./install.sh lsb-cprocsp-devel cprocsp-pki-cades && \
      if [ "${INSTALL_PHP_CADES_FROM_REPO}" = "0" ]; then \
        ./install.sh cprocsp-pki-phpcades; \
      fi; \
      # ----------------------------------------
    else \
      cd "${CSP_EXTRACT_PATH}" && \
      # ----------------------------------------
      # Установка CSP
      # "cprocsp-rsa" нужен для исправления ошибки "Error while importing PFX Provider type not defined. [ErrorCode: 0x80090017]" при импорте файла ".pfx"
      ./install.sh lsb-cprocsp-devel cprocsp-rsa; \
      # ----------------------------------------
      \
      # ----------------------------------------
      # Распаковка Cades
      # ----------------------------------------
      if [ ! -f "${CADES_FILE_PATH}" ]; then \
        echo "Файл \"${CADES_FILE_NAME}\" не найден в директории \"./cryptopro\"! Найденные файлы:"; \
        ls -al "${TEMP_WORK_DIRECTORY}/cryptopro"; \
        exit 1; \
      fi && \
      tar --extract --gzip --file="${CADES_FILE_PATH}" --directory="${TEMP_WORK_DIRECTORY}" && \
      if [ ! -d "${CADES_EXTRACT_PATH}" ]; then \
        echo "Директория \"${CADES_EXTRACT_PATH}\" не найдена! Вероятно, имя директории в архиве отличается от \"${CADES_EXTRACT_NAME}\". Найденные директории:"; \
        ls -al "${TEMP_WORK_DIRECTORY}"; \
        exit 1; \
      fi && \
      # ----------------------------------------
      \
      # ----------------------------------------
      # Установка Cades 1/2.
      # ----------------------------------------
      cd "${CADES_EXTRACT_PATH}" && \
      dpkg -i "$(find . -type f -name 'cprocsp-pki-cades*.deb')" && \
      if [ "${INSTALL_PHP_CADES_FROM_REPO}" = "0" ]; then \
        dpkg -i "$(find . -type f -name 'cprocsp-pki-phpcades*.deb')"; \
      fi; \
      # ----------------------------------------
      \
      # ----------------------------------------
      # Установка Cades 2/2.
      # Устанавливаем "lsb-cprocsp-devel" из архива Cades.
      # Новые архивы этот файл не содержат, а без его установки, при сборке расширения PHP будет ошибка "fatal error: atldef2.h: No such file or directory".
      # Поэтому этот файл добавлен отдельно в репозиторий.
      # ----------------------------------------
      cd "${CADES_EXTRACT_PATH}" && \
      \
      lsb_cprocsp_devel="$(basename "$(find . -type f -name 'lsb-cprocsp-devel*.deb')")" && \
      if [ -z "${lsb_cprocsp_devel}" ]; then \
        cp "${TEMP_WORK_DIRECTORY}/cryptopro/lsb-cprocsp-devel_5.0.11863-5_all.deb" "${CADES_EXTRACT_PATH}" && \
        lsb_cprocsp_devel="$(basename "$(find . -type f -name 'lsb-cprocsp-devel*.deb')")"; \
      fi && \
      \
      if [ -z "${lsb_cprocsp_devel}" ]; then \
        echo "Не удалось найти файл для установки lsb-cprocsp-devel!"; \
        exit 1; \
      fi && \
      lsb_cprocsp_devel_name="$(echo "${lsb_cprocsp_devel}" | sed -E 's/\.deb$//')" && \
      \
      # Fix dependency error "lsb-cprocsp-devel : Depends: lsb-cprocsp-base (>= 5.0) but 4.0.9975-6 is to be installed"
      dpkg-deb -x "${CADES_EXTRACT_PATH}/${lsb_cprocsp_devel_name}.deb" "${CADES_EXTRACT_PATH}/${lsb_cprocsp_devel_name}" && \
      dpkg-deb --control "${CADES_EXTRACT_PATH}/${lsb_cprocsp_devel_name}.deb" "${CADES_EXTRACT_PATH}/${lsb_cprocsp_devel_name}/DEBIAN" && \
      sed -Ei 's/(lsb-cprocsp-base \()>= 5\.0(\))/\1>= 4.0\2/' "${CADES_EXTRACT_PATH}/${lsb_cprocsp_devel_name}/DEBIAN/control" && \
      dpkg -b "${CADES_EXTRACT_PATH}/${lsb_cprocsp_devel_name}" "${CADES_EXTRACT_PATH}/${lsb_cprocsp_devel_name}.deb" && \
      \
      dpkg -i "${lsb_cprocsp_devel_name}.deb"; \
      # ----------------------------------------
    fi

ENV PATH="/opt/cprocsp/bin/amd64:/opt/cprocsp/sbin/amd64:${PATH}"

# Проверка установки
RUN certmgr --help
# ========================================

# ========================================
# Установка расширения CryptoPro для PHP
# ========================================
ARG PHP_CADES_DIRECTORY="/opt/cprocsp/src/phpcades"
RUN \
    # Способ 1: Использование системного PHP Cades (с патчем)
    if [ "${INSTALL_PHP_CADES_FROM_REPO}" = "0" ]; then \
      cd "${PHP_CADES_DIRECTORY}" && \
      # Применение патча
      patch -p0 < "${TEMP_WORK_DIRECTORY}/cryptopro/php${PHP_VERSION_MAJOR}_support.patch"; \
    # Способ 2: Исходный код php-cades отдельно (уже пропатченный)
    else \
      mkdir --parents /opt/cprocsp/src && \
      git clone https://github.com/CryptoPro/phpcades.git "${PHP_CADES_DIRECTORY}"; \
    fi

# Указание версии PHP
RUN sed -i "s#PHPDIR=/php#PHPDIR=${TEMP_WORK_DIRECTORY}/php-${PHP_VERSION_FULL}#g" "${PHP_CADES_DIRECTORY}/Makefile.unix"

# To fix "fatal error: boost/shared_ptr.hpp: No such file or directory"
RUN apt-get update && \
    apt-get install -y libboost-dev

# Сборка
RUN eval "$(/opt/cprocsp/src/doxygen/setenv.sh --64)" && \
    cd "${PHP_CADES_DIRECTORY}" && \
    # Указываем "-fpermissive" для исправления ошибки "error: declaration does not declare anything [-fpermissive]" из-за типа "__s32".
    add_CPPFLAGS=-fpermissive make -f Makefile.unix

# Копирование собранного файла расширения
RUN mv "${PHP_CADES_DIRECTORY}/libphpcades.so" "$(php -i | grep '^extension_dir => ' | awk '{print $3}')"

# Включение расширения
RUN mkdir "${PHP_INI_DIR}/conf.d" && \
    echo "extension=libphpcades.so" >> "${PHP_INI_DIR}/conf.d/cryptopro_custom_settings.ini"

# Проверка установки
RUN php -r "var_dump(class_exists('CPStore'));" | grep -q 'bool(true)'
# ========================================

# ========================================
# TODO: Остальная установка
# ========================================
# ...
# ========================================

# ========================================
# Очистка лишних файлов и кешей для уменьшения размера образа
# ========================================
# Очистка APT
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Очистка директории, использованной для загрузки файлов, распаковок и прочего
RUN rm -r "${TEMP_WORK_DIRECTORY}"

# Очистка временных файлов
RUN rm -rf /tmp/* /var/tmp/*
# ========================================