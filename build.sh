#!/bin/bash

versions=$(
  echo 'bookworm' && \
  echo 'bullseye' && \
  echo 'buster' && \
  echo 'stretch' && \
  echo 'jessie' && \
  echo 'wheezy'
)

detectVersion () {
  # detection the major version of the image
  version=""
  if [[ "${version}" == "" ]] && [[ -f hashes/$1 ]] && [[ "$2" == "" ]]; then
    version=$(cat hashes/$1 | grep 'version' | sed -e 's/^version://')
  fi
  if [[ "${version}" == "" ]]; then
    for possibleVersion in $versions; do
      if [[ $1 == *"${possibleVersion}"* ]]; then
        version="${possibleVersion}"
      fi
    done
  fi

  if [[ "${version}" == "" ]]; then
   docker image pull node:$1 > /dev/null
    version=$(
      docker run --rm node:$1 cat /etc/os-release | \
      grep 'VERSION=' | \
      grep -oE '\(.*\)' | \
      grep -oE '\w+' || \
      echo ''
    )
  fi
  if [[ "${version}" == "" ]]; then
   docker image pull node:$1 > /dev/null
      version=$(
        docker run --rm node:$1 cat /etc/os-release | \
        grep 'PRETTY_NAME=' | \
        grep -oE '\w+/\w+"' | \
        grep -oE '\w+/' | \
        grep -oE '\w+' || \
        echo ''
      )
  fi
  if [[ "${version}" == "" ]]; then
    version=$(cat hashes/$1 | grep 'version' | sed -e 's/^version://')
  fi

  echo $version
}

detectDockerfile () {
    # detecting suitable docker file
    dockerfile="docker/Dockerfile"
    if [[ -f docker/$1/Dockerfile ]]; then
        dockerfile="docker/$1/Dockerfile"
    fi

    echo $dockerfile;
}

if [[ ! -d ./buildx-data ]]; then
    mkdir ./buildx-data
fi
if [[ ! -d ./buildx-data/index ]]; then
    mkdir ./buildx-data/index
fi
if [[ -f .url ]]; then
    URL=$(cat .url)
