FROM summerwind/actions-runner:latest AS builder

# install docker cli
RUN true \
 && echo "deb https://download.docker.com/linux/ubuntu focal stable" | sudo tee /etc/apt/sources.list.d/docker.list \
 && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list \
 && curl -sL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - \
 && curl -sL https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - \
 && sudo apt update -q \
 && sudo apt upgrade -q -y \
 && sudo apt install -q -y docker-ce-cli --no-install-recommends

# install aws cli
RUN cd /tmp \
 && curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip" \
 && unzip awscliv2.zip \
 && sudo ./aws/install \
 && rm -rf aws awscliv2.zip

# install golang
env PATH="$HOME/.gobrew/current/bin:$HOME/.gobrew/bin:$PATH"
RUN curl -sLk https://git.io/gobrew | sh - \
 && gobrew install 1.18

# install volta
env VOLTA_HOME="$HOME/.volta"
env PATH="$PATH:$VOLTA_HOME/bin"
RUN curl https://get.volta.sh | bash \
 && volta install node@16 \
 && volta install node@14 \
 && volta install yarn

# ecr login
RUN arch=$(test $(uname -m) = "aarch64" && echo arm64 || echo amd64) \
 && sudo curl -L -o /usr/bin/docker-credential-ecr-login https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/0.6.0/linux-${arch}/docker-credential-ecr-login \
 && sudo chmod +x /usr/bin/docker-credential-ecr-login \
 && mkdir -p $HOME/.docker \
 && echo '{"credsStore": "ecr-login"}' > $HOME/.docker/config.json

# update PATH
RUN sudo sed -i "/^PATH=/c\PATH=$PATH" /etc/environment


### builder + browser
FROM builder AS browser
RUN sudo apt install -q -y docker-ce-cli --no-install-recommends
