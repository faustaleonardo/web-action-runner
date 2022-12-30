# syntax=docker/dockerfile:1.4

# golang fetcher
FROM ghcr.io/actions/actions-runner-controller/actions-runner:ubuntu-22.04 AS golang
ARG GO_VERSION=1.19.4
RUN arch=$(test $(uname -m) = "aarch64" && echo arm64 || echo amd64) \
 && curl -sL https://go.dev/dl/go${GO_VERSION}.linux-${arch}.tar.gz | sudo tar -xzC /usr/local

# volta fetcher
FROM ghcr.io/actions/actions-runner-controller/actions-runner:ubuntu-22.04 AS volta
ARG VOLTA_VERSION=1.1.0
ENV VOLTA_HOME="$HOME/.volta"
ENV PATH="$PATH:$VOLTA_HOME/bin"
RUN volta_bin=${VOLTA_HOME}/bin \
 && mkdir -p ${volta_bin} \
 && volta_name=$(test $(uname -m) = "aarch64" && echo 'linux-arm64' || echo 'linux') \
 && curl -sL https://github.com/abihf/volta-release/releases/download/v${VOLTA_VERSION}/volta-${VOLTA_VERSION}-${volta_name}.tar.gz | tar -xzC ${volta_bin} \
 && chmod +x ${volta_bin}/* \
 && volta install node@18 \
 && volta install node@16 \
 && volta install yarn@1

# ecr docker credentials fetcher
FROM ghcr.io/actions/actions-runner-controller/actions-runner:ubuntu-22.04 AS ecrlogin
ARG DCEL_VERSION=0.6.0
RUN arch=$(test $(uname -m) = "aarch64" && echo arm64 || echo amd64) \
 && sudo curl -L -o /usr/bin/docker-credential-ecr-login https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/${DCEL_VERSION}/linux-${arch}/docker-credential-ecr-login \
 && sudo chmod +x /usr/bin/docker-credential-ecr-login 

# docker buildx fetcher
FROM ghcr.io/actions/actions-runner-controller/actions-runner:ubuntu-22.04 AS buildx
ARG BUILDX_VERSION=0.9.1
RUN arch=$(test $(uname -m) = "aarch64" && echo arm64 || echo amd64) \
 && sudo mkdir -p /usr/local/lib/docker/cli-plugins \
 && sudo curl -L -o /usr/local/lib/docker/cli-plugins/docker-buildx https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-${arch} \
 && sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx 


# ================================================================================

FROM ghcr.io/actions/actions-runner-controller/actions-runner:ubuntu-22.04 AS builder
# install docker cli
RUN true \
 && echo "deb https://download.docker.com/linux/ubuntu jammy stable" | sudo tee /etc/apt/sources.list.d/docker.list \
 && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list \
 && curl -sL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - \
 && curl -sL https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - \
 && sudo apt update -q \
 && sudo apt upgrade -q -y \
 && sudo apt install -q -y zstd --no-install-recommends

# install aws cli
RUN cd /tmp \
 && curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip" \
 && unzip -q awscliv2.zip \
 && sudo ./aws/install \
 && rm -rf aws awscliv2.zip

# ecr login
COPY --link --from=ecrlogin /usr/bin/docker-credential-ecr-login /usr/bin/docker-credential-ecr-login
RUN mkdir -p $HOME/.docker \
 && echo '{"credsStore": "ecr-login"}' > $HOME/.docker/config.json

# docker buildx
COPY --link --from=buildx /usr/local/lib/docker/cli-plugins/docker-buildx /usr/local/lib/docker/cli-plugins/docker-buildx


# install golang
ENV PATH="$PATH:/usr/local/go/bin"
COPY --link --from=golang /usr/local/go /usr/local/go

# install volta
ENV VOLTA_HOME="$HOME/.volta"
ENV PATH="$PATH:$VOLTA_HOME/bin"
COPY --link --from=volta $VOLTA_HOME $VOLTA_HOME

# update PATH
RUN sudo sed -i "/^PATH=/c\PATH=$PATH" /etc/environment

# --------------------------

### builder + browser
FROM builder AS browser
RUN sudo apt install -q -y google-chrome-stable --no-install-recommends
