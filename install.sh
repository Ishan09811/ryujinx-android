#!/data/data/com.termux/files/usr/bin/bash

RYU_URL="https://github.com/Ryujinx/release-channel-master/releases/download/1.1.1376/ryujinx-1.1.1376-linux_arm64.tar.gz"
RYU_ARCHIVE="ryujinx-1.1.1376-linux_arm64.tar.gz"

err() {
    echo -e "\033[1;31mError: $@\033[0m" >&2
    exit 1
}

install_deps() {
    yes | pkg up
    pkg i x11-repo -y
    pkg i -y \
        pulseaudio \
        termux-x11-nightly \
        proot-distro wget || \
        err "Failed to install dependencies"
    proot-distro install ubuntu
}

download_ryujinx() {
    if [ -d publish ]; then
        echo -e "\033[1;33mUsing old Ryujinx installation\n\033[0m"
    else
        wget "$RYU_URL" -O "$RYU_ARCHIVE" || err "Failed to download Ryujinx"
        tar -xzf "$RYU_ARCHIVE" && rm "$RYU_ARCHIVE" || err "Failed to extract Ryujinx"
    fi
}

setup_ryujinx_menu() {
    wget https://raw.githubusercontent.com/Ishan09811/RyujinxMobile/main/ryujinx_menu.zip -O /data/data/com.termux/files/home/ryujinx_menu.zip
    unzip /data/data/com.termux/files/home/ryujinx_menu.zip -d /data/data/com.termux/files/home/ryujinx_menu
    echo "alias Ryujinx='/data/data/com.termux/files/home/ryujinx_menu/ryujinx.sh'" >> ~/.bashrc
    source ~/.bashrc
    chmod +x /data/data/com.termux/files/home/ryujinx_menu/ryujinx.sh
}


run_proot() {
    proot-distro login --termux-home --isolated ubuntu -- "$@" || err "Proot command failed: $@"
}

install_deps_proot() {
    run_proot apt update -y && \
    run_proot apt upgrade -y && \
    run_proot apt install -y libicu-dev libice6 libvulkan-dev libx11-dev xorg libsdl2-2.0-0 || \
    err "Failed to install dependencies in Ubuntu"
}

install_mesa() {
    run_proot apt update -y && \
    run_proot apt install -y software-properties-common && \
    run_proot add-apt-repository -y "ppa:mastag/mesa-turnip-kgsl" && \
    run_proot apt update -y && \
    run_proot apt dist-upgrade -y || \
    err "Failed to install Mesa"
}

install_ryu() {
    cat > $HOME/.profile <<EOF
export DISPLAY=:0
export DOTNET_GCHeapHardLimit=1C0000000
export MESA_LOADER_DRIVER_OVERRIDE=zink
export TU_DEBUG=noconform
EOF
    cat > $PREFIX/bin/ryujinx <<EOF
#!/data/data/com.termux/files/usr/bin/bash
termux-x11 :0 &>/dev/null & sleep 1
proot-distro login --shared-tmp --isolated --bind /sdcard --termux-home ubuntu -- /root/publish/Ryujinx
# kill x11
pkill -9 "app_process"
EOF
    chmod +x $PREFIX/bin/ryujinx
}

main() {
    install_deps
    download_ryujinx
    setup_ryujinx_menu
    install_deps_proot
    install_mesa
    install_ryu
    echo "Installation complete! You can now run Ryujinx by typing 'Ryujinx'."
}

main
