#!/bin/bash
set -eo  pipefail

install_base () {
    dnf -y install \
        @base-graphical \
        @fonts \
        @hardware-support \
        @networkmanager-submodules \
        @standard \
        git \
        make \
        pipewire \
        pipewire-pulseaudio \
        tuned \
        udisks2 \
        vim-default-editor \
        --allowerasing \
        --setopt install_weak_deps=False

    # enable tuned
    systemctl enable tuned.service

    # Disable rhgb
    grubby --remove-args="rhgb" --update-kernel=ALL
}

install_sway () {
    # Repo for my Sway config and tools, see
    #   https://copr.fedorainfracloud.org/coprs/ludwigd/sway-supplemental/
    # for details.
    dnf -y copr enable ludwigd/sway-supplemental
    
    dnf -y install \
        sway \
        sway-config-ludwigd \
        xdg-desktop-portal-wlr \
        xorg-x11-server-Xwayland \
        --setopt install_weak_deps=False
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
        keepassxc \
        mc \
        nm-connection-editor-desktop \
        pandoc \
        ranger \
        zathura \
        zathura-bash-completion \
        zathura-pdf-poppler \
        --setopt install_weak_deps=False
}

install_virtualization () {
    # we want weak deps here
    dnf -y install \
        podman \
        podman-compose \
        podman-machine \
        virt-manager
}

install_multimedia () {
    dnf -y install \
        ffmpeg-free \
        gstreamer1-plugins-bad-free \
        mpv \
        pavucontrol \
        strawberry \
        yt-dlp \
        --setopt install_weak_deps=False
}

install_printing () {
    # just a minimal CUPS installtion
    dnf -y install \
        cups \
        cups-filters \
        cups-filters-driverless \
        sane-backends-drivers-scanners \
        xsane \
        --setopt install_weak_deps=False
}

install_vpn () {
    dnf -y install \
        NetworkManager-openvpn \
        NetworkManager-openvpn-gnome \
        openresolv \
        wireguard-tools \
        --setopt install_weak_deps=False
}

install_python-development () {
    dnf -y install \
        python3 \
        python3-lsp-server \
        python3-pip \
        python3-virtualenv \
        --setopt install_weak_deps=False
}

install_rust-development () {
    dnf -y install \
        cargo \
        rust \
        rustfmt \
        rust-analyzer \
        rust-src \
        --setopt install_weak_deps=False
}

install_c-development () {
    dnf -y install \
        autoconf \
        automake \
        bison \
        cmake \
        ctags \
        flex \
        gcc \
        gcc-c++ \
        gdb \
        glibc-devel \
        --setopt install_weak_deps=False
}

install_shell-development () {
    # not optimal, but does not fit anywhere else
    dnf -y install \
        ShellCheck \
        --setopt install_weak_deps=False
}

install_rpm-development () {
    dnf -y install \
        patch \
        rpmdevtools \
        tito \
        --setopt install_weak_deps=False
}

get_dotfiles () {
    # Check dependencies
    if [[ ! $(which git sway-config-ludwigd) ]]; then
        exit 1
    fi

    # Clone the repository
    worktree="$HOME"
    gitdir="$worktree"/.dotfiles
    git clone --bare https://github.com/ludwigd/dotfiles "$gitdir"

    # Manage dotfiles the openSUSE way
    # See: https://news.opensuse.org/2020/03/27/Manage-dotfiles-with-Git/
    pushd .
    cd "$HOME"
    git --git-dir="$gitdir" --work-tree="$worktree" checkout -f
    popd
}

install_pattern-home () {
    install_base
    install_sway
    install_apps
    install_multimedia
    install_printing
    install_virtualization
    install_vpn
    install_python-development
    install_rust-development
    install_c-development
    install_rpm-development
    install_shell-development
}

install_pattern-work () {
    install_base
    install_sway
    install_apps
    install_multimedia
    install_virtualization
    install_vpn
    install_python-development
    install_shell-development
}

check_root () {
    if [ $EUID -ne 0 ]; then
        echo "You must be root to install software."
        exit 1
    fi
}

usage () {
    echo "${0##*/} <group|pattern>"
    echo "    A nice way to setup my machines."
    echo
    echo "Groups:"
    echo "  base             - install base packages"
    echo "  sway             - a preconfigured tiling window manager"
    echo "  apps             - install apps"
    echo "  multimedia       - play audio and video files"
    echo "  printing         - print and scan your documents"
    echo "  virtualization   - run virtual machines (and containers)"
    echo "  vpn              - connect to OpenVPN or Wireguard networks"
    echo "  dotfiles         - get ludwigd's dotfiles"
    echo "  python-dev       - Fedora 🫶 Python"
    echo "  rust-dev         - the rust toolchain"
    echo "  c-dev            - c++ < c"
    echo "  rpm-dev          - build rpm packages"
    echo "  sh-dev           - tools for (better) shell scripting"
    echo
    echo "Patterns:"
    echo "  home             - default setup for home computing"
    echo "  work             - default setup for work"
}

main () {
    local cmd=$1

    if [[ -z "$cmd" ]]; then
        usage
        exit 1
    elif [[ $cmd == "base" ]]; then
        check_root
        install_base
    elif [[ $cmd == "sway" ]]; then
        check_root
        install_sway
    elif [[ $cmd == "apps" ]]; then
        check_root
        install_apps
    elif [[ $cmd == "multimedia" ]]; then
        check_root
        install_multimedia
    elif [[ $cmd == "printing" ]]; then
        check_root
        install_printing
    elif [[ $cmd == "virtualization" ]]; then
        check_root
        install_virtualization
    elif [[ $cmd == "vpn" ]]; then
        check_root
        install_vpn
    elif [[ $cmd == "dotfiles" ]]; then
        if [[ $EUID -eq 0 && $2 != "--force-root" ]]; then
            echo "You should not run this as root. Append --force-root to do it anyway."
            exit 1
        fi
        get_dotfiles
    elif [[ $cmd == "python-dev" ]]; then
        check_root
        install_python-development
    elif [[ $cmd == "rust-dev" ]]; then
        check_root
        install_rust-development
    elif [[ $cmd == "c-dev" ]]; then
        check_root
        install_c-development
    elif [[ $cmd == "rpm-dev" ]]; then
        check_root
        install_rpm-development
    elif [[ $cmd == "sh-dev" ]]; then
        check_root
        install_shell-development
    elif [[ $cmd = "home" ]]; then
        check_root
        install_pattern-home
    elif [[ $cmd == "work" ]]; then
        check_root
        install_pattern-work
    else
        echo "Unknown group or pattern: $cmd"
        exit 1
    fi
}

main "$@"
