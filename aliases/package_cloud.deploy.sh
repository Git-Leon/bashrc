rm -rf target
rm dependency-reduced-pom.xml
ls
git pull --all

currentDirectory=`pwd`
parentDirectory="$(dirname "$currentDirectory")"
project_version=`mvn help:evaluate -Dexpression=project.version -q -DforceStdout`
project_name=`mvn help:evaluate -Dexpression=project.name -q -DforceStdout`
mvn package -Dmaven.test.skip=true
ECHO package_cloud push git-leon/utils ./target/$project_name-$project_version.jar --coordinates=com.github.git-leon:$project_name:$project_version | clip

cat /dev/clipboard
ECHO output copied to clipboard
