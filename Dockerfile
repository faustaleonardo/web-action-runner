FROM summerwind/actions-runner:latest

# install buildah and google-chrome
RUN . /etc/os-release \
 && echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/libcontainers.list \
 && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list \
 && curl -sL "https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key" | sudo apt-key add - \
 && curl -sL https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - \
 && sudo apt update -q \
 && sudo apt upgrade -q -y \
 && sudo apt install -q -y buildah google-chrome-stable bison --no-install-recommends

# install aws cli
RUN cd /tmp \
 && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip" -o "awscliv2.zip" \
 && unzip awscliv2.zip \
 && sudo ./aws/install \
 && rm -rf aws awscliv2.zip

# install nvm
env NVM_DIR="$HOME/.nvm"
RUN curl -s https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash \
 && . $HOME/.nvm/nvm.sh \
 && nvm install 14 \
 && npm install -g yarn

# install golang
env PATH="$HOME/.gobrew/current/bin:$HOME/.gobrew/bin:$PATH"
RUN curl -sLk https://git.io/gobrew | sh - \
 && gobrew install 1.17
