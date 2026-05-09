WORKDIR /src
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends unzip && rm -rf /var/lib/apt/lists/*
COPY ./src /src
RUN npm install
RUN npx puppeteer browsers install chrome
RUN npx puppeteer browsers install firefox
RUN find /root/.cache/puppeteer/ -name '*.zip' -execdir unzip -oq {} \;
CMD node index.js
