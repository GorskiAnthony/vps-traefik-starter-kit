#!/bin/bash

# Variables d'environnement
GITHUB_ACCOUNT_NAME=$1
GITHUB_REPOSITORY_NAME=$2
PROJECT_NAME=$3
DOCKER_USERNAME=$4

# Variables de configuration
PROJECTS_DIR="/home/ubuntu/projects"
ENVS_DIR="$PROJECTS_DIR/envs"
REPO_DIR="$PROJECTS_DIR/$GITHUB_REPOSITORY_NAME"
TMP_ENV_FILE="/tmp/$PROJECT_NAME.env"
GLOBAL_ENV="/home/ubuntu/traefik/data/.env"
PROJECT_SLUG=${PROJECT_NAME:-project}
DB_NAME="$PROJECT_NAME"

echo "🚀 Déploiement de $PROJECT_NAME à $(date '+%Y-%m-%d %H:%M:%S')"

# Charge les variables globales Traefik
if [ -f "$GLOBAL_ENV" ]; then
  set -o allexport
  source "$GLOBAL_ENV"
  set +o allexport
else
  echo "❌ Fichier global .env manquant : $GLOBAL_ENV"
  exit 1
fi

# Prépare les répertoires
mkdir -p "$ENVS_DIR"

# Clone si besoin
if [ ! -d "$REPO_DIR" ]; then
  cd "$PROJECTS_DIR"
  git clone https://github.com/$GITHUB_ACCOUNT_NAME/$GITHUB_REPOSITORY_NAME
  cd "$REPO_DIR"
  git switch staging
else
  cd "$REPO_DIR"
  git pull origin staging --rebase
fi

# Génération du fichier .env pour le container
echo "APP_PORT=3310" > "$TMP_ENV_FILE"
echo "APP_SECRET=$APP_SECRET" >> "$TMP_ENV_FILE"
echo "DB_HOST=${DATABASE_SUBDOMAIN_NAME}-db" >> "$TMP_ENV_FILE"
echo "DB_PORT=3306" >> "$TMP_ENV_FILE"
echo "DB_USER=$USER_NAME" >> "$TMP_ENV_FILE"
echo "DB_PASSWORD=$USER_PASSWORD" >> "$TMP_ENV_FILE"
echo "DB_NAME=$DB_NAME" >> "$TMP_ENV_FILE"
echo "HOST=$HOST" >> "$TMP_ENV_FILE"
echo "PROJECT_NAME=$PROJECT_NAME" >> "$TMP_ENV_FILE"
echo "DOCKER_IMAGE=$DOCKER_USERNAME/project-$PROJECT_NAME:latest" >> "$TMP_ENV_FILE"

# Copie le fichier .env dans le répertoire du projet
cp "$TMP_ENV_FILE" "$REPO_DIR/.env"

# Debug visible
echo "✅ Fichier .env généré dans /tmp :"
grep -E '^(APP_PORT|DB_HOST|DB_NAME|HOST|PROJECT_NAME)' "$TMP_ENV_FILE"
echo "ℹ️ Variables sensibles masquées (DB_USER, DB_PASSWORD, APP_SECRET)"

# Vite client (si projet front)
if [ -d "client" ]; then
  echo "VITE_API_URL=https://$PROJECT_NAME.$HOST" > client/.env
  cat "$TMP_ENV_FILE" >> client/.env
fi

# Pull de l’image
echo "➡️ Pull image : $DOCKER_USERNAME/project-$PROJECT_NAME:latest"
docker pull "$DOCKER_USERNAME/project-$PROJECT_NAME:latest"

# Stop container si existant
if docker container ls --format '{{.Names}}' | grep -q "${PROJECT_SLUG}-web"; then
  docker container stop "${PROJECT_SLUG}-web"
fi

# Lancer le container
DOCKER_IMAGE=$DOCKER_USERNAME/project-$PROJECT_NAME:latest \
docker compose -f docker-compose.prod.yml \
--env-file "$TMP_ENV_FILE" up -d --remove-orphans --force-recreate

# Restart forcé (si docker compose pas suffisant)
if docker container ls -qa --filter name="${PROJECT_SLUG}-web" > /dev/null; then
  docker container restart "${PROJECT_SLUG}-web"
fi

# Attente + migration
echo "⏳ Attente du démarrage du container (5s)..."
sleep 5

echo "🚀 Lancement de la migration (npm run db:migrate)..."
docker exec "${PROJECT_SLUG}-web" npm run db:migrate || echo "⚠️ Aucune migration exécutée ou erreur ignorée"

# Nettoyage
docker system prune -a -f

echo "✅ Déploiement terminé pour $PROJECT_NAME"

