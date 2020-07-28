docker-compose down
docker rmi oracle/database:19.3.0-ee
docker image prune <<< y

rm -rf ~/oradata/DG*

# Run the build to create the oracle/database:19.3.0-ee Docker image
./buildDockerImage.sh -v 19.3.0 -e

# Run compose (detached)
docker-compose up -d
# Tail the logs
docker-compose logs -f
