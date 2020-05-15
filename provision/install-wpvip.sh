function git_install {
  local TARGET=${1}
  local SOURCE=${2}

  if [[ -z "${TARGET}" ]]; then
    exit 1
  fi
  if [[ -z "${SOURCE}" ]]; then
    exit 1
  fi

  echo "git install: ${SOURCE} ${TARGET}"

  if [ ! -d ${TARGET} ]
  then
    noroot mkdir -p ${TARGET}
  fi

  local OLD_PATH="$(pwd)"
  cd ${TARGET}

  if [ ! -d ${TARGET}/.git ]; then

    noroot git init
    noroot git remote add origin "${SOURCE}"
    noroot git fetch origin master
    noroot git checkout origin/master -b master
    noroot git submodule update --init --recursive

  fi

  cd "${OLD_PATH}"

}

function svn_install {
  local TARGET=${1}
  local SOURCE=${2}

  if [[ -z "${TARGET}" ]]; then
    exit 1
  fi
  if [[ -z "${SOURCE}" ]]; then
    exit 1
  fi

  echo "svn install: ${SOURCE} ${TARGET}"

  if [[ ! -d ${TARGET} ]]; then
    noroot mkdir -p ${TARGET}
  fi

  if [[ ! -d ${TARGET}/.git ]]; then
    return
  fi

  local OLD_PATH="$(pwd)"
  cd ${TARGET}

  if [ ! -d ${TARGET}/.svn ]; then
    noroot svn checkout ${SOURCE} ${TARGET}
  fi

  cd "${OLD_PATH}"

}

function install_vipclassic() {

  git_install "${WP_MU_PLUGINS_DIR}" "https://github.com/automattic/vip-wpcom-mu-plugins.git"
  svn_install "${WP_CONTENT_DIR}/themes/vip/plugins" "https://vip-svn.wordpress.com/plugins/"

  if [[ ! -f ${WP_MU_PLUGINS_DIR}/amp-wp/vendor/autoload.php ]]; then
    git -C ${WP_MU_PLUGINS_DIR} submodule deinit -f amp-wp
    rm -rf ${WP_MU_PLUGINS_DIR}/amp-wp
    curl -o /tmp/amp-wp.zip https://downloads.wordpress.org/plugin/amp.1.5.3.zip
    unzip /tmp/amp-wp.zip -d ${WP_MU_PLUGINS_DIR}/
    mv ${WP_MU_PLUGINS_DIR}/amp ${WP_MU_PLUGINS_DIR}/amp-wp
  fi

}

function install_vipgo() {
  git_install "${WP_MU_PLUGINS_DIR}" "https://github.com/automattic/vip-go-mu-plugins-built.git"
}

function maybe_install_plugins() {
  local REPO=$(get_config_value 'wp_plugins.repo')
  if [[ -z "${REPO}" ]]; then
    return
  fi
  git_install "${WP_PLUGINS_DIR}" "${REPO}"
}

function maybe_install_themes() {
  local WP_THEMES=$(get_config_value 'wp_themes')
  local REPO
  if [[ -z "${WP_THEMES}" ]]; then
    return
  fi

  echo "${WP_THEMES}" | shyaml keys-0 |
    while IFS='' read -r -d $'\0' theme; do
      REPO=$(get_config_value "wp_themes.${theme}.repo")
      if [[ -z "${REPO}" ]]; then
        continue;
      fi
      git_install "${WP_CONTENT_DIR}/themes/${theme}" "${REPO}"
    done

}

maybe_install_themes
maybe_install_plugins

WP_VIP=$(get_config_value 'wp_vip' false | awk '{print tolower($0)}')
if [[ ! "${WP_VIP}" =~ classic ]]; then
  install_vipclassic
elif [[ ! "${WP_VIP}" =~ go ]]; then
  install_vipgo
fi
