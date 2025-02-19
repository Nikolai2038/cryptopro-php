#!/bin/bash

# Fail command if any of pipeline blocks fail
set -o pipefail || exit "$?"

# ========================================
# Установка ini-настроек PHP
# ========================================
echo "Установка ini-настроек PHP..."

if [ "${CI_ENVIRONMENT_NAME}" = "dev" ] || [ "${CI_ENVIRONMENT_NAME}" = "test" ]; then
  custom_settings_file="${PHP_INI_DIR}/conf.d/xdebug_custom_settings.ini"
  # shellcheck disable=SC2320
  echo "xdebug.client_host=${XDEBUG_IP}" >> "${custom_settings_file}" || exit "$?"

  xdebug_log_level=0
  if ((XDEBUG_IS_LOGS_VISIBLE)); then
    xdebug_log_level=7
  fi
  # shellcheck disable=SC2320
  echo "xdebug.log_level=${xdebug_log_level}" >> "${custom_settings_file}" || exit "$?"
fi

# Настройка временной зоны
# shellcheck disable=SC2320
echo "date.timezone = \"${TZ}\"" > "${PHP_INI_DIR}/conf.d/tz.ini" || exit "$?"
# ========================================

# ========================================
# Проверка установленных версий
# ========================================
echo "========================================"
echo "Дистрибутив:"
echo "========================================"

cat /etc/*-release || exit "$?"

echo "========================================"
echo "Установленные версии компонентов:"
echo "========================================"

echo "php:"
php --version || exit "$?"
echo "----------------------------------------"

echo "php-fpm:"
php-fpm -v || exit "$?"
echo "----------------------------------------"

echo "php-config:"
php-config --version || exit "$?"
echo "----------------------------------------"

echo "Composer:"
composer --version || exit "$?"
echo "----------------------------------------"

echo "Лицензия CryptoPRO:"
cpconfig -license -view || echo "Нет лицензии" >&2 || exit "$?"
echo "----------------------------------------"

echo "Сертификаты CryptoPRO:"
su "${PHP_USER_NAME}" -s /bin/bash -c "/opt/cprocsp/bin/amd64/certmgr -list" || echo "Нет лицензии" >&2 || exit "$?"
echo "----------------------------------------"

echo "Тестовый контейнер CryptoPRO:"
csptest -keyset -enum_cont -verifyc -fq || echo "Нет лицензии" >&2 || exit "$?"
echo "========================================"
# ========================================

echo "Запуск команды \"$*\"..."
exec "$@" || exit "$?"
