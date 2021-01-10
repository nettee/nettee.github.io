FROM node:latest

RUN mkdir -p /data/hexo
WORKDIR /data/hexo

COPY . .

RUN npm --registry=https://registry.npm.taobao.org install hexo-cli -g \
    && npm install

CMD hexo clean && hexo g && hexo s
