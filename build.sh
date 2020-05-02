#!/bin/bash

if [[ -f .url ]]; then
    URL=$(cat .url)
fi
if [[ $URL == "" ]]; then
    URL=https://registry.hub.docker.com/v2/repositories/library/node/tags
fi

while [[ $URL != "" ]]; do
    echo $URL > .url

    exitCode=1
    while [[ $exitCode != 0 ]]; do
        content=$(curl -s $URL)
        exitCode=$?
        echo "$exitCode - $URL"
    done

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
        exitCode=1
        while [[ $exitCode != 0 ]]; do
            content=$(curl -s https://registry.hub.docker.com/v2/repositories/library/node/tags/$tag)
            exitCode=$?
            echo "$exitCode - https://registry.hub.docker.com/v2/repositories/library/node/tags/$tag"
        done

        template=''
        version=0
        versionMax=$(echo $tag | grep -oE '^\d+')
        while [[ "$version" -le "$versionMax" ]];
        do
            if [[ -f "Dockerfile${version}.template" ]]; then
                template="Dockerfile${version}.template"
            fi
            version=$((version + 1))
        done
        echo "Dockerfile: $template"

        digestCurrent=$(
            echo $content | \
            grep -oE '"digest":"[^"]+"' | \
            sed -e 's/^"digest":"//' | \
            sed -e 's/"$//' && \
            echo dockerfile:`md5 -q $template`
        )
        digestOld=$(cat hashes/$tag 2> /dev/null)
        if [[ $digestCurrent != $digestOld ]] && [[ $digestCurrent != "" ]]; then
            docker pull node:$tag
            docker pull satantime/puppeteer-node:$tag
            echo "FROM node:${tag}" > Dockerfile && \
            cat $template >> Dockerfile && \
            docker build . -t satantime/puppeteer-node:$tag && \
            docker push satantime/puppeteer-node:$tag && \
            rm Dockerfile && \
            printf '%s\n' $digestCurrent > hashes/$tag && \
            git add hashes/* && \
            git commit -m "Update of ${tag} on $(date +%Y-%m-%d)" hashes/* && \
            sleep 0;
        fi
        sleep 0;
    done;
    sleep 0;
done
rm .url
