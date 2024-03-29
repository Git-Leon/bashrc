url=$1
urlWithoutSuffix="${url%.*}"
repoName="$(basename "${urlWithoutSuffix}")"
hostName="$(basename "${urlWithoutSuffix%/${repoName}}")"

git pull $url
git remote add $hostName git@github.com:$hostName/$repoName.git
git fetch $hostName

git branch -r | grep -v '\->' |\
while read remote; do
    git branch --track "${remote#origin/}" "$remote";
    git pull
done
git fetch --all
git pull --all
git branch
