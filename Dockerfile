# ----------------------------------------------------------------------
#   Dockerfile – Build‑Umgebung für Raspberry Pi Pico + Zenoh‑pico
# ----------------------------------------------------------------------
FROM ubuntu:22.04

# --------------------------------------------------------------
#   System‑Pakete (apt)
# --------------------------------------------------------------
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        ninja-build \
        git \
        wget \
        unzip \
        python3 \
        python3-pip \
        libusb-1.0-0-dev \
        gcc-arm-none-eabi \
        binutils-arm-none-eabi \
        libnewlib-arm-none-eabi \
        libstdc++-arm-none-eabi-newlib \
        && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------------
#   Benutzer & Arbeitsverzeichnis
# --------------------------------------------------------------
ARG USERNAME=picobuild
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    mkdir -p /workspace && chown $USERNAME:$USERNAME /workspace

WORKDIR /workspace

# --------------------------------------------------------------
#   Pico SDK
# --------------------------------------------------------------
ENV PICO_SDK_VERSION=2.0.0
RUN git clone --depth 1 -b $PICO_SDK_VERSION \
        https://github.com/raspberrypi/pico-sdk.git && \
    cd pico-sdk && git submodule update --init

ENV PICO_SDK_PATH=/workspace/pico-sdk

# --------------------------------------------------------------
#   Zenoh‑pico (C API)
# --------------------------------------------------------------
ENV ZENOH_PICO_VERSION=0.11.0.3
RUN git clone --depth 1 -b $ZENOH_PICO_VERSION \
        https://github.com/eclipse-zenoh/zenoh-pico.git && \
    cd zenoh-pico && \
    # Zenoh‑pico stellt ein CMake‑Projekt bereit, das wir später einbinden
    true

# --------------------------------------------------------------
#   pico‑prog (Upload‑Tool)
# --------------------------------------------------------------
RUN wget -qO- https://github.com/raspberrypi/pico-tools/releases/latest/download/pico-tools-linux.zip \
        | bsdtar -xf- -C /usr/local/bin && \
    chmod +x /usr/local/bin/pico* && \
    # sysfs‑Zugriff für das USB‑Device (nur für das Flash‑Tool nötig)
    echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"2e8a\", MODE=\"0666\", GROUP=\"plugdev\"" \
        > /etc/udev/rules.d/99-pico.rules && \
    udevadm control --reload-rules && \
    udevadm trigger

# --------------------------------------------------------------
#   CMake‑Toolchain‑File für RP2040
# --------------------------------------------------------------
ENV PICO_TOOLCHAIN_FILE=$PICO_SDK_PATH/external/pico_sdk_import.cmake

# --------------------------------------------------------------
#   Entrypoint (optional)
# --------------------------------------------------------------
# Der Container wird im interaktiven Modus gestartet, daher kein
# festes ENTRYPOINT nötig – wir benutzen einfach `bash`.
CMD ["bash"]
