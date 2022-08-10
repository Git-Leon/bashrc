sourceRepo=$1
targetRepo=$2
destDirectory="$(date | awk -F':' '{print $1}')"

git clone $sourceRepo $destDirectory
cd $destDirectory
git branch -r | grep -v '\->' | while read remote; do git branch --track "${remote#origin/}" "$remote"; done
git fetch --all
git pull --all
git branch
git remote add new-origin $targetRepo
git remote --all new-origin
git push --all new-origin -f
git remote rm origin
git remote rename new-origin origin