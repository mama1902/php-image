ARG REGISTRY_HOST
ARG REGISTRY_NAMESPACE
ARG REGISTRY_VERSION


MAINTAINER horsecma <569471385@qq.com>

ARG timezone
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV TIMEZONE=${timezone:-"Asia/Shanghai"}

LABEL org.opencontainers.image.authors="dior-pcis" \
      org.opencontainers.image.description="Application packaged by DIOR PCIS" \
      org.opencontainers.image.ref.name="magento-2.4.5" \
      org.opencontainers.image.source="https://dev.azure.com/KTDTC/DIOR%20E-Commerce/_git/dior-bz-platform_env-magento" \
      org.opencontainers.image.title="php8.2" \
      org.opencontainers.image.vendor="Shanghai Kaytune Industrial Co., Ltd." \
      org.opencontainers.image.version="1.0.0"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN lsb_release -s --release
USER root
WORKDIR /app

RUN echo "non-cached build" > non-cached-build.txt
COPY rootfs/php-8.3.8.tar.bz2 /usr/local/
COPY rootfs/redis-6.0.2.tgz /usr/local/
COPY rootfs/oniguruma-6.9.4.tar.gz /usr/local/
COPY rootfs/libsodium-2.0.23.tgz /usr/local/
COPY rootfs/s.list /etc/apt/sources.list
COPY rootfs/php.ini /app/www/php.ini
COPY install-php.sh /app/www/install-php.sh
COPY health_check2.php /app/www/health_check2.php

RUN  apt-get update  &&  apt-get install -y wget apt-utils dialog libreadline-dev vim



RUN apt-get install -y software-properties-common ca-certificates lsb-release apt-transport-https
RUN echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

RUN wget -qO - https://packages.sury.org/php/apt.gpg | sudo apt-key add -
RUN apt-key adv --fetch-keys 'https://packages.sury.org/php/apt.gpg' > /dev/null 2>&1
RUN apt-get update && apt-get upgrade -y && apt-get install -f


RUN chmod +x  /app/www/install-php.sh
RUN /app/www/install-php.sh 8.3.8  /usr/local/php

RUN  php -v &&  php -m


#COPY rootfs/php-fpm.conf /etc/php/8.2/fpm/php-fpm.conf
#COPY rootfs/www.conf /etc/php/8.2/fpm/pool.d/www.conf

RUN php /app/www/health_check2.php

EXPOSE 9000

CMD ["php-fpm"]
