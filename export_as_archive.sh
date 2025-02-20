#!/bin/sh

main() {
  realpath_for_script="$(realpath "$0")" || return "$?"
  basename_for_script="$(basename "${realpath_for_script}")" || return "$?"

  if [ "${basename_for_script}" != "export_as_archive.sh" ]; then
    echo "Этот скрипт нужно запускать напрямую!" >&2
    return 1
  fi

  repository_path="$(dirname "${realpath_for_script}")" || return "$?"
  repository_name="$(basename "${repository_path}")" || return "$?"
  repository_name_new="${repository_name}-example" || return "$?"
  repository_path_new="${HOME}/${repository_name_new}" || return "$?"

  # Copy current repository
  if [ -d "${repository_path_new}" ]; then
    rm -rf "${repository_path_new}" || return "$?"
  fi
  cp -r "${repository_path}" "${repository_path_new}" || return "$?"

  git -C "${repository_path_new}" clean -dfX || return "$?"
  rm -rf "${repository_path_new}/.git" || return "$?"
  find "${repository_path_new}" -type f -name ".gitignore" -exec rm -f {} \; || return "$?"
  find "${repository_path_new}" -type f -name ".gitkeep" -exec rm -f {} \; || return "$?"
  rm "${repository_path_new}/LICENSE" || return "$?"
  rm "${repository_path_new}/export_as_archive.sh" || return "$?"
  sed -Ei "s/${repository_name}/${repository_name_new}/g" "${repository_path_new}/README.md" || return "$?"
  sed -Ei "s/^(.+)git clone.*\$/\\1cd ${repository_name_new}/" "${repository_path_new}/README.md" || return "$?"
  sed -Ei 's/Склонировать проект/Перейти в директорию с файлом docker-compose.yml/' "${repository_path_new}/README.md" || return "$?"

  # Create archive
  archive_path="${HOME}/${repository_name_new}.tar.gz" || return "$?"
  tar -czf "${archive_path}" -C "${HOME}" "${repository_name_new}" || return "$?"
}

main "$@" || exit "$?"
