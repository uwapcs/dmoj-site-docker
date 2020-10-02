FROM debian:stretch

# Install required packages and remove apt cache when done.
RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \ 
  ca-certificates \
  chrpath \
  curl \
  debconf-utils \
  default-libmysqlclient-dev \
  gcc g++ \
  gettext \
  git \
  gnupg \
  libfontconfig1 libfontconfig1-dev \
  libfreetype6 libfreetype6-dev \
  libssl-dev \
  libxft-dev \
  libxml2-dev \
  libxslt1-dev \
  make \
  mysql-client \
  nano \
  nginx \
  openssl \
  python3 python3-dev python3-setuptools python3-pip \
  supervisor \
  wget \
  zlib1g-dev \
&& apt-get clean && rm -rf /var/bin/apt/lists/*

# Bootstrap pip and setuptools
RUN pip3 install --no-cache-dir --no-cache-dir -U pip setuptools

# Install uwsgi now because it takes a little while
RUN pip3 install --no-cache-dir uwsgi

# Get nodejs and install packages
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get install -y nodejs
RUN npm install -g --unsafe-perm=true phantomjs-prebuilt postcss postcss-cli autoprefixer sass

# Install app requirements before rest of code to be cache friendly
COPY site/requirements.txt /site/
RUN pip3 install --no-cache-dir -r /site/requirements.txt

# Copy app
COPY site /site

# Install utility so we can easily use docker secrets in local_settings.py
RUN pip3 install --no-cache-dir get-docker-secret

# Install recaptcha support
RUN pip3 install --no-cache-dir "django-recaptcha2<1.4.0"

# I don't know why these are here
RUN pip3 install --no-cache-dir mysqlclient
#RUN pip3 install --no-cache-dir "django_select2<7"

# Set up event server
RUN npm install qu ws simplesets
RUN pip3 install --no-cache-dir websocket-client
COPY websocket/config.js /site/websocket

# Copy uwsgi config
COPY uwsgi /uwsgi

# Copy supervisor configs
COPY supervisor /etc/supervisor/conf.d

# Configure nginx
COPY nginx/default /etc/nginx/sites-available/default

# Prepare problem storage
RUN mkdir -p /problems/pdfcache
RUN mkdir -p /problems/problems

# Install wait, as docker-entry depends on it
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.5.0/wait /wait
RUN chmod +x /wait

# Install docker-entry
COPY docker-entry /site

# Generate styles
RUN /site/make_style.sh

EXPOSE 80
EXPOSE 9999
EXPOSE 9998
EXPOSE 15100
EXPOSE 15101
EXPOSE 15102

WORKDIR /site
ENTRYPOINT ["/site/docker-entry"]
