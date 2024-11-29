package_cloud_username=""
package_cloud_packagename=""
read -p "Enter PackageCloud username: " package_cloud_username
read -p "Enter PackageCloud package name: " package_cloud_packagename

rm -rf target
rm dependency-reduced-pom.xml
ls

echo Fetching any potential remote changes...
git fetch --all
git pull --all

if ! [[ -f "./mvnw" ]]; then
  echo "The file, ``./mvnw``, does not exist."
  echo "Running ``mvn -N wrapper:wrapper`` to generate ``./mvnw``..."
  mvn -N wrapper:wrapper
fi

echo Fetching project metadata...
project_name=`./mvnw help:evaluate -Dexpression=project.name -q -DforceStdout`
project_version=`./mvnw help:evaluate -Dexpression=project.version -q -DforceStdout`
project_groupId=`./mvnw help:evaluate -Dexpression=project.groupId -q -DforceStdout`
project_artifactId=`./mvnw help:evaluate -Dexpression=project.artifactId -q -DforceStdout`


artifact_target=$package_cloud_username/$package_cloud_packagename
artifact_origin=./target/$project_artifactId-$project_version.jar
artifact_coords=$project_groupId:$project_artifactId:$project_version

echo "project_name: "            $project_name
echo "project_version: "         $project_version
echo "project_groupId: "         $project_groupId
echo "project_artifactId: "      $project_artifactId

echo "artifact_target: "         $artifact_target
echo "artifact_origin: "         $artifact_origin
echo "artifact_coords: "         $artifact_coords


echo Building maven application
echo ./mvnw package -Dmaven.test.skip=true
./mvnw package -Dmaven.test.skip=true


echo Pushing to package cloud
printf "0\n0\ny\n" | package_cloud push $artifact_target $artifact_origin --coordinates=$artifact_coords