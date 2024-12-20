#!/bin/bash
set -eo  pipefail

install_base () {
    dnf -y install \
        @standard \
        git \
        make \
        tuned \
        vim-enhanced \
        --exclude bash-color-prompt,default-editor \
        --setopt install_weak_deps=False

    # enable tuned
    systemctl enable tuned.service
}

install_wm () {
    # Sway Supplemental COPR
    dnf -y copr enable ludwigd/sway-supplemental
    
    dnf -y install \
        bluez \
        brightnessctl \
        clipman \
        foot \
        gammastep \
        grim \
        i3status \
        mesa-dri-drivers \
        mesa-va-drivers \
        NetworkManager-wifi \
        pavucontrol \
        pipewire \
        pipewire-pulseaudio \
        pulseaudio-utils \
        rofi-wayland \
        sway \
        sway-systemd \
        swaycaffeine \
        swayidle \
        swaylock \
        yaws \
        --setopt install_weak_deps=False
}

install_apps () {
    dnf -y install \
        aerc \
        android-file-transfer \
        borgbackup \
        chromium \
        emacs \
        ffmpeg-free \
        firefox \
        gimp \
        htop \
        imv \
        irssi \
        keepassxc \
        mpv \
        pandoc \
        qt5-qtwayland \
        ranger \
        sane-backends-drivers-scanners \
        udiskie \
        xsane \
        yt-dlp \
        --setopt install_weak_deps=False

    # we want weak deps here
    dnf -y install \
        podman \
        virt-manager
}

install_fonts () {
    dnf -y install \
        dejavu-sans-fonts \
        dejavu-sans-mono-fonts \
        dejavu-serif-fonts \
        fontconfig \
        google-noto-color-emoji-fonts \
        jetbrains-mono-fonts-all \
        liberation-mono-fonts \
        liberation-sans-fonts \
        liberation-serif-fonts
}

fix_missing_codecs () {
    # enable rpmfusion
    dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

    # replace limited drivers and codecs
    dnf -y install --best --allowerasing \
        ffmpeg \
        libavcodec-freeworld \
        mesa-va-drivers-freeworld
}

install_cups () {
    dnf -y install \
        @printing \
        --exclude PackageKit,PackageKit-glib,samba-client
}

install_tools () {
    dnf -y install \
        android-tools \
        autoconf \
        automake \
        binutils \
        bison \
        cargo \
        cmake \
        ctags \
        flex \
        gcc \
        gcc-c++ \
        gdb \
        glibc-devel \
        java-latest-openjdk \
        java-latest-openjdk-devel \
        javacc \
        patch \
        patchutils \
        python3 \
        python3-pip \
        python3-virtualenv \
        rust \
        strace \
        zstd

    # link android udev rules
    ln -s /usr/share/doc/android-tools/51-android.rules \
       /etc/udev/rules.d/51-android.rules
}

install_texlive () {
    dnf -y install \
        aspell \
        aspell-de \
        aspell-en \
        hunspell \
        hunspell-de \
        ImageMagick \
        texlive-collection-basic \
        texlive-collection-bibtexextra \
        texlive-collection-binextra \
        texlive-collection-context \
        texlive-collection-fontsextra \
        texlive-collection-fontsrecommended \
        texlive-collection-fontutils \
        texlive-collection-formatsextra \
        texlive-collection-langenglish \
        texlive-collection-langgerman \
        texlive-collection-latex \
        texlive-collection-latexextra \
        texlive-collection-latexrecommended \
        texlive-collection-luatex \
        texlive-collection-mathscience \
        texlive-collection-metapost \
        texlive-collection-pictures \
        texlive-collection-plaingeneric \
        texlive-collection-pstricks \
        texlive-collection-publishers \
        texlive-collection-xetex \
        --exclude evince
}

get_dotfiles () {
    # Check dependencies
    if [[ ! $(which git) ]]; then
        exit 1
    fi

    # Clone the repository
    worktree=$HOME
    gitdir=$worktree/.dotfiles
    git clone --bare https://github.com/ludwigd/dotfiles $gitdir

    # Manage dotfiles the openSUSE way
    # See: https://news.opensuse.org/2020/03/27/Manage-dotfiles-with-Git/
    pushd .
    cd $HOME
    git --git-dir=$gitdir --work-tree=$worktree checkout -f
    popd
}

check_root () {
    if [ $EUID -ne 0 ]; then
        echo "You must be root to install software."
        exit 1
    fi
}

usage () {
    echo "install.sh <cmd>"
    echo "    This script installs my setup for a Fedora Linux laptop."
    echo
    echo "Commands:"
    echo "  base             - install base packages"
    echo "  wm               - install wm packages"
    echo "  apps             - install apps"
    echo "  fonts            - install additional fonts"
    echo "  codecs           - install ffmpeg and mesa drivers from rpmfusion"
    echo "  cups             - install support for printing"
    echo "  tools            - install tools commonly needed for development"
    echo "  texlive          - install an opinionated selection of TeXlive packages"
    echo "  dotfiles         - get dotfiles"
}

main () {
    local cmd=$1

    if [[ -z "$cmd" ]]; then
        usage
        exit 1
    elif [[ $cmd == "base" ]]; then
        check_root
        install_base
    elif [[ $cmd == "wm" ]]; then
        check_root
        install_wm
    elif [[ $cmd == "apps" ]]; then
        check_root
        install_apps
    elif [[ $cmd == "fonts" ]]; then
        check_root
        install_fonts
    elif [[ $cmd == "codecs" ]]; then
        check_root
        fix_missing_codecs
    elif [[ $cmd == "cups" ]]; then
        check_root
        install_cups
    elif [[ $cmd == "tools" ]]; then
        check_root
        install_tools
    elif [[ $cmd == "texlive" ]]; then
        check_root
        install_texlive
    elif [[ $cmd == "dotfiles" ]]; then
        if [[ $EUID -eq 0 && $2 != "--force-root" ]]; then
            echo "You should not run this as root. Append --force-root to do it anyway."
            exit 1
        fi
        get_dotfiles
    else
        echo "Unknown command: $cmd"
        exit 1
    fi
}

main "$@"
