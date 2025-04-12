rm -rf ./src/staticfiles/*
rm -rf ./src/static/generated/*
docker compose stop django && docker compose rm -f django && docker compose up -d django

#docker compose stop builder && docker compose rm -f builder && docker compose up -d builder

docker compose exec django ./manage.py collectstatic --noinput

echo "Static files update complete!"
