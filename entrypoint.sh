#!/bin/bash

git config --global --add safe.directory "/github/workspace/$1"

cd $1
export DATA=$(curl $3 | jq --arg APP_NAME "$4" '{"data":map(select(.appName == $APP_NAME))}')

if [[ $2 =~ .*\.json ]]; then
    echo -e "$DATA" > $2
elif [[ $2 =~ .*\.swift ]]; then
    echo -e "// This Source Code Form is subject to the terms of the Mozilla Public\n// License, v. 2.0. If a copy of the MPL was not distributed with this\n// file, You can obtain one at http://mozilla.org/MPL/2.0/\n\nimport Foundation\n\npublic struct FirstRunExperiments {\n    public static let value = \"\"\"$DATA\"\"\"\n}" > $2
elif [[ $2 =~ .*\.kt ]]; then
    if [[ -z $6 ]]; then
        echo "Package is not specified. Package is a required value for the kotlin language."
        exit 1
    fi
    echo -e "// This Source Code Form is subject to the terms of the Mozilla Public\n// License, v. 2.0. If a copy of the MPL was not distributed with this\n// file, You can obtain one at http://mozilla.org/MPL/2.0/\n\npackage $6\n\nconst val firstRunExperiments = \"\"\"$DATA\"\"\"" > $2
else
    echo "Language of output file is not supported. Please choose between 'kotlin', 'swift', or 'json'"
    exit 1
fi

git status
export CHANGED=$(git status -s | wc -l)
export CHANGED_BRANCH=0

if test $CHANGED -eq 1
then
    git add $2
    echo "$CHANGED file(s) have been modified"

    export REMOTE_BRANCH=$(git ls-remote --head origin $5)
    if [[ -z $REMOTE_BRANCH ]];
    then
        export CHANGED_BRANCH=1
        echo "Remote branch currently does not exist; outputting that there are changes."
    else
        export CHANGED_BRANCH=$(git --no-pager diff origin/$5 | grep $2 | wc -l)
        if test $CHANGED_BRANCH -eq 1
        then
            echo "Remote branch differs from current changes, it should be updated."
        else
            echo "Remote branch and current changes are equivalent."
        fi
    fi
else
    echo "No changes to make, exiting job"
fi

echo "changed=$CHANGED" >> $GITHUB_OUTPUT
echo "changed-branch=$CHANGED_BRANCH" >> $GITHUB_OUTPUT
