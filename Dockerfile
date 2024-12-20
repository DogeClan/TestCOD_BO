# Use a lightweight base image
FROM debian:latest

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:99

# Update and install required dependencies
RUN apt-get update && apt-get install -y \
    dolphin-emu \
    unzip \
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
    libmediainfo0v5 \
    libpcrecpp0v5 \
    libzen0v5 \
    --no-install-recommends && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a directory for games
RUN mkdir -p /games

WORKDIR /games

# Download the game files
RUN wget -q https://github.com/DogeClan/TestCOD_BO/releases/download/LOZ/Legend.of.Zelda.The.-.The.Wind.Waker.USA.1.zip && \
    unzip -q Legend.of.Zelda.The.-.The.Wind.Waker.USA.1.zip && \
    rm Legend.of.Zelda.The.-.The.Wind.Waker.USA.1.zip

RUN ln -s /usr/games/dolphin-emu /usr/local/bin/dolphin-emu

# Create the directory for noVNC
RUN mkdir -p /usr/share/novnc && \
    wget -qO- https://github.com/novnc/noVNC/archive/refs/tags/v1.5.0.tar.gz | tar xz --strip-components=1 -C /usr/share/novnc && \
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
         '# Launch Dolphin Emulator with the specified game files\n' \
         'dolphin-emu "/games/Legend of Zelda, The - The Wind Waker (USA).rvz"\n' \
         'wait' > /usr/local/bin/start-dolphin && \
    chmod +x /usr/local/bin/start-dolphin

# Set the noVNC HTML directory
RUN ln -s /usr/share/novnc/vnc.html /usr/share/novnc/index.html

# Expose VNC and noVNC ports
EXPOSE 5900 6080

# Set the entrypoint to run Dolphin Emulator with noVNC
ENTRYPOINT ["/usr/local/bin/start-dolphin"]
