RUN mv /etc/apt/sources.list /etc/apt/sources.list.bak && \
    cp /etc/apt/sources.list.bak /etc/apt/sources.list && \
    echo "Original sources.list:" && \
    cat /etc/apt/sources.list && \
    echo 'deb http://deb.debian.org/debian jessie main' >> /etc/apt/sources.list && \
    sed -Ei "s/\.debian\.org/.debian.org.lo/g" /etc/apt/sources.list && \
    sed -Ei "/-updates/d" /etc/apt/sources.list && \
    sed -Ei "/\\/updates/d" /etc/apt/sources.list && \
    echo "Updated sources.list:" && \
    cat /etc/apt/sources.list && \
    apt-get -o Acquire::Check-Valid-Until=false update && \
    apt-get -o Acquire::Check-Valid-Until=false install -y --force-yes --no-install-recommends \
        bzip2 \
        ca-certificates \
        fonts-liberation \
        gconf-service \
        libasound2 \
        libatk1.0-0 \
        libbz2-1.0 \
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
        xz-utils=5.1.1alpha+20120614-2 \
    && \
    apt-get -o Acquire::Check-Valid-Until=false -y --force-yes autoremove && \
    apt-get -o Acquire::Check-Valid-Until=false -y --force-yes autoclean && \
    mv /etc/apt/sources.list.bak /etc/apt/sources.list && \
    rm -Rf /var/lib/apt/lists/*
