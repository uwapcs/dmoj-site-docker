FROM debian:bookworm

# Prerequisite packages
RUN apt-get update && apt-get install -y --no-install-recommends \
	git \
	gcc \
	g++ \
	make \
	python3-dev \
	python3-pip \
	libxml2-dev \
	libxslt1-dev \
	zlib1g-dev \
	gettext \
	curl \
	default-libmysqlclient-dev \
	default-mysql-client \
	pkg-config \
	redis-server \
	supervisor \
	nginx \
	&& apt-get clean && rm -rf /var/bin/apt/lists/*

# Install uwsgi now because it takes a little while
RUN pip3 install --no-cache-dir --break-system-packages uwsgi

# Install nodejs and packages
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - # TODO migrate
RUN apt-get install nodejs
RUN npm install -g --unsafe-perm=true sass postcss-cli postcss autoprefixer

# Install site prerequisites
COPY site/requirements.txt /site/
RUN pip3 install --no-cache-dir --break-system-packages -r site/requirements.txt # TODO: don't break system packages
RUN pip3 install --no-cache-dir --break-system-packages mysqlclient

# Copy app
COPY site /site

# Install utility so we can easily use docker secrets in local_settings.py
RUN pip3 install --no-cache-dir --break-system-packages get-docker-secret

# Django recaptcha support
RUN pip3 install --no-cache-dir --break-system-packages django-recaptcha2 django-recaptcha3

# Install python redis for celery
RUN pip3 install --no-cache-dir --break-system-packages redis

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
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.12.0/wait /wait
RUN chmod +x /wait

# Install docker-entry
COPY docker-entry /site/
RUN chmod +x /site/docker-entry

# Set workdir. Note: due to a change in Node 15, this must come before local npm install commands
WORKDIR /site

# Set up event server
RUN npm install qu ws simplesets
RUN pip3 install --no-cache-dir --break-system-packages websocket-client
COPY websocket/config.js /site/websocket

ENTRYPOINT ["/site/docker-entry"]
