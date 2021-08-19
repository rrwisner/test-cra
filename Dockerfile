# => Build container
FROM node:alpine as builder
WORKDIR /app
COPY package.json .
COPY yarn.lock .
RUN yarn
COPY . .
RUN yarn build

# => Run container
FROM nginx:latest

RUN apt-get update && apt-get install -y \
  awscli git jq build-essential curl bison \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /var/cache/apt/*

ARG bash_3_version=3.2.57

WORKDIR /tmp
RUN curl -o bash-${bash_3_version}.tar.gz \
  http://ftp.gnu.org/gnu/bash/bash-${bash_3_version}.tar.gz
RUN tar xf bash-${bash_3_version}.tar.gz

WORKDIR /tmp/bash-${bash_3_version}
RUN ./configure --prefix=/opt/bash3
RUN make EXEEXT=3
RUN make install EXEEXT=3

# Nginx config
RUN rm -rf /etc/nginx/conf.d
COPY conf /etc/nginx

# Add bash 3 to PATH
ENV PATH=/opt/bash3/bin:$PATH

# Static build
COPY --from=builder /app/build /usr/share/nginx/html/build/
COPY --from=builder /app/scripts /usr/share/nginx/html/

# Default port exposure
EXPOSE 80

# Copy .env file and shell script to container
WORKDIR /usr/share/nginx/html
COPY .env .

# Start Nginx server
CMD ["/bin/sh", "-c", "/usr/share/nginx/html/run.sh && nginx -g \"daemon off;\""]
