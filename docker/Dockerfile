RUN UPDATE_REPO="" && \
    SECURITY_REPO="" && \
    if [ -e /etc/apt/sources.list ]; then \
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
        updatedSources=$( \
          cat /etc/apt/sources.list | \
            sed -E 's/\.debian\.org/.debian.org.lo/g' \
        ) && \
        if [ "$UPDATE_REPO" = "" ]; then \
          updatedSources=$( \
            echo "${updatedSources}" | \
            sed -E '/-updates/d' | \
            sed -E '/\/updates/d' \
          ) && \
          true; \
        fi && \
        if [ "$SECURITY_REPO" = "" ]; then \
          updatedSources=$( \
            echo "${updatedSources}" | \
            sed -E '/-security/d' \
          ) && \
          true; \
        fi && \
        echo "${updatedSources}" > /etc/apt/sources.list.polished && \
        mv /etc/apt/sources.list.polished /etc/apt/sources.list && \
        echo "Updated sources.list:" && \
        cat /etc/apt/sources.list && \
        true; \
    fi && \
    if [ -e /etc/apt/sources.list.d/debian.sources ]; then \
        updatedSources=$( \
          cat /etc/apt/sources.list.d/debian.sources | \
          sed -z 's/\n/|/gm' | \
          sed -E 's/\|\|/\n/g' | \
          sed -E 's/\.debian\.org/.debian.org.lo/g' \
        ) && \
        if [ "$UPDATE_REPO" = "" ]; then \
          updatedSources=$( \
            echo "${updatedSources}" | \
            sed -E 's/Suites: ([^\s]+) \1-updates/Suites: \1/g' | \
            sed -E '/-updates/d' \
          ) && \
          true; \
        fi && \
        if [ "$SECURITY_REPO" = "" ]; then \
          updatedSources=$( \
            echo "${updatedSources}" | \
            sed -E '/debian-security/d' | \
            sed -E '/-security/d' \
          ) && \
          true; \
        fi && \
        echo "${updatedSources}" | sed -z 's/\n/\n\n/gm' | sed -E 's/\|/\n/g' > /etc/apt/sources.list.d/debian.sources.polished && \
        mv /etc/apt/sources.list.d/debian.sources.polished /etc/apt/sources.list.d/debian.sources && \
        echo "Updated sources.list:" && \
        cat /etc/apt/sources.list.d/debian.sources && \
        true; \
    fi && \
    apt update && \
    apt --fix-broken install -y --no-install-recommends \
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
        xz-utils \
    && \
    apt autoremove -y && \
    apt autoclean -y && \
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
