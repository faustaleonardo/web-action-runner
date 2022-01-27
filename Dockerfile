FROM summerwind/actions-runner@sha256:446c638534939b5be43b9366106def24380d283d34797066d672dbc4f3eb530d

# install buildah and google-chrome
RUN true \
 && echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" | sudo tee /etc/apt/sources.list.d/docker.list \
 && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list \
 && curl -sL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - \
 && curl -sL https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - \
 && sudo apt update -q \
 && sudo apt upgrade -q -y \
 && sudo apt install -q -y docker-ce-cli google-chrome-stable --no-install-recommends

# install aws cli
RUN cd /tmp \
 && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip" -o "awscliv2.zip" \
 && unzip awscliv2.zip \
 && sudo ./aws/install \
 && rm -rf aws awscliv2.zip

# install golang
env PATH="$HOME/.gobrew/current/bin:$HOME/.gobrew/bin:$PATH"
RUN curl -sLk https://git.io/gobrew | sh - \
 && gobrew install 1.17

# install volta
env VOLTA_HOME="$HOME/.volta"
env PATH="$PATH:$VOLTA_HOME/bin"
RUN curl https://get.volta.sh | bash \
 && volta install node@14 \
 && volta install yarn

# ecr login
RUN sudo curl -L -o /usr/bin/docker-credential-ecr-login https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/0.5.0/linux-amd64/docker-credential-ecr-login \
 && sudo chmod +x /usr/bin/docker-credential-ecr-login \
 && mkdir -p $HOME/.docker \
 && echo '{"credsStore": "ecr-login"}' > $HOME/.docker/config.json
