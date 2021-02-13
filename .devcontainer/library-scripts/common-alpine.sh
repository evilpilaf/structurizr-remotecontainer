#!/bin/ash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/master/script-library/docs/common.md
#
# Syntax: ./common-alpine.sh [install zsh flag] [username] [user UID] [user GID] [install Oh My *! flag]

INSTALL_ZSH=${1:-"true"}
USERNAME=${2:-"automatic"}
USER_UID=${3:-"automatic"}
USER_GID=${4:-"automatic"}
INSTALL_OH_MYS=${5:-"true"}

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

# Switch to bash right away
if [ "${SWITCHED_TO_BASH}" != "true" ]; then
    apk add bash
    export SWITCHED_TO_BASH=true
    exec /bin/bash "$0" "$@"
    exit $?
fi

# If in automatic mode, determine if a user already exists, if not use vscode
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode"  "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in ${POSSIBLE_USERS[@]}; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=vscode
    fi
elif [ "${USERNAME}" = "none" ]; then
    USERNAME=root
    USER_UID=0
    USER_GID=0
fi

# Load markers to see which steps have already run
MARKER_FILE="/usr/local/etc/vscode-dev-containers/common"
if [ -f "${MARKER_FILE}" ]; then
    echo "Marker file found:"
    cat "${MARKER_FILE}"
    source "${MARKER_FILE}"
fi

# Install git, bash, common dependencies
if [ "${PACKAGES_ALREADY_INSTALLED}" != "true" ]; then
    apk update
    apk add --no-cache \
        git \
        openssh-client \
        gnupg \
        procps \
        lsof \
        htop \
        net-tools \
        psmisc \
        curl \
        wget \
        rsync \
        ca-certificates \
        unzip \
        zip \
        nano \
        vim \
        less \
        jq \
        libgcc \
        libstdc++ \
        krb5-libs \
        libintl \
        libssl1.1 \
        lttng-ust \
        tzdata \
        userspace-rcu \
        zlib \
        sudo \
        coreutils \
        sed \
        grep \
        which \
        ncdu \
        shadow \
        strace

    # Install man pages - package name varies between 3.12 and earlier versions
    if apk info man > /dev/null 2>&1; then
        apk add man man-pages
    else
        apk add mandoc man-pages
    fi

    PACKAGES_ALREADY_INSTALLED="true"
fi

# Create or update a non-root user to match UID/GID.
if id -u ${USERNAME} > /dev/null 2>&1; then
    # User exists, update if needed
    if [ "${USER_GID}" != "automatic" ] && [ "$USER_GID" != "$(id -G $USERNAME)" ]; then
        groupmod --gid $USER_GID $USERNAME
        usermod --gid $USER_GID $USERNAME
    fi
    if [ "${USER_UID}" != "automatic" ] && [ "$USER_UID" != "$(id -u $USERNAME)" ]; then
        usermod --uid $USER_UID $USERNAME
    fi
else
    # Create user
    if [ "${USER_GID}" = "automatic" ]; then
        groupadd $USERNAME
    else
        groupadd --gid $USER_GID $USERNAME
    fi
    if [ "${USER_UID}" = "automatic" ]; then
        useradd -s /bin/bash --gid $USERNAME -m $USERNAME
    else
        useradd -s /bin/bash -K MAIL_DIR=/dev/null --uid $USER_UID --gid $USERNAME -m $USERNAME
    fi
fi

# Add add sudo support for non-root user
if [ "${USERNAME}" != "root" ] && [ "${EXISTING_NON_ROOT_USER}" != "${USERNAME}" ]; then
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME
    chmod 0440 /etc/sudoers.d/$USERNAME
    EXISTING_NON_ROOT_USER="${USERNAME}"
fi

# ** Shell customization section **
if [ "${USERNAME}" = "root" ]; then
    USER_RC_PATH="/root"
else
    USER_RC_PATH="/home/${USERNAME}"
fi

# bashrc/zshrc snippet
RC_SNIPPET="$(cat << EOF
export USER=\$(whoami)

export PATH=\$PATH:\$HOME/.local/bin

if type code-insiders > /dev/null 2>&1 && ! type code > /dev/null 2>&1; then
    alias code=code-insiders
fi
EOF
)"

# code shim, it fallbacks to code-insiders if code is not available
cat << 'EOF' > /usr/local/bin/code
#!/bin/sh

get_in_path_except_current() {
  which -a "$1" | grep -v "$0" | head -1
}

code="$(get_in_path_except_current code)"

if [ -n "$code" ]; then
  exec "$code" "$@"
elif [ "$(command -v code-insiders)" ]; then
  exec code-insiders "$@"
else
  echo "code or code-insiders is not installed" >&2
  exit 127
fi
EOF
chmod +x /usr/local/bin/code

