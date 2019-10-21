FROM php:7-fpm
COPY config/php.ini /usr/local/etc/php/

RUN mkdir /tmp/xdebug
WORKDIR /tmp/xdebug
RUN apt-get update && \
    apt-get install -y wget && \
    wget https://xdebug.org/files/xdebug-2.7.2.tgz && \
    tar -xvzf xdebug-2.7.2.tgz && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /tmp/xdebug/xdebug-2.7.2
RUN echo "Dpkg::Options {\
   "--force-confdef";\
   "--force-confold";\
}" >  /etc/apt/apt.conf.d/local

RUN /usr/local/bin/phpize && \
    ./configure --enable-xdebug && \
    make && \
    make test && \
    cp modules/xdebug.so /usr/local/lib/php/extensions/no-debug-non-zts-20180731/ && \
    docker-php-ext-enable xdebug

# Configure xdebug
RUN echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.idekey=PHPSTORM" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.remote_connect_back=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.remote_host=192.168.99.1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.remote_autostart=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.remote_port=9001" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
EXPOSE 9001

#configure SSH
RUN apt-get update && \
    apt-get install -y openssh-server && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /var/run/sshd
RUN echo 'root:screencast' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22

#supervisor
RUN apt-get update && \
    apt-get -y install gettext libgettextpo-dev supervisor && \
    rm -rf /var/lib/apt/lists/*
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

#composer
RUN wget http://getcomposer.org/installer && \
    php installer && \
    mv composer.phar /usr/local/bin/composer && \
    rm installer

#git
RUN apt-get update && \
    apt-get install -y libcurl4-openssl-dev pkg-config libssl-dev && \
    apt-get install -y git && \
    apt-get install -y curl && \
    curl --silent --location https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

#zip
RUN apt-get update && \
    apt-get install -y libzip-dev && \
    pecl install zip && \
    docker-php-ext-enable zip && \
    rm -rf /var/lib/apt/lists/*

#mysql
RUN apt-get update && \
    apt-get install -y default-mysql-client && \
    docker-php-ext-install mysqli && \
    docker-php-ext-install pdo_mysql && \
    docker-php-ext-install gettext && \
    rm -rf /var/lib/apt/lists/*

#apcu
RUN pecl install apcu && \
    docker-php-ext-enable apcu && \
    echo "apc.enable_cli = 1" >> /usr/local/etc/php/php.ini

#PHPUnit
RUN mkdir /tmp/phpUnit
WORKDIR /tmp/phpUnit
RUN wget https://phar.phpunit.de/phpunit.phar && \
    chmod +x phpunit.phar && \
    mv phpunit.phar /usr/local/bin/phpunit.phar

#other
RUN apt-get update && \
    apt-get install -y vim nano dnsutils rsyslog cron && \
    service cron start && \
    rm -rf /var/lib/apt/lists/*

#intl
RUN apt-get update && \
    apt-get install -y libicu-dev && \
    docker-php-ext-install intl && \
    rm -rf /var/lib/apt/lists/*

#opcode
RUN docker-php-ext-install opcache

#PHPUnit
WORKDIR /tmp
RUN wget https://phar.phpunit.de/phpunit.phar && \
    chmod +x phpunit.phar && \
    mv phpunit.phar /usr/local/bin/phpunit.phar

#LDAP
RUN apt-get update && \
    apt-get install libldap2-dev -y && \
    rm -rf /var/lib/apt/lists/* && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
    docker-php-ext-install ldap && \
    rm -rf /var/lib/apt/lists/*

#SOCKETS
RUN docker-php-ext-install sockets

#bash aliases
RUN echo 'alias enableDebug="export PHP_IDE_CONFIG=\"serverName=cli\"; echo \"debug enabled\""' >> ~/.bashrc && \
    echo 'alias disableDebug="export PHP_IDE_CONFIG=\"serverName=\"; echo \"debug disabled\""' >> ~/.bashrc && \
    echo 'alias webapp="cd /opt/webapp/"' >> ~/.bashrc

#redis
RUN pecl install redis && \
    docker-php-ext-enable redis

#gd
RUN apt-get update && \
    apt-get install -y libpng-dev && \
    docker-php-ext-install gd && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/bin/sh","-c"]

CMD ["/usr/bin/supervisord", "-n"]

