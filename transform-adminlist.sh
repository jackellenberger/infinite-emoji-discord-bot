#!/bin/bash

if [ "$#" -eq 1 ]; then
  cat $1 \
    | jq -r '. | map({(.name): .url}) | add' \
    > emojilist.json.new

  if [ -f "emojilist.json" ]; then
    echo "Merging emojilist.json.new and emojilist.json.old\n"
    mv emojilist.json emojilist.json.old
    jq -Mn --argfile old emojilist.json.old --argfile new emojilist.json.new '$old + $new' > emojilist.json
  else
    mv emojilist.json.new emojilist.json
  fi

  echo "emojilist.json generated"
else
  echo 'Usage: transform-adminlist.sh <subdomain.adminList.json>'
fi
