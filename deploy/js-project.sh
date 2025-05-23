# To ADD Stop all web containers for better performance
if [ "$(docker container ls -q --filter name=web)" ]; then
docker container stop $(docker container ls -q --filter name=web)
fi

#Import Traefik variables
set -o allexport
source ../data/.env
set +o allexport

#Set variables sent by github action script
GITHUB_ACCOUNT_NAME=${1}
GITHUB_REPOSITORY_NAME=${2}
PROJECT_NAME=${3}
GITHUB_JSON_VARS=${4}
DB_NAME=`echo "$GITHUB_REPOSITORY_NAME" | sed 's/\-/\_/g'`

#Create projects directory if not exists
mkdir -p "../../projects/envs"

#Clone the repository if not exists
if [ ! -d "../../projects/$GITHUB_REPOSITORY_NAME" ]; then
  cd "../../projects/"
  git clone https://github.com/$GITHUB_ACCOUNT_NAME/$GITHUB_REPOSITORY_NAME
  git switch staging
  cd -
fi

#Pull staging branch
cd "../../projects/$GITHUB_REPOSITORY_NAME"
git pull origin staging --rebase

#parse and write ENV vars for both front and backend
echo $GITHUB_JSON_VARS | jq 'to_entries[] | "\(.key)=\(.value)"' | sed 's/"//g' > ../envs/.env-$GITHUB_REPOSITORY_NAME
echo "VITE_API_URL=https://$PROJECT_NAME.$HOST" > ./client/.env
cat ../envs/.env-$GITHUB_REPOSITORY_NAME >> ./client/.env

#Build and start Docker container with docker compose
GITHUB_REPOSITORY_NAME=$GITHUB_REPOSITORY_NAME \
PROJECT_NAME=$PROJECT_NAME \
DB_NAME=$DB_NAME \
docker compose -f docker-compose.prod.yml \
--env-file ../../traefik/data/.env up -d --build --remove-orphans --force-recreate

# To ADD Restart mailhog containers
if [ "$(docker container ls -qa --filter name=web)" ]; then
docker container restart $(docker container ls -qa --filter name=web)
fi

docker system prune -a -f

