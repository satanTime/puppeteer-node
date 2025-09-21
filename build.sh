#!/bin/bash

versions=$(
  echo 'trixie' && \
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
   docker image pull --platform linux/amd64 node:$1 > /dev/null
    version=$(
      docker run --rm --platform linux/amd64 node:$1 cat /etc/os-release | \
      grep 'VERSION=' | \
      grep -oE '\(.*\)' | \
      grep -oE '\w+' || \
      echo ''
    )
  fi
  if [[ "${version}" == "" ]]; then
   docker image pull --platform linux/amd64 node:$1 > /dev/null
      version=$(
        docker run --rm --platform linux/amd64 node:$1 cat /etc/os-release | \
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
  for version in $versions; do
    if [[ $version != "wheezy" ]] && [[ $version != "jessie" ]]; then
      tagsInclude=$(
        echo "${tagsInclude}" && \
        echo "${version}-slim"
      )
    fi
    tagsInclude=$(
      echo "${tagsInclude}" && \
      echo "${version}"
    )
    if [[ $version == "jessie" ]]; then
      tagsInclude=$(
        echo "${tagsInclude}" && \
        echo "dubnium-${version}-slim" && \
        echo "dubnium-${version}"
      )
    fi
  done
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
        echo $content | jq -r .next
    )
    if [[ "${URL}" == "null" ]]; then
      URL=""
    fi
    tags=$(
        echo "${tagsInclude}" && \
        echo $content | \
        jq -r '.results[].name' | \
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

        mediaType=$(
          echo $content | jq -r .media_type
        )
        if [[ "${mediaType:0:48}" == "application/vnd.docker.distribution.manifest.v1+" ]]; then
          continue;
        fi

        digestCurrent=$(
          echo $content | \
          jq -r '.digest, .images[].digest' | \
          sed '/^null$/d' | \
          sort | \
          uniq
        )
        tagStatus=$(
          echo $content | \
          jq -r '.tag_status'
        )
        if [[ "${digestCurrent}" == "" ]] && [[ "${tagStatus}" == "inactive" ]]; then
          continue;
        fi

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
        updateExist=$(curl --fail -s -o /dev/null "http://deb.debian.org/debian/dists/$version-updates/Release" && echo "yes" || echo "")
        securityExist=$(curl --fail -s -o /dev/null "http://security.debian.org/debian-security/dists/$version-security/Release" && echo "yes" || echo "")
        if [[ "${securityExist}" == "" ]]; then
          securityExist=$(curl --fail -s -o /dev/null "http://security.debian.org/debian-security/dists/$version/updates/Release" && echo "yes" || echo "")
        fi

        digestCurrent=$(
            echo "${digestCurrent}" && \
            echo dockerfile:${md5} && \
            echo version:${version}
        )
        platforms=$(
          echo $content | \
          jq -r '.images[] | (.os + "/" + .architecture + "/" + .variant)' | \
          sed '/unknown/d' | \
          sed 's/\/$//' | \
          sed 's/^\//linux\//' | \
          sort | \
          uniq | \
          tr '\n' ',' | \
          sed -e 's/,$//'
        )
        if [[ "${platforms}" == "linux/" ]]; then
          platforms="linux/amd64"
        fi
        if [[ "${platforms}" == "" ]]; then
          platforms="linux/amd64"
        fi
        contentType=$(
          echo $content | jq -r .content_type
        )

        digestOld=$(cat hashes/$tag 2> /dev/null)
        buildArgs=""
        if [[ "${digestOld}" != "" ]]; then
            buildArgs=$(echo "${digestOld}" | grep 'buildx:' | sed -E 's/^buildx\:/--cache-from type=local,src=.\/buildx-data,digest=/g')
            digestOld=$(echo "${digestOld}" | sed -E '/buildx\:/d')
        fi
        if [[ "${digestCurrent}" != "" ]]; then
            currentBuildFile=""
            if [[ "$(which md5)" != "" ]]; then
              currentBuildFile=$(echo "${digestCurrent}" | grep -oE '^sha256:.*$' | md5)
            fi
            if [[ "$(which md5sum)" != "" ]]; then
              currentBuildFile=$(echo "${digestCurrent}" | grep -oE '^sha256:.*$' | md5sum | grep -oE '^[^ ]+')
            fi
            if [[ "${currentBuildFile}" == "" ]]; then
              echo "Cannot calculate md5 sum for the digestCurrent"
              exit 1
            fi
            if [[ -f "./buildx-data/index/${currentBuildFile}" ]]; then
                buildArgs=$(
                    echo "${buildArgs}" && \
                    echo "--cache-from type=local,src=./buildx-data,digest=$(cat ./buildx-data/index/${currentBuildFile})"
                )
            fi
        fi
        if [[ "${digestOld}" != "" ]]; then
            currentBuildFile=""
            if [[ "$(which md5)" != "" ]]; then
              currentBuildFile=$(echo "${digestOld}" | grep -oE '^sha256:.*$' | md5)
            fi
            if [[ "$(which md5sum)" != "" ]]; then
              currentBuildFile=$(echo "${digestOld}" | grep -oE '^sha256:.*$' | md5sum | grep -oE '^[^ ]+')
            fi
            if [[ "${currentBuildFile}" == "" ]]; then
              echo "Cannot calculate md5 sum for the digestOld"
              exit 1
            fi
            if [[ -f "./buildx-data/index/${currentBuildFile}" ]]; then
                buildArgs=$(
                    echo "${buildArgs}" && \
                    echo "--cache-from type=local,src=./buildx-data,digest=$(cat ./buildx-data/index/${currentBuildFile})"
                )
            fi
        fi
        buildArgs=$(
          echo "${buildArgs}" && \
          echo "--cache-to type=local,dest=./buildx-data"
        )
        buildCommand="docker buildx build --builder puppeteer-node"
        if [[ "${contentType}" != "image" ]]; then
          buildCommand="docker --context=default buildx build" && \
          buildArgs=""
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
            echo Platforms: $platforms
            echo Update Repo: $updateExist
            echo Security Repo: $securityExist
            echo Dockerfile: $dockerfile
            echo Command: $buildCommand
            echo Args: $buildArgs

            echo "FROM node:${tag}" > Dockerfile && \
            cat $dockerfile \
              | sed -e "s/UPDATE_REPO=\"\"/UPDATE_REPO=\"${updateExist}\"/" \
              | sed -e "s/SECURITY_REPO=\"\"/SECURITY_REPO=\"${securityExist}\"/" \
              >> Dockerfile && \
            $(
               CONTAINERD_ENABLE_DEPRECATED_PULL_SCHEMA_1_IMAGE=1 ${buildCommand} ${buildArgs} \
                --add-host archive.debian.org.lo:172.16.0.1 \
                --add-host deb.debian.org.lo:172.16.0.1 \
                --add-host http.debian.net:172.16.0.1 \
                --add-host httpredir.debian.org.lo:172.16.0.1 \
                --add-host security.debian.org.lo:172.16.0.1 \
                --add-host snapshot.debian.org.lo:172.16.0.1 \
                --platform $platforms \
                --allow network.host \
                --tag satantime/puppeteer-node:$tag --push .
            ) && \
            digestCurrent=$(echo "${digestCurrent}" | sed -E '/version:/d' && echo "version:${version}") && \
            buildArgs=$(cat ./buildx-data/index.json | jq -r '.manifests[].digest') && \
            digestCurrent=$(echo "${digestCurrent}" | sed -E '/buildx:/d' && echo "buildx:${buildArgs}") && \
            currentBuildFile="" && \
            if [[ "$(which md5)" != "" ]]; then
              currentBuildFile=$(echo "${digestCurrent}" | grep -oE '^sha256:.*$' | md5)
            fi && \
            if [[ "$(which md5sum)" != "" ]]; then
              currentBuildFile=$(echo "${digestCurrent}" | grep -oE '^sha256:.*$' | md5sum | grep -oE '^[^ ]+')
            fi && \
            if [[ "${currentBuildFile}" == "" ]]; then
              echo "Cannot calculate md5 sum for the template"
              exit 1
            fi && \
            echo "${buildArgs}" > "./buildx-data/index/${currentBuildFile}" && \
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
