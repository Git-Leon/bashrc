sourceRepo=$1
targetRepo=$2
destDirectory=$(date +%s)

git clone $sourceRepo $destDirectory
cd $destDirectory
git branch -r | grep -v '\->' |\
while read remote; do
    git branch --track "${remote#origin/}" "$remote"; done
git fetch --all
git pull --all
git branch
git remote add new-origin $targetRepo
git push --all new-origin -f
git remote rm origin
git remote rename new-origin origin
cd ..
rm -rf $destDirectory

echo "Successfully migrated!"
echo "source: [ $sourceRepo ]"
echo "source: [ $targetRepo ]"