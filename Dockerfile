# Use a lightweight base image
FROM debian:latest

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:99

# Update and install required dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    gnupg \
    wget \
    xvfb \
    x11vnc \
    novnc \
    websockify \
    curl \
    python3 \
    python3-pip \
    sudo \
    --no-install-recommends && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add the Dolphin Emulator PPA manually with updated method for PGP key
RUN wget -qO - https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x6A6D97523F50ABC2 | gpg --dearmor -o /usr/share/keyrings/dolphin-emu-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/dolphin-emu-archive-keyring.gpg] http://ppa.launchpad.net/cobalt2727/dolphin-emu/ubuntu focal main" > /etc/apt/sources.list.d/dolphin-emu.list && \
    apt-get update && \
    apt-get install -y dolphin-emu && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create the directory for noVNC
RUN mkdir -p /usr/share/novnc && \
    wget -qO- https://github.com/novnc/noVNC/archive/refs/heads/main.tar.gz | tar xz --strip-components=1 -C /usr/share/novnc && \
    ln -s /usr/share/novnc/utils/websockify /usr/local/bin/websockify

# Create a start script for Dolphin Emulator with XVFB and noVNC
RUN mkdir -p /usr/local/bin && \
    echo '#!/bin/bash\n' \
         '# Start Xvfb for a virtual display\n' \
         'Xvfb :99 -screen 0 1024x768x24 &\n' \
         '# Start x11vnc to expose the virtual display\n' \
         'x11vnc -forever -nopw -shared -rfbport 5900 -display :99 &\n' \
         '# Start websockify to provide web access to the VNC server\n' \
         'websockify --web=/usr/share/novnc 6080 localhost:5900 &\n' \
         '# Launch Dolphin Emulator headlessly\n' \
         'dolphin-emu --exec="$@"\n' \
         'wait' > /usr/local/bin/start-dolphin && \
    chmod +x /usr/local/bin/start-dolphin

# Set the noVNC HTML directory
RUN ln -s /usr/share/novnc/vnc.html /usr/share/novnc/index.html

# Expose VNC and noVNC ports
EXPOSE 5900 6080

# Set the entrypoint to run Dolphin Emulator with noVNC
ENTRYPOINT ["/usr/local/bin/start-dolphin"]
