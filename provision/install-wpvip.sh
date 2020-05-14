function git_install {
  local TARGET=${1}
  local SOURCE=${2}

  if [[ -z "${TARGET}" ]]; then
    exit 1
  fi
  if [[ -z "${SOURCE}" ]]; then
    exit 1
  fi

  if [ ! -d ${TARGET} ]
  then
    noroot mkdir -p ${TARGET}
  fi

  local OLD_PATH="$(pwd)"
  cd ${TARGET}

  if [ ! -d ${TARGET}/.git ]; then

    noroot git init
    noroot git remote add origin "${SOURCE}"
    noroot git fetch
    noroot git checkout origin/master -b master
    noroot git submodule update --init --recursive

  else

    noroot git fetch --prune
    noroot git checkout master
    noroot git reset --hard origin/master
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

  if [ ! -d ${TARGET} ]
  then
    noroot mkdir -p ${TARGET}
  fi

  local OLD_PATH="$(pwd)"
  cd ${TARGET}

  if [ ! -d ${TARGET}/.svn ]; then
    noroot svn checkout ${SOURCE} ${TARGET}
  else
    noroot svn cleanup ${TARGET}
    noroot svn update ${TARGET}
  fi

  cd "${OLD_PATH}"

}

function maybe_install_vipclassic() {
  WP_VIP=$(get_config_value 'wp_vip' false | awk '{print tolower($0)}')

  if [[ ! "${WP_VIP}" =~ classic ]]; then
    return 0
  fi

  git_install "${WP_MU_PLUGINS_DIR}" "https://github.com/automattic/vip-wpcom-mu-plugins.git"
  svn_install "${WP_CONTENT_DIR}/themes/vip/plugins" "https://vip-svn.wordpress.com/plugins/"

}

function maybe_install_vipgo() {
  WP_VIP=$(get_config_value 'wp_vip' false | awk '{print tolower($0)}')

  if [[ ! "${WP_VIP}" =~ go ]]; then
    return 0
  fi

  git_install "${WP_MU_PLUGINS_DIR}" "https://github.com/automattic/vip-go-mu-plugins-built.git"

}

maybe_install_vipclassic
maybe_install_vipgo
