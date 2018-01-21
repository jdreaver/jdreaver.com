FROM ubuntu:16.04

# Install apt dependencies
RUN \
  apt-get update && \
  apt-get install --assume-yes \
    build-essential \
    curl \
    git \
    libelf-dev \
    libgmp3-dev \
    libtinfo-dev \
    moreutils \
    python-pip \
    wget \
    zlib1g-dev && \
  rm -rf /var/lib/apt/lists/*

# Install stack
ENV STACK_VERSION 1.6.1
RUN \
  curl -L https://github.com/commercialhaskell/stack/releases/download/v$STACK_VERSION/stack-$STACK_VERSION-linux-x86_64.tar.gz | tar -xzv -C /tmp && \
  mv /tmp/stack-$STACK_VERSION-linux-x86_64/stack /usr/local/bin/stack && \
  rm -rf /tmp/*

# Install awscli
RUN pip install awscli==1.11.117

# Use en_US.UTF-8 locale to fix decoding errors. It isn't here by default so we
# use locale-gen.
RUN \
  apt-get update && \
  apt-get install -y \
    locales && \
  rm -rf /var/lib/apt/lists/* && \
  locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
