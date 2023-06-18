RUN if [ -e /etc/apt/sources.list ]; then \
        cp /etc/apt/sources.list /etc/apt/sources.list.bak && \
        echo "Original sources.list:" && \
        cat /etc/apt/sources.list && \
        true; \
    fi && \
    if [ -e /etc/apt/sources.list.d/debian.sources ]; then \
        cp /etc/apt/sources.list.d/debian.sources /etc/apt/debian.sources.bak && \
        echo "Original sources.list:" && \
        cat /etc/apt/sources.list.d/debian.sources && \
        true; \
    fi && \
    if [ -e /etc/apt/sources.list ]; then \
        sed -Ei "s/\.debian\.org/.debian.org.lo/g" /etc/apt/sources.list && \
        echo "Updated sources.list:" && \
        cat /etc/apt/sources.list && \
        true; \
    fi && \
    if [ -e /etc/apt/sources.list.d/debian.sources ]; then \
        sed -Ei "s/\.debian\.org/.debian.org.lo/g" /etc/apt/sources.list.d/debian.sources && \
        echo "Updated sources.list:" && \
        cat /etc/apt/sources.list.d/debian.sources && \
        true; \
    fi && \
    apt-get -o Acquire::Check-Valid-Until=false update && \
    apt-get -o Acquire::Check-Valid-Until=false install -y --force-yes --no-install-recommends \
        ca-certificates \
        fonts-liberation \
        gconf-service \
        libasound2 \
        libatk1.0-0 \
        libc6 \
        libcairo2 \
        libcups2 \
        libdbus-1-3 \
        libexpat1 \
        libfontconfig1 \
        libgbm1 \
        libgcc1 \
        libgconf-2-4 \
        libgdk-pixbuf2.0-0 \
        libglib2.0-0 \
        libgtk-3-0 \
        libnspr4 \
        libnss3 \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        libstdc++6 \
        libx11-6 \
        libx11-xcb1 \
        libxcb-dri3-0 \
        libxcb1 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxi6 \
        libxrandr2 \
        libxrender1 \
        libxshmfence1 \
        libxss1 \
        libxtst6 \
        lsb-release \
        wget \
    && \
    apt-get -o Acquire::Check-Valid-Until=false -y --force-yes autoremove && \
    apt-get -o Acquire::Check-Valid-Until=false -y --force-yes autoclean && \
    if [ -e /etc/apt/sources.list.bak ]; then \
        mv /etc/apt/sources.list.bak /etc/apt/sources.list && \
        rm -Rf /var/lib/apt/lists/* && \
        true; \
    fi && \
    if [ -e /etc/apt/debian.sources.bak ]; then \
        mv /etc/apt/debian.sources.bak /etc/apt/sources.list.d/debian.sources && \
        rm -Rf /var/lib/apt/lists/* && \
        true; \
    fi
