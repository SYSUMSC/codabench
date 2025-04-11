docker compose stop django && docker compose rm -f django && docker compose up -d django
docker compose exec django ./manage.py collectstatic --noinput
