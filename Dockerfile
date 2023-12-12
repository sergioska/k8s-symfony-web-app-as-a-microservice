FROM php:7.4-fpm AS php-stage

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    gnupg \
    && apt-get clean

RUN until apt-get update; do echo "Retrying apt-get update"; sleep 5; done

RUN apt-get install -y --no-install-recommends \
    unzip \
    libicu-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    && apt-get clean

RUN apt-get update && apt-get install -y libxml2-dev

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd intl pdo pdo_mysql zip calendar soap

RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    echo "deb https://deb.nodesource.com/node_14.x $(lsb_release -cs) main" > /etc/apt/sources.list.d/nodesource.list && \
    echo "deb-src https://deb.nodesource.com/node_14.x $(lsb_release -cs) main" >> /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y nodejs

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /var/www/html

COPY . .

RUN composer install --no-scripts

RUN npm install

# RUN npm run dev

FROM nginx:alpine AS nginx-stage

COPY .docker/nginx/nginx.conf /etc/nginx/nginx.conf

#COPY mysql/my.cnf  /var/lib/mysql

FROM php-stage AS symfony-app

COPY --from=php-stage /var/www/html /var/www/html

EXPOSE 9000

CMD ["php-fpm"]

WORKDIR /var/www/html

COPY --from=nginx-stage /etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=php-stage /var/www/html/public_html /var/www/html
EXPOSE 8080

RUN chmod -R 774 /var/www/html
#RUN chmod -R 777 /var/www/html/var/cache
RUN chmod -R 774 /var/www/html/vendor
#
WORKDIR /var/lib/mysql

RUN chmod -R 774 /var/lib/mysql


#Securite symfony 
#linux + dockerifle gerer 2 instances qui communiquent 
# KEY
# Makefile