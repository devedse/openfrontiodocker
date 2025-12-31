#!/bin/bash
set -e

echo "Starting OpenFrontIO..."
echo "Backend + Frontend will be available on port 80"

# Start supervisor which will manage nginx and node
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