# Codespaces themes - partly inspired by https://github.com/ohmyzsh/ohmyzsh/blob/master/themes/robbyrussell.zsh-theme
CODESPACES_BASH="$(cat \
<<EOF
#!/usr/bin/env bash
prompt() {
    if [ "\$?" != "0" ]; then
        local arrow_color=\${bold_red}
    else
        local arrow_color=\${reset_color}
    fi
    if [ ! -z "\${GITHUB_USER}" ]; then
        local USERNAME="gh:@\${GITHUB_USER}"
    else
        local USERNAME="\$(whoami)"
    fi
    local cwd="\$(pwd | sed "s|^\${HOME}|~|")"
    PS1="\${green}\${USERNAME} \${arrow_color}➜\${reset_color} \${bold_blue}\${cwd}\${reset_color} \$(scm_prompt_info)\${white}$ \${reset_color}"
}
SCM_THEME_PROMPT_PREFIX="\${reset_color}\${cyan}(\${bold_red}"
SCM_THEME_PROMPT_SUFFIX="\${reset_color} "
SCM_THEME_PROMPT_DIRTY=" \${bold_yellow}✗\${reset_color}\${cyan})"
SCM_THEME_PROMPT_CLEAN="\${reset_color}\${cyan})"
SCM_GIT_SHOW_MINIMAL_INFO="true"
safe_append_prompt_command prompt
EOF
)"
CODESPACES_ZSH="$(cat \
<<EOF
prompt() {
    if [ ! -z "\${GITHUB_USER}" ]; then
        local USERNAME="gh:@\${GITHUB_USER}"
    else
        local USERNAME="\$(whoami)"
    fi
    PROMPT="%{\$fg[green]%}\${USERNAME} %(?:%{\$reset_color%}➜ :%{\$fg_bold[red]%}➜ )"
    PROMPT+='%{\$fg_bold[blue]%}%~%{\$reset_color%} \$(git_prompt_info)%{\$fg[white]%}$ %{\$reset_color%}'
}
ZSH_THEME_GIT_PROMPT_PREFIX="%{\$fg_bold[cyan]%}(%{\$fg_bold[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{\$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY=" %{\$fg_bold[yellow]%}✗%{\$fg_bold[cyan]%})"
ZSH_THEME_GIT_PROMPT_CLEAN="%{\$fg_bold[cyan]%})"
prompt
EOF
)"

# Adapted Oh My Zsh! install step to work with both "Oh Mys" rather than relying on an installer script
# See https://github.com/ohmyzsh/ohmyzsh/blob/master/tools/install.sh for offical script.
install-oh-my()
{
    local OH_MY=$1
    local OH_MY_INSTALL_DIR="${USER_RC_PATH}/.oh-my-${OH_MY}"
    local TEMPLATE="${OH_MY_INSTALL_DIR}/templates/$2"
    local OH_MY_GIT_URL=$3
    local USER_RC_FILE="${USER_RC_PATH}/.${OH_MY}rc"

    if [ -d "${OH_MY_INSTALL_DIR}" ] || [ "${INSTALL_OH_MYS}" != "true" ]; then
        return 0
    fi

    umask g-w,o-w
    mkdir -p ${OH_MY_INSTALL_DIR}
    git clone --depth=1 \
        -c core.eol=lf \
        -c core.autocrlf=false \
        -c fsck.zeroPaddedFilemode=ignore \
        -c fetch.fsck.zeroPaddedFilemode=ignore \
        -c receive.fsck.zeroPaddedFilemode=ignore \
        ${OH_MY_GIT_URL} ${OH_MY_INSTALL_DIR} 2>&1
    echo -e "$(cat "${TEMPLATE}")\nDISABLE_AUTO_UPDATE=true\nDISABLE_UPDATE_PROMPT=true" > ${USER_RC_FILE}
    if [ "${OH_MY}" = "bash" ]; then
        sed -i -e 's/OSH_THEME=.*/OSH_THEME="codespaces"/g' ${USER_RC_FILE}
        mkdir -p ${OH_MY_INSTALL_DIR}/custom/themes/codespaces
        echo "${CODESPACES_BASH}" > ${OH_MY_INSTALL_DIR}/custom/themes/codespaces/codespaces.theme.sh
    else
        sed -i -e 's/ZSH_THEME=.*/ZSH_THEME="codespaces"/g' ${USER_RC_FILE}
        mkdir -p ${OH_MY_INSTALL_DIR}/custom/themes
        echo "${CODESPACES_ZSH}" > ${OH_MY_INSTALL_DIR}/custom/themes/codespaces.zsh-theme
    fi
    # Shrink git while still enabling updates
    cd ${OH_MY_INSTALL_DIR}
    git repack -a -d -f --depth=1 --window=1

    if [ "${USERNAME}" != "root" ]; then
        cp -rf ${USER_RC_FILE} ${OH_MY_INSTALL_DIR} /root
        chown -R ${USERNAME}:${USERNAME} ${USER_RC_PATH}
    fi
}

if [ "${RC_SNIPPET_ALREADY_ADDED}" != "true" ]; then
    echo "${RC_SNIPPET}" >> /etc/bash.bashrc
    RC_SNIPPET_ALREADY_ADDED="true"
fi
install-oh-my bash bashrc.osh-template https://github.com/ohmybash/oh-my-bash

# Optionally install and configure zsh and Oh My Zsh!
if [ "${INSTALL_ZSH}" = "true" ]; then
    if ! type zsh > /dev/null 2>&1; then
        apk add zsh
    fi
    if [ "${ZSH_ALREADY_INSTALLED}" != "true" ]; then
        echo "${RC_SNIPPET}" >> /etc/zsh/zshrc
        ZSH_ALREADY_INSTALLED="true"
    fi
    install-oh-my zsh zshrc.zsh-template https://github.com/ohmyzsh/ohmyzsh
fi

# Write marker file
mkdir -p "$(dirname "${MARKER_FILE}")"
echo -e "\
    PACKAGES_ALREADY_INSTALLED=${PACKAGES_ALREADY_INSTALLED}\n\
    EXISTING_NON_ROOT_USER=${EXISTING_NON_ROOT_USER}\n\
    RC_SNIPPET_ALREADY_ADDED=${RC_SNIPPET_ALREADY_ADDED}\n\
    ZSH_ALREADY_INSTALLED=${ZSH_ALREADY_INSTALLED}" > "${MARKER_FILE}"

echo "Done!"
