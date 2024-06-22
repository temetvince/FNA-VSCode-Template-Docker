# Use an official Ubuntu as a parent image
FROM ubuntu:20.04

# Set environment variable to prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages including curl and tar
RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y \
    sudo \
    wget \
    curl \
    tar \
    git \
    git-lfs \
    xclip \
    software-properties-common \
    apt-transport-https \
    gnupg \
    ca-certificates \
    mono-complete \
    mesa-utils \
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    xorg \
    xvfb \
    libx11-dev \
    libxext-dev \
    libxrender-dev \
    libxrandr-dev \
    libgl1-mesa-dev \
    wine \
    wine32 \
    wine64 \
    winetricks \
    && rm -rf /var/lib/apt/lists/* \
    || { echo 'Failed to install necessary packages'; exit 1; }

# Install OpenGL
RUN apt-get update && apt-get install -y \
    libglu1-mesa-dev freeglut3-dev mesa-common-dev \
    || { echo 'Failed to install OpenGL packages'; exit 1; }

# Install .NET SDK
RUN wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && apt-get update && apt-get install -y dotnet-sdk-5.0 \
    || { echo 'Failed to install .NET SDK'; exit 1; }

# Install NuGet
RUN wget https://dist.nuget.org/win-x86-commandline/latest/nuget.exe -O /usr/local/bin/nuget.exe \
    && chmod +x /usr/local/bin/nuget.exe \
    || { echo 'Failed to install NuGet'; exit 1; }

# Reset the DEBIAN_FRONTEND variable
ENV DEBIAN_FRONTEND=dialog

# Set environment variables for OpenGL
ENV DISPLAY=:0
ENV LIBGL_ALWAYS_INDIRECT=1

# Set up a non-root user
RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo \
    || { echo 'Failed to set up non-root user'; exit 1; }
USER docker
WORKDIR /home/docker

# Set PATH to include .NET SDK tools
ENV PATH="${PATH}:/home/docker/.dotnet/tools"

# Clone the FNA-VSCode-Template repository
RUN git clone https://github.com/temetvince/FNA-VSCode-Template.git /home/docker/FNA-VSCode-Template \
    && echo 'Repository cloned successfully' \
    || (echo 'Failed to clone the repository'; exit 1)

# Set working directory to the cloned repository
WORKDIR /home/docker/FNA-VSCode-Template

# Make getFNA.sh and getNez.sh executable
RUN chmod +x getFNA.sh getNez.sh \
    && echo 'Scripts made executable' \
    || (echo 'Failed to make scripts executable'; exit 1)

# Set the new project name
ARG newProjectName=YourProjectName

# Run getFNA.sh script and check for errors
RUN printf "Y\nY\n${newProjectName}\n" | ./getFNA.sh; exit_code=$?; if [ $exit_code -ne 0 ]; then echo "./getFNA.sh failed with exit code $exit_code"; exit $exit_code; fi

# Build Nez project
RUN ./getNez.sh $newProjectName; exit_code=$?; if [ $exit_code -ne 0 ]; then echo "./getNez.sh failed with exit code $exit_code"; exit $exit_code; fi

# Set the working directory to the new project directory
WORKDIR /home/docker/FNA-VSCode-Template/$newProjectName

# Initialize Git LFS
RUN git lfs install \
    && echo 'Git LFS initialized successfully' \
    || (echo 'Failed to initialize Git LFS'; exit 1)

# Restore NuGet packages with detailed verbosity and capture the exit code
RUN mono /usr/local/bin/nuget.exe restore Nez/Nez.sln -Verbosity detailed; exit_code=$?; if [ $exit_code -ne 0 ]; then echo "nuget restore failed with exit code $exit_code"; exit $exit_code; fi

# Copy and run your application (replace this with your application setup)
COPY . .
CMD ["bash"]
