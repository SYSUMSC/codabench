docker compose stop django && docker compose rm -f django && docker compose up -d django
rm -rf ./src/staticfiles/*


# Make sure the builder service is running
echo "Starting builder service..."
docker compose up -d builder

# Give the builder service a moment to start
echo "Waiting for builder service to start..."
sleep 3

# Restart the builder service to trigger a rebuild of Riot.js and Stylus files
echo "Rebuilding Riot.js and Stylus files..."
docker compose restart builder

# Give the builder service time to rebuild the files
echo "Waiting for files to be rebuilt..."
sleep 5

# Clear the staticfiles directory
echo "Clearing staticfiles directory..."
rm -rf ./src/staticfiles/*

# Run collectstatic to collect the newly built files
echo "Running collectstatic..."
docker compose exec django ./manage.py collectstatic --noinput

echo "Static files update complete!"
