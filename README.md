# OpenFrontIO Docker Build

Automated Docker builds for [OpenFrontIO](https://github.com/openfrontio/OpenFrontIO) - an online real-time strategy game focused on territorial control and alliance building.

## 🚀 Quick Start

A `docker-compose.yml` file is included in this repository. Access the game at http://localhost after starting.

## 📦 Available Tags

- `latest` - Latest build from the main branch
- `YYYYMMDD-HHMMSS` - Timestamped builds from the nightly scheduled runs
- Custom tags created via manual workflow dispatch

## 🔧 Building Locally

### Using PowerShell Script

The included PowerShell script will clone the repository and build the image:

```powershell
# Build only
.\build-local.ps1

# Build and push to Docker Hub
.\build-local.ps1 -Push

# Build with custom tag
.\build-local.ps1 -Push -Tag "v1.0.0"
```

### Manual Docker Build

1. Clone the OpenFrontIO repository:
```bash
git clone https://github.com/openfrontio/OpenFrontIO.git
cd OpenFrontIO
```

2. Build the image:
```bash
docker build -t devedse/openfrontio:latest .
```

3. Push to Docker Hub (optional):
```bash
docker push devedse/openfrontio:latest
```

## 🤖 Automated Builds

This repository includes a GitHub Actions workflow that:

- ✅ Runs every night at 2 AM UTC (scheduled build)
- ✅ Can be manually triggered via workflow dispatch
- ✅ Clones the latest OpenFrontIO code
- ✅ Builds a Docker image with the latest changes
- ✅ Tags the image with timestamp and commit hash
- ✅ Pushes to Docker Hub automatically

### Manual Trigger

1. Go to the [Actions tab](../../actions)
2. Select "Build and Push OpenFrontIO to Docker Hub"
3. Click "Run workflow"
4. Optionally specify a custom tag
5. Click "Run workflow" to start

## 🔑 Setup

### For GitHub Actions

Add the following secret to your repository:

- `DOCKERHUBTOKEN` - Your Docker Hub access token

To create a Docker Hub token:
1. Go to [Docker Hub Account Settings](https://hub.docker.com/settings/security)
2. Click "New Access Token"
3. Give it a description and appropriate permissions
4. Copy the token and add it to your GitHub repository secrets

### For Local Builds

Login to Docker Hub before pushing:

```bash
docker login
```

Or with PowerShell:

```powershell
docker login
```

## 📝 Configuration

### Environment Variables

The OpenFrontIO container supports the following environment variables:

| Variable | Description | Required |
|----------|-------------|----------|
| `CF_ACCOUNT_ID` | Cloudflare Account ID (for tunnel setup) | No |
| `CF_API_TOKEN` | Cloudflare API Token | No |
| `DOMAIN` | Your domain name | No |
| `SUBDOMAIN` | Subdomain for the deployment | No |
| `TURNSTILE_SECRET_KEY` | Cloudflare Turnstile secret key | No |
| `API_KEY` | API key for backend services | No |

### Volumes

- `/etc/cloudflared` - Cloudflare tunnel configuration (persisted)

### Ports

- `80` - HTTP web server (nginx)

## 🏗️ Architecture

The Docker image is built from the official OpenFrontIO repository using their multi-stage Dockerfile:

1. **Build Stage** - Installs dependencies and builds the application using Node.js and Vite
2. **Production Stage** - Creates a minimal production image with:
   - Node.js runtime
   - Nginx web server
   - Cloudflared (for Cloudflare tunnel support)
   - Supervisor (for process management)
   - Built application files

## 📚 OpenFrontIO Features

- Real-time Strategy Gameplay: Expand your territory and engage in strategic battles
- Alliance System: Form alliances with other players for mutual defense
- Multiple Maps: Play across various geographical regions
- Resource Management: Balance expansion with defensive capabilities
- Cross-platform: Runs in any modern web browser

## 🔗 Links

- [OpenFrontIO Official Repository](https://github.com/openfrontio/OpenFrontIO)
- [OpenFrontIO Website](https://openfront.io/)
- [Docker Hub Image](https://hub.docker.com/r/devedse/openfrontio)
- [Game Documentation](https://github.com/openfrontio/OpenFrontIO#readme)

## 📜 License

OpenFrontIO source code is licensed under the GNU Affero General Public License v3.0.
For asset licensing, see the [LICENSE-ASSETS](https://github.com/openfrontio/OpenFrontIO/blob/main/LICENSE-ASSETS) file.

This Docker build repository is maintained separately and is not officially affiliated with the OpenFrontIO project.

## 🤝 Contributing

This is a build automation repository. For contributing to OpenFrontIO itself, please visit the [main repository](https://github.com/openfrontio/OpenFrontIO).

## 💡 Support

For OpenFrontIO game issues, please visit:
- [OpenFrontIO Issues](https://github.com/openfrontio/OpenFrontIO/issues)
- [OpenFrontIO Discord](https://discord.gg/K9zernJB5z)

For Docker build issues related to this repository, please open an issue here.

## 🎮 Advanced Usage

### Development Mode

To run with development settings and access logs:

```bash
docker run -d \
  --name openfrontio-dev \
  -p 80:80 \
  -v $(pwd)/logs:/var/log/supervisor \
  devedse/openfrontio:latest
```

### With Custom Nginx Configuration

```bash
docker run -d \
  --name openfrontio \
  -p 80:80 \
  -v $(pwd)/nginx.conf:/etc/nginx/conf.d/default.conf:ro \
  devedse/openfrontio:latest
```

### Check Container Logs

```bash
# All logs
docker logs openfrontio

# Follow logs
docker logs -f openfrontio

# Supervisor logs
docker exec openfrontio cat /var/log/supervisor/supervisord.log
```

## 📊 Build Status

![Build Status](https://github.com/devedse/openfrontiodocker/actions/workflows/build-and-push.yml/badge.svg)

---

**Note**: This Docker image is built from the official OpenFrontIO source code. All game credits go to the OpenFrontIO team and contributors.