fi
tagsInclude=""
if [[ $URL == "" ]]; then
    URL=https://registry.hub.docker.com/v2/repositories/library/node/tags
    tagsInclude="${versions}"
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
        echo "${tagsInclude}" && \
        echo $content | \
        grep -oE '"name":"[^"]+"' | \
        sed -e 's/^"name":"//' | \
        sed -e 's/"$//' | \
        grep -v 'alpine' | \
        grep -v 'onbuild'
    )
    tags=$(echo "${tags}" | sed -E '/^$/d')
    tagsInclude=""
    for tag in $tags; do
        exitCode=1
        while [[ $exitCode != 0 ]]; do
            content=$(curl -sL https://registry.hub.docker.com/v2/repositories/library/node/tags/$tag)
            exitCode=$?
            echo "$exitCode - https://registry.hub.docker.com/v2/repositories/library/node/tags/$tag"
        done

        version=$(detectVersion $tag)
        dockerfile=$(detectDockerfile $version)

        if [[ "${version}" == "" ]]; then
            echo "Cannot detect version of ${tag}"
            exit 1
        fi

        md5=""
        if [[ "$(which md5)" != "" ]]; then
          md5=$(md5 -q $dockerfile)
        fi
        if [[ "$(which md5sum)" != "" ]]; then
          md5=$(md5sum $dockerfile | grep -oE '^[^ ]+')
        fi
        if [[ "${md5}" == "" ]]; then
          echo "Cannot calculate md5 sum for the template"
          exit 1
        fi

        digestCurrent=$(
            echo $content | \
            grep -oE '"digest":"[^"]+"' | \
            sed -e 's/^"digest":"//' | \
            sed -e 's/"$//' | \
            sort | \
            uniq && \
            echo dockerfile:${md5} && \
            echo version:${version}
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
            tr '\n' ',' | \
            sed -e 's/,$//'
        )
        if [[ "${platforms}" == "linux/" ]]; then
          platforms="linux/amd64"
        fi
        if [[ "${platforms}" == "" ]]; then
          platforms="linux/amd64"
        fi

        digestOld=$(cat hashes/$tag 2> /dev/null)
        digestBuildX=""
        if [[ "${digestOld}" != "" ]]; then
            digestBuildX=$(echo "${digestOld}" | grep 'buildx:' | sed -E 's/^buildx\:/--cache-from type=local,src=.\/buildx-data,digest=/g')
            digestOld=$(echo "${digestOld}" | sed -E '/buildx\:/d')
        fi
        if [[ "${digestCurrent}" != "" ]]; then
            currentBuildFile=$(echo "${digestCurrent}" | grep -oE '^sha256:.*$' | md5)
            if [[ -f "./buildx-data/index/${currentBuildFile}" ]]; then
                digestBuildX=$(
                    echo "${digestBuildX}" && \
                    echo "--cache-from type=local,src=./buildx-data,digest=$(cat ./buildx-data/index/${currentBuildFile})"
                )
            fi
        fi
        if [[ "${digestOld}" != "" ]]; then
            currentBuildFile=$(echo "${digestOld}" | grep -oE '^sha256:.*$' | md5)
            if [[ -f "./buildx-data/index/${currentBuildFile}" ]]; then
                digestBuildX=$(
                    echo "${digestBuildX}" && \
                    echo "--cache-from type=local,src=./buildx-data,digest=$(cat ./buildx-data/index/${currentBuildFile})"
                )
            fi
        fi

        if [[ "${digestOld}" != "" ]] && [[ "$(echo "$digestOld" | grep version:)" == "" ]]; then
            echo version:${version} >> hashes/$tag
            git add hashes/$tag
            git commit -m "chore($tag): version" hashes/$tag
            digestOld=$(
                echo "$digestOld" && \
                echo version:${version}
            )
        fi

        if [[ "$(echo "$digestCurrent" | sort)" != "$(echo "$digestOld" | sort)" ]] && [[ $digestCurrent != "" ]] || [[ -f hashes/$tag.error ]] || [[ -f "hashes/${tag}@error" ]]; then
            version=$(detectVersion $tag true)
            dockerfile=$(detectDockerfile $version)

            echo Tag: $tag
            echo Version: $version
            echo Dockerfile: $dockerfile
            echo Caches: $digestBuildX

            echo "FROM node:${tag}" > Dockerfile && \
            cat $dockerfile >> Dockerfile && \
            $(
              docker buildx build \
                --builder puppeteer-node \
                ${digestBuildX} \
                --cache-to type=local,dest=./buildx-data \
                --add-host archive.debian.org.lo:172.16.0.1 \
                --add-host deb.debian.org.lo:172.16.0.1 \
                --add-host httpredir.debian.org.lo:172.16.0.1 \
                --add-host security.debian.org.lo:172.16.0.1 \
                --add-host snapshot.debian.org.lo:172.16.0.1 \
                --platform $platforms \
                --tag satantime/puppeteer-node:$tag --push .
            ) && \
            digestCurrent=$(echo "${digestCurrent}" | sed -E '/version:/d' && echo "version:${version}") && \
            digestBuildX=$(cat ./buildx-data/index.json | jq -r '.manifests[].digest') && \
            digestCurrent=$(echo "${digestCurrent}" | sed -E '/buildx:/d' && echo "buildx:${digestBuildX}") && \
            currentBuildFile=$(echo "${digestCurrent}" | grep -oE '^sha256:.*$' | md5) && \
            echo "${digestBuildX}" > "./buildx-data/index/${currentBuildFile}" && \
            rm Dockerfile
            code="${?}"
            if [[ -f "hashes/${tag}.error" ]]; then
                rm "hashes/${tag}.error"
                git rm -f "hashes/${tag}.error"
            fi
            if [[ -f "hashes/${tag}@error" ]]; then
                rm "hashes/${tag}@error"
                git rm -f "hashes/${tag}@error"
            fi
            if [[ "${code}" == "0" ]]; then
                printf '%s\n' $digestCurrent > hashes/$tag
                git add hashes/$tag
                git commit -m "chore($tag): updated" "hashes/${tag}"
            fi
            if [[ "${code}" != "0" ]]; then
                printf '%s\n' $digestCurrent > "hashes/${tag}@error"
                git add "hashes/${tag}@error"
            fi
            sleep 10
        fi
        true;
    done
    true;
done
rm .url
