#!/bin/bash
set -eo  pipefail

install_base () {
    dnf -y install \
        @standard \
        git \
        make \
        NetworkManager \
        NetworkManager-tui \
        NetworkManager-wifi \
        tuned \
        vim-enhanced

    # enable tuned
    systemctl enable tuned.service
}

install_wm () {
    # Sway Supplemental COPR
    dnf -y copr enable ludwigd/sway-supplemental
    
    dnf -y install \
        brightnessctl \
        clipman \
        foot \
        gammastep \
        i3status \
        kanshi \
        pavucontrol \
        pipewire \
        pipewire-pulseaudio \
        playerctl \
        pulseaudio-utils \
        rofi-wayland \
        sway \
        swaybg \
        swaycaffeine \
        swayidle \
        swaylock \
        wev \
        xlsclients \
        yaws
}

setup_hwaccel () {
    local gpu=$1

    if [[ -z $gpu ]]; then
        echo "You have to specify whether your gpu is amd or intel"
        exit 1
    fi
    
    # RPMfusion
    dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

    # Install full ffmpeg and va drivers from RPMfusion
    local pkgs=( ffmpeg gstreamer1-plugin-libav libavcodec-freeworld )
    case $gpu in
        "intel")
            pkgs+=( libva-intel-driver intel-media-driver )
            ;;
        "amd")
            pkgs+=( mesa-va-drivers-freeworld mesa-vdpau-drivers-freeworld )
            ;;
        *)
            echo "$gpu not in {amd, intel}"
            exit 1
            ;;
    esac
    dnf -y install --best --allowerasing "${pkgs[@]}"
}

install_apps () {
    dnf -y install \
        aerc \
        android-file-transfer \
        borgbackup \
        chromium \
        emacs \
        firefox \
        gimp \
        htop \
        imv \
        inkscape \
        irssi \
        keepassxc \
        libreoffice \
        libreoffice-gtk3 \
        mpv \
        mupdf \
        podman \
        quodlibet \
        ranger \
        udiskie \
        virt-manager \
        xournalpp \
        xsane
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

install_fonts () {
    dnf -y install \
        dejavu-sans-fonts \
        dejavu-sans-mono-fonts \
        dejavu-serif-fonts \
        fontconfig \
        google-noto-emoji-color-fonts \
        google-noto-sans-cjk-ttc-fonts \
        jetbrains-mono-fonts-all \
        liberation-mono-fonts \
        liberation-sans-fonts \
        liberation-serif-fonts
}

install_cups () {
    dnf -y install \
        @printing \
        system-config-printer \
        --exclude PackageKit,PackageKit-glib,samba-client
}

install_texlive () {
    dnf -y install \
        aspell \
        aspell-de \
        aspell-en \
        hunspell \
        hunspell-de \
        ImageMagick \
        pandoc \
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

    # Who am I?
    ME=$(who am i | cut -f1 -d" ")
    
    # Clone the repository
    worktree=/home/$ME
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
    echo "install.sh cmd+"
    echo "    This script installs my setup for a Fedora Linux laptop."
    echo
    echo "Usage:"
    echo "  base                 - install base packages"
    echo "  wm                   - install wm packages"
    echo "  apps                 - install apps"
    echo "  fonts                - install additional fonts"
    echo "  hwaccel (amd|intel)  - install stuff for hw accel from RPMfusion"
    echo "  cups                 - install support for printing"
    echo "  tools                - install tools commonly needed for development"
    echo "  texlive              - install an opinionated selection of TeXlive packages"
    echo "  dotfiles             - get dotfiles"
}

main () {
    # if called w/o args
    if [[ -z "$1" ]]; then
        usage
        exit 1
    fi

    while [[ -n $1 ]]; do
        case $1 in
            "base")
                check_root
                install_base
                ;;
            "wm")
                check_root
                install_wm
                ;;
            "apps")
                check_root
                install_apps
                ;;
            "fonts")
                check_root
                install_fonts
                ;;
            "hwaccel")
                check_root
                setup_hwaccel $2
                shift
                ;;
            "cups")
                check_root
                install_cups
                ;;
            "tools")
                check_root
                install_tools
                ;;
            "texlive")
                check_root
                install_texlive
                ;;
            "dotfiles")
                get_dotfiles
                ;;
            *)
                echo "Unknown command: $1"
                ;;
        esac
        shift
    done
}

main "$@"
