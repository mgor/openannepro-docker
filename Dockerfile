
# docker build -t ap2 .
#
# docker run --privileged -h ap2 --rm -it -v ${PWD}:/host --user $(id -u) -w /home/dev ap2 bash

FROM debian:bullseye

MAINTAINER Mikael Göransson <github@mgor.se>

ARG model=c18

RUN echo "Bulding for AnnePro2 ${model}"

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
        build-essential \
        less \
        git \
        sudo \
        pkg-config \
        libusb-1.0-0-dev \
        cargo \
        gcc-arm-none-eabi \
        libstdc++-arm-none-eabi-newlib \
        ca-certificates

RUN adduser --disabled-password --gecos '' dev && \
    adduser dev sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER dev

RUN cd ~/ && \
    git clone https://github.com/OpenAnnePro/AnnePro2-Tools.git && \
    cd ~/AnnePro2-Tools && \
    cargo build --release

RUN cd ~/ && \
    git clone https://github.com/OpenAnnePro/qmk_firmware.git annepro-qmk --recursive --depth 1 && \
    cd ~/annepro-qmk && \
    make annepro2/${model}
RUN cd ~/ && \
    git clone https://github.com/OpenAnnePro/AnnePro2-Shine.git --recursive --depth 1 && \
    cd ~/AnnePro2-Shine && make MODEL=${model}

RUN cp /home/dev/AnnePro2-Tools/target/release/annepro2_tools /home/dev/

RUN cp /home/dev/annepro-qmk/.build/annepro2_c18_default.bin /home/dev/

RUN cp /home/dev/AnnePro2-Shine/build/annepro2-shine.bin /home/dev/

ENV TZ /usr/share/zoneinfo/Europe/Stockholm
