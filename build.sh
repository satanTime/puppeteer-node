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
        content=$(curl -sL $URL)
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
#        if [[ `echo $tag | grep -oE '^[^\.-]+'` =~ ^(10|12|14|15|16|current|lts|dubnium|erbium|fermium)$ ]]; then
          skip=0
#        fi
        if [[ "${skip}" = "1" ]]; then
          continue
        fi

        exitCode=1
        while [[ $exitCode != 0 ]]; do
            content=$(curl -sL https://registry.hub.docker.com/v2/repositories/library/node/tags/$tag)
            exitCode=$?
            echo "$exitCode - https://registry.hub.docker.com/v2/repositories/library/node/tags/$tag"
        done

        digestCurrent=$(
            echo $content | \
            grep -oE '"digest":"[^"]+"' | \
            sed -e 's/^"digest":"//' | \
            sed -e 's/"$//' | \
            sort | \
            uniq && \
            echo dockerfile:`md5 -q Dockerfile.template`
        )
        platforms=$(
            echo $content | \
            grep -oE '"architecture":"[^"]+"' | \
            sed -e 's/^"architecture":"//' | \
            sed -e 's/"$//' | \
            sort | \
            uniq
        )
        platforms=$(
            echo "$platforms" | \
            sed -e 's/^/linux\//' | \
            grep -v 'ppc64le' | \
            tr '\n' ',' | \
            sed -e 's/,$//'
        )
        if [[ "${platforms}" == "linux/" ]]; then
          platforms="linux/amd64"
        fi
        if [[ "${platforms}" == "linux/amd64" ]]; then
          platforms=""
        fi

        digestOld=$(cat hashes/$tag 2> /dev/null)
        if [[ "$(echo "$digestCurrent" | sort)" != "$(echo "$digestOld" | sort)" ]] && [[ $digestCurrent != "" ]] || [[ -f hashes/$tag.error ]] || [[ -f "hashes/${tag}@error" ]]; then
            echo "FROM node:${tag}" > Dockerfile && \
            cat Dockerfile.template >> Dockerfile && \
            if [[ "${platforms}" == "" ]]; then
              DOCKER_BUILDKIT=0 docker build \
                  --add-host archive.debian.org.lo:172.16.0.1 \
                  --add-host deb.debian.org.lo:172.16.0.1 \
                  --add-host security.debian.org.lo:172.16.0.1 \
                  --add-host snapshot.debian.org.lo:172.16.0.1 \
                  --tag satantime/puppeteer-node:$tag . && \
              docker push satantime/puppeteer-node:$tag && \
              rm Dockerfile
              code="${?}"
            fi
            if [[ "${platforms}" != "" ]]; then
              docker buildx build \
                  --add-host archive.debian.org.lo:172.16.0.1 \
                  --add-host deb.debian.org.lo:172.16.0.1 \
                  --add-host security.debian.org.lo:172.16.0.1 \
                  --add-host snapshot.debian.org.lo:172.16.0.1 \
                  --platform $platforms \
                  --tag satantime/puppeteer-node:$tag --push . && \
              rm Dockerfile
              code="${?}"
            fi
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
