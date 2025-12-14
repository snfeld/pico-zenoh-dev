FROM ubuntu:22.04

# Umgebungsvariablen
ENV DEBIAN_FRONTEND=noninteractive
ENV PICO_SDK_PATH=/opt/pico-sdk
ENV ZENOH_PICO_PATH=/opt/zenoh-pico

# System-Updates und grundlegende Abhängigkeiten installieren
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    build-essential \
    cmake \
    gcc-arm-none-eabi \
    libnewlib-arm-none-eabi \
    libstdc++-arm-none-eabi-newlib \
    git \
    wget \
    curl \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    pkg-config \
    libusb-1.0-0-dev \
    libffi-dev \
    libssl-dev \
    clang \
    ninja-build \
    make \
    && rm -rf /var/lib/apt/lists/*

# Python-Abhängigkeiten installieren
RUN pip3 install \
    pyserial \
    cmake \
    pycryptodome \
    tqdm

# Raspberry Pi Pico SDK installieren
RUN git clone https://github.com/raspberrypi/pico-sdk.git ${PICO_SDK_PATH} && \
    cd ${PICO_SDK_PATH} && \
    git submodule update --init

# Zenoh-pico klonen (ohne sofort zu bauen)
RUN git clone https://github.com/eclipse-zenoh/zenoh-pico.git ${ZENOH_PICO_PATH} && \
    cd ${ZENOH_PICO_PATH} && \
    git submodule update --init --recursive

# Pico-Tools installieren
RUN git clone https://github.com/raspberrypi/picotool.git /opt/picotool && \
    cd /opt/picotool && \
    mkdir build && \
    cd build && \
    cmake .. -DPICO_SDK_PATH=${PICO_SDK_PATH} && \
    make -j$(nproc) && \
    cp picotool /usr/local/bin/

# Arbeitsverzeichnis erstellen
WORKDIR /workspace

# Umgebungsvariablen für die Shell exportieren
RUN echo 'export PICO_SDK_PATH=/opt/pico-sdk' >> /etc/bash.bashrc && \
    echo 'export ZENOH_PICO_PATH=/opt/zenoh-pico' >> /etc/bash.bashrc && \
    echo 'export PATH=/usr/local/bin:$PATH' >> /etc/bash.bashrc

# Standardbefehl
CMD ["/bin/bash"]
