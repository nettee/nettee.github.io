FROM node:latest

WORKDIR /data/hexo

RUN npm --registry=https://registry.npm.taobao.org install hexo-cli -g \
    && npm install

CMD hexo clean && hexo g && hexo s
