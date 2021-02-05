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
        skip=1
        if [[ `echo $tag | grep -oE '^[^\.-]+'` =~ ^(10|12|14|15|16|dubnium|erbium|fermium)$ ]]; then
          skip=0
        fi
        if [[ "${skip}" = "1" ]]; then
          continue
        fi

        exitCode=1
        while [[ $exitCode != 0 ]]; do
            content=$(curl -s https://registry.hub.docker.com/v2/repositories/library/node/tags/$tag)
            exitCode=$?
            echo "$exitCode - https://registry.hub.docker.com/v2/repositories/library/node/tags/$tag"
        done

        digestCurrent=$(
            echo $content | \
            grep -oE '"digest":"[^"]+"' | \
            sed -e 's/^"digest":"//' | \
            sed -e 's/"$//' && \
            echo dockerfile:`md5 -q Dockerfile.template`
        )
        platforms=$(
            echo $content | \
            grep -oE '"architecture":"[^"]+"' | \
            sed -e 's/^"architecture":"//' | \
            sed -e 's/"$//' | \
            sed -e 's/^/linux\//' | \
            tr '\n' ',' | \
            sed -e 's/,$//'
        )

        digestOld=$(cat hashes/$tag 2> /dev/null)
        if [[ "$(echo "$digestCurrent" | sort)" != "$(echo "$digestOld" | sort)" ]] && [[ $digestCurrent != "" ]] || [[ -f hashes/$tag.error ]] || [[ -f "hashes/${tag}@error" ]]; then
            docker pull node:$tag
            docker pull satantime/puppeteer-node:$tag
            echo "FROM node:${tag}" > Dockerfile && \
            cat Dockerfile.template >> Dockerfile && \
            docker buildx build \
                --platform $platforms \
                --tag satantime/puppeteer-node:$tag --push . && \
            rm Dockerfile
            code="${?}"
            if [[ -f hashes/$tag.error ]]; then
                git rm -f hashes/$tag.error
            fi
            if [[ -f "hashes/${tag}@error" ]]; then
                git rm -f "hashes/${tag}@error"
            fi
            if [[ "${code}" == "0" ]]; then
                printf '%s\n' $digestCurrent > hashes/$tag
                git add hashes/$tag
                git commit -m "Update of $tag on $(date +%Y-%m-%d)" hashes/$tag
            fi
            if [[ "${code}" != "0" ]]; then
                printf '%s\n' $digestCurrent > "hashes/${tag}@error"
                git add "hashes/${tag}@error"
            fi
        fi
        true;
    done
    true;
done
rm .url
