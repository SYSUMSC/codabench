docker compose up -d
docker compose exec django ./manage.py migrate
docker compose exec django ./manage.py generate_data
docker compose exec django ./manage.py collectstatic --noinput