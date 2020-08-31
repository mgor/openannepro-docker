FROM gcc:10.2

LABEL maintainer="github@mgor.se"

ARG model=c18

ENV USER=qmk \
    TZ=/usr/share/zoneinfo/Europe/Stockholm

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq \
        less \
        git \
        sudo \
        pkg-config \
        libusb-1.0-0-dev \
        ca-certificates \
        avr-libc \
        binutils-avr \
        clang-format \
        dfu-programmer \
        dfu-util \
        diffutils \
        gcc-avr \
        avrdude \
        libusb-dev \
        python3 \
        python3-pip \
        unzip \
        wget \
        zip

RUN wget -qO- https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2 | tar -xj -C /opt

RUN wget https://www.obdev.at/downloads/vusb/bootloadHID.2012-12-08.tar.gz -O - | tar -xz -C /tmp && \
    cd /tmp/bootloadHID.2012-12-08/commandline/ && \
    make && \
    cp bootloadHID /usr/local/bin && \
    type bootloadHID

RUN echo "set disable_coredump false" >> /etc/sudo.conf && \
    adduser --disabled-password --gecos '' ${USER} && \
    adduser ${USER} sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    echo 'export PATH=~/.local/bin:$PATH' >> /home/qmk/.bashrc

USER ${USER}

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile=default

ENV PATH=$PATH:/home/qmk/.cargo/bin:/opt/gcc-arm-none-eabi-9-2019-q4-major/bin

RUN mkdir -p ~/.local/bin && \
    mkdir ~/src

RUN cd ~/src && \
    git clone https://github.com/OpenAnnePro/qmk_firmware.git annepro-qmk --recursive --depth 1 && \
    cd annepro-qmk && \
    pip3 install --user -r requirements.txt && \ 
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
    export PORT_IGNORE_GCC_VERSION_CHECK=true && \
    make MODEL=${model} && \
    cp build/annepro2-shine.bin ~/
