FROM php:7-fpm
COPY config/php.ini /usr/local/etc/php/

RUN mkdir /tmp/xdebug
WORKDIR /tmp/xdebug
RUN apt-get update && apt-get install -y wget && wget https://xdebug.org/files/xdebug-2.7.2.tgz && tar -xvzf xdebug-2.7.2.tgz && apt-get install -y gnupg
WORKDIR /tmp/xdebug/xdebug-2.7.2
RUN echo "Dpkg::Options {\
   "--force-confdef";\
   "--force-confold";\
}" >  /etc/apt/apt.conf.d/local

RUN /usr/local/bin/phpize
RUN ./configure --enable-xdebug
RUN make && make test
RUN cp modules/xdebug.so /usr/local/lib/php/extensions/no-debug-non-zts-20180731/
RUN docker-php-ext-enable xdebug

# Configure xdebug
RUN echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.idekey=PHPSTORM" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote_connect_back=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote_host=192.168.99.1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote_autostart=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote_port=9001" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
EXPOSE 9001

#configure SSH
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:screencast' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22

#supervisor
RUN apt-get -y install gettext libgettextpo-dev supervisor
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

#composer
RUN wget http://getcomposer.org/installer && php installer && mv composer.phar /usr/local/bin/composer && rm installer

#git
RUN apt-get install -y libcurl4-openssl-dev pkg-config libssl-dev
#RUN pecl install mongodb && docker-php-ext-enable mongodb
#RUN echo "extension=mongodb.so" >> /usr/local/etc/php/php.ini
RUN apt-get install -y git && apt-get install -y curl && curl --silent --location https://deb.nodesource.com/setup_10.x | bash - && \
  apt-get install -y nodejs

#zip
RUN apt-get install -y libzip-dev && pecl install zip && docker-php-ext-enable zip

#mysql
RUN apt-key adv --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys 5072E1F5
RUN echo deb http://repo.mysql.com/apt/debian/ buster mysql-5.7 > /etc/apt/sources.list.d/mysql.list
RUN apt-get update && apt-get install -y mysql-client
RUN docker-php-ext-install mysqli && docker-php-ext-install pdo_mysql && docker-php-ext-install gettext

#apcu
RUN pecl install apcu && docker-php-ext-enable apcu && echo "apc.enable_cli = 1" >> /usr/local/etc/php/php.ini

#PHPUnit
RUN mkdir /tmp/phpUnit
WORKDIR /tmp/phpUnit
RUN wget https://phar.phpunit.de/phpunit.phar && chmod +x phpunit.phar && mv phpunit.phar /usr/local/bin/phpunit.phar

#other
RUN apt-get install -y vim nano dnsutils rsyslog cron && service cron start

#intl
RUN apt-get install -y libicu-dev && docker-php-ext-install intl

#opcode
RUN docker-php-ext-install opcache

#PHPUnit
WORKDIR /tmp
RUN wget https://phar.phpunit.de/phpunit.phar && chmod +x phpunit.phar && mv phpunit.phar /usr/local/bin/phpunit.phar

#LDAP
RUN apt-get update && \
    apt-get install libldap2-dev -y && \
    rm -rf /var/lib/apt/lists/* && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
    docker-php-ext-install ldap

#SOCKETS
RUN docker-php-ext-install sockets

#bash aliases
RUN echo 'alias enableDebug="export PHP_IDE_CONFIG=\"serverName=cli\"; echo \"debug enabled\""' >> ~/.bashrc
RUN echo 'alias disableDebug="export PHP_IDE_CONFIG=\"serverName=\"; echo \"debug disabled\""' >> ~/.bashrc
RUN echo 'alias webapp="cd /opt/webapp/"' >> ~/.bashrc

#redis
RUN pecl install redis && docker-php-ext-enable redis

#gd
RUN apt-get update && apt-get install -y libpng-dev && docker-php-ext-install gd

ENTRYPOINT ["/bin/sh","-c"]

CMD ["/usr/bin/supervisord", "-n"]

