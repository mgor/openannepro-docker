FROM gcc:10.2

LABEL maintainer="github@mgor.se"

ARG model=c18

ENV USER=qmk \
    TZ=/usr/share/zoneinfo/Europe/Stockholm

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq \
        less \
        git \
        sudo \
        pkg-config \
        libusb-1.0-0-dev \
        gcc-arm-none-eabi \
        libstdc++-arm-none-eabi-newlib \
        ca-certificates

RUN echo "set disable_coredump false" >> /etc/sudo.conf

RUN adduser --disabled-password --gecos '' ${USER} && \
    adduser ${USER} sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    echo 'export PATH=~/.local/bin:$PATH' >> /home/qmk/.bashrc

USER ${USER}

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile=default

ENV PATH=$PATH:/home/qmk/.cargo/bin

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
    rm -rf Cargo.lock && \
    cargo build --release && \
    cp target/release/annepro2_tools ~/.local/bin

RUN cd ~/src && \
    git clone https://github.com/OpenAnnePro/AnnePro2-Shine.git --recursive --depth 1 annepro2-shine && \
    cd annepro2-shine && \
    make MODEL=${model} && \
    cp build/annepro2-shine.bin ~/
