if [[ $(docker ps -q) ]] 
    then
        docker kill $(docker ps -q)
else
    true
fi


if [[ $(docker ps -aq) ]]
    then
        docker rm $(docker ps -aq) ;
else
    true
fi

service docker restart