ARG CONTAINER_REGISTRY=""
ARG DEBIAN_VERSION="12.8"

FROM ${CONTAINER_REGISTRY}debian:${DEBIAN_VERSION}

# Обновление системы
RUN apt-get update && apt-get dist-upgrade -y

# ========================================
# Приготовления
# ========================================
# Установка необходимых пакетов
RUN apt-get update && apt install -y \
      # Для клонирования PHP Cades
      git

# Временная директория для загрузки файлов, распаковок и прочего - только на время сборки
ARG TEMP_WORK_DIRECTORY="/temp/work-directory"

COPY "./cryptopro" "${TEMP_WORK_DIRECTORY}/cryptopro"
# ========================================

# ========================================
# Установка системных пакетов CryptoPro
# ========================================

ARG CSP_VERSION_MAIN="50"
ARG CSP_VERSION_REDACTION="3"

ARG CSP_FILE_NAME="csp${CSP_VERSION_MAIN}r${CSP_VERSION_REDACTION}_linux-amd64_deb.tgz"
ARG CSP_FILE_PATH="${TEMP_WORK_DIRECTORY}/cryptopro/${CSP_FILE_NAME}"

# ----------------------------------------
# Распаковка CSP
# ----------------------------------------
RUN if [ ! -f "${CSP_FILE_PATH}" ]; then \
      echo "Файл \"${CSP_FILE_NAME}\" не найден в директории \"./cryptopro\"! Найденные файлы:"; \
      ls -al "${TEMP_WORK_DIRECTORY}/cryptopro"; \
      exit 1; \
    fi && \
    tar --extract --gzip --file="${CSP_FILE_PATH}" --directory="${TEMP_WORK_DIRECTORY}"

ARG CSP_EXTRACT_PATH="${TEMP_WORK_DIRECTORY}/linux-amd64_deb"
RUN if [ ! -d "${CSP_EXTRACT_PATH}" ]; then \
      echo "Директория \"${CSP_EXTRACT_PATH}\" не найдена! Вероятно, имя директории в архиве отличается от \"linux-amd64_deb\". Найденные директории:"; \
      ls -al "${TEMP_WORK_DIRECTORY}"; \
      exit 1; \
    fi
# ----------------------------------------

# ----------------------------------------
# Установка CSP
# ----------------------------------------
# Версии CSP до 5.0 R3 не содержат пакета "cprocsp-pki-cades"
RUN if { [ "${CSP_VERSION_MAIN}" = "50" ] && { [ "${CSP_VERSION_REDACTION}" = "3" ] || [ "${CSP_VERSION_REDACTION}" ">" "3" ]; }; } || [ "${CSP_VERSION_MAIN}" > "50" ]; then \
      cd "${CSP_EXTRACT_PATH}" && \
      ./install.sh lsb-cprocsp-devel; \
    else \
      cd "${CSP_EXTRACT_PATH}" && \
      ./install.sh lsb-cprocsp-devel cprocsp-pki-cades; \
    fi
# ----------------------------------------

# ========================================

# ========================================
# PHP Cades
# ========================================
# Исходный код php-cades
ARG PHP_CADES_DIRECTORY="${TEMP_WORK_DIRECTORY}/phpcades"
RUN git clone https://github.com/CryptoPro/phpcades.git "${PHP_CADES_DIRECTORY}"
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
RUN apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# Очистка директории, использованной для загрузки файлов, распаковок и прочего
RUN rm -r "${TEMP_WORK_DIRECTORY}"

# Очистка временных файлов
RUN rm -rf /tmp/* /var/tmp/*
# ========================================