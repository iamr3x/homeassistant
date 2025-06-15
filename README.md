# Home Assistant Docker Setup

🏠 Complete Home Assistant setup with Docker Compose, ready for GitHub deployment.

## 📋 Prerequisites

- Docker และ Docker Compose
- Git
- Port 8123 available (Home Assistant web interface)

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone <your-repo-url>
cd homeassistant-docker
```

### 2. Setup Environment

```bash
# Copy environment template
cp .env.example .env

# Edit environment variables
nano .env
```

### 3. Create Required Directories

```bash
# สร้าง directories สำหรับ volumes
mkdir -p config media
mkdir -p mosquitto/{config,data,log}
mkdir -p grafana/{dashboards,datasources}

# Set permissions (สำคัญสำหรับ Home Assistant)
sudo chown -R 1000:1000 config media
```

### 4. Start Services

```bash
# Start all services
docker compose up -d

# Check logs
docker compose logs -f homeassistant
```

### 5. Access Home Assistant

- **Home Assistant**: <http://localhost:8123>
- **Grafana**: <http://localhost:3000> (admin/password จาก .env)
- **MQTT**: localhost:1883

## 📁 Directory Structure

```
homeassistant-docker/
├── docker-compose.yml
├── .env
├── .env.example
├── .gitignore
├── README.md
├── config/                 # Home Assistant configuration
├── media/                  # Media files
├── mosquitto/             # MQTT broker data
│   ├── config/
│   ├── data/
│   └── log/
└── grafana/               # Grafana configuration
    ├── dashboards/
    └── datasources/
```

## 🔧 Configuration

### Home Assistant Database (Optional)

ถ้าต้องการใช้ PostgreSQL แทน SQLite:

```yaml
# เพิ่มใน config/configuration.yaml
recorder:
  db_url: postgresql://homeassistant:password@postgres:5432/homeassistant
  purge_keep_days: 30
  auto_purge: true
```

### MQTT Configuration

```yaml
# เพิ่มใน config/configuration.yaml
mqtt:
  broker: mosquitto
  port: 1883
  username: homeassistant
  password: your_mqtt_password
```

## 🔒 Security Notes

- **ห้าม commit** `.env` file ไป GitHub
- เปลี่ยน default passwords ทั้งหมด
- ใช้ reverse proxy (nginx/traefik) สำหรับ production
- Enable SSL/TLS สำหรับ external access

## 📊 Monitoring & Backup

### Backup Script

```bash
#!/bin/bash
# backup.sh
DATE=$(date +%Y%m%d_%H%M%S)
tar -czf "backup_homeassistant_$DATE.tar.gz" config/ mosquitto/data/
```

### Health Checks

```bash
# Check all services
docker compose ps

# Check Home Assistant logs
docker compose logs homeassistant

# Check resource usage
docker stats
```

## 🔄 Updates

```bash
# Update images
docker compose pull

# Restart with new images
docker compose up -d

# Clean old images
docker image prune
```

## 🐛 Troubleshooting

### Common Issues

1. **Port conflicts**: ตรวจสอบว่า port 8123 ว่าง
2. **Permission issues**: `sudo chown -R 1000:1000 config/`
3. **Network issues**: ตรวจสอบ `network_mode: host`

### Useful Commands

```bash
# Restart Home Assistant only
docker compose restart homeassistant

# View real-time logs
docker compose logs -f

# Execute command in container
docker compose exec homeassistant bash
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## 📄 License

MIT License - see LICENSE file for details.
