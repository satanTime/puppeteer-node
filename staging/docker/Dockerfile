WORKDIR /src
COPY ./src /src
RUN ["npm", "install"]
RUN ["npx", "rebrowser-puppeteer", "browsers", "install", "chrome"]
RUN ["npx", "rebrowser-puppeteer", "browsers", "install", "firefox"]
CMD ["node", "index.js"]
