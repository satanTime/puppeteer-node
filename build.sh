#!/bin/bash

if [[ -f .url ]]; then
    URL=$(cat .url)
fi
if [[ $URL == "" ]]; then
    URL=https://registry.hub.docker.com/v2/repositories/library/node/tags
fi

while [[ $URL != "" ]]; do
    echo $URL
    echo $URL > .url
    content=$(curl -s $URL)
    URL=$(
        echo $content | \
        grep -oE '"next":"https://registry.hub.docker.com/v2/[^"]+"' | \
        sed -e 's/^"next":"//' | \
        sed -e 's/"$//'
    )
    tags=$(
        echo $content | \
        grep -oE '"name":"[^"]+"' | \
        sed -e 's/^"name":"//' | \
        sed -e 's/"$//' | \
        grep -v 'alpine' | \
        grep -v 'onbuild' | \
        grep -v 'wheezy'
    )
    for tag in $tags; do
        echo $tag
        digestCurrent=$(
            curl -s https://registry.hub.docker.com/v2/repositories/library/node/tags/$tag | \
            grep -oE '"digest":"[^"]+"' | \
            sed -e 's/^"digest":"//' | \
            sed -e 's/"$//'
        )
        digestOld=$(cat hashes/$tag 2> /dev/null)
        if [[ $digestCurrent != $digestOld ]]; then
            docker pull node:$tag
            docker pull satantime/puppeteer-node:$tag
            echo "FROM node:${tag}" > Dockerfile && \
            cat Dockerfile.template >> Dockerfile && \
            docker build . -t satantime/puppeteer-node:$tag && \
            docker push satantime/puppeteer-node:$tag && \
            rm Dockerfile && \
            printf '%s\n' $digestCurrent > hashes/$tag
            sleep 0;
        fi
        sleep 0;
    done;
    sleep 0;
done
rm .url
git add --all
git commit -m "Update on $(date +%Y-%m-%d)"
