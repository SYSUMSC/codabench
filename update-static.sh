docker compose exec builder npm run build-stylus
docker compose exec builder npm run build-riot
docker compose exec builder npm run concat-riot
docker compose exec django ./manage.py collectstatic --noinput