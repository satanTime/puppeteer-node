#!/bin/bash

while [[ 1 ]]; do
    tags=$(
      git status -s \
      | grep 'hashes/' \
      | grep -E '^[AMR]  ' \
      | sed 's/[AMR]  //g' \
      | sed 's/^.*-> //g' \
      | grep -v '.error' \
      | grep -v '@error' \
      | sed 's/hashes\///g' \
      || echo '' \
    )

    for tag in $tags; do
        files="hashes/$tag"
        echo "Tag: $tag" && \
        docker push satantime/puppeteer-node:$tag && \
        git commit -m "Update of $tag on $(date +%Y-%m-%d)" hashes/$tag && \
        true
    done

    if [[ "$tags" == "" ]]; then
        echo "Empty queue... sleeping 5 seconds"
        sleep 5
    fi
done
