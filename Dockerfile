FROM ubuntu:rolling

LABEL maintainer="github@mgor.se"

ARG model=c18

ENV USER=qmk \
    TZ=/usr/share/zoneinfo/Europe/Stockholm

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
        less \
        git \
        sudo \
        pkg-config \
        libusb-1.0-0-dev \
        cargo \
        gcc-10 \
        g++-10 \
        gcc-arm-none-eabi \
        libstdc++-arm-none-eabi-newlib \
        ca-certificates && \
    echo "set disable_coredump false" >> /etc/sudo.conf

RUN sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 10 && \
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 10 && \
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 9 && \
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 && \
    sudo update-alternatives --auto gcc && \
    sudo update-alternatives --auto g++

RUN adduser --disabled-password --gecos '' ${USER} && \
    adduser ${USER} sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    echo 'export PATH=~/.local/bin:$PATH' >> /home/qmk/.bashrc

USER ${USER}

RUN mkdir -p ~/.local/bin && \
    mkdir ~/src

RUN cd ~/src && \
    git clone https://github.com/OpenAnnePro/qmk_firmware.git annepro-qmk --recursive --depth 1 && \
    cd annepro-qmk && \
    bash util/qmk_install.sh && \
    make git-submodule && \
    make annepro2/${model} && \
    cp .build/annepro2_${model}_default.bin ~/

RUN cd ~/src && \
    git clone https://github.com/OpenAnnePro/AnnePro2-Tools.git annepro2-tools && \
    cd annepro2-tools && \
    cargo build --release && \
    cp target/release/annepro2_tools ~/.local/bin

RUN cd ~/src && \
    git clone https://github.com/OpenAnnePro/AnnePro2-Shine.git --recursive --depth 1 annepro2-shine && \
    cd annepro2-shine && \
    make MODEL=${model} && \
    cp build/annepro2-shine.bin ~/
