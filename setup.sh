#!/bin/bash

# Home Assistant Docker Setup Script
# สำหรับ setup เริ่มต้นและการจัดการ

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    print_status "ตรวจสอบ dependencies..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker ไม่ได้ติดตั้ง"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose ไม่ได้ติดตั้ง"
        exit 1
    fi

    print_success "Dependencies พร้อมใช้งาน"
}

create_directories() {
    print_status "สร้าง directories..."

    mkdir -p config media
    mkdir -p mosquitto/{config,data,log}
    mkdir -p grafana/{dashboards,datasources}

    print_success "สร้าง directories เรียบร้อย"
}

setup_permissions() {
    print_status "ตั้งค่า permissions..."

    # Home Assistant ใช้ UID 1000
    sudo chown -R 1000:1000 config media 2>/dev/null || {
        print_warning "ไม่สามารถเปลี่ยน owner ได้ (อาจต้องใช้ sudo)"
    }

    # Mosquitto directories
    chmod -R 755 mosquitto/

    print_success "ตั้งค่า permissions เรียบร้อย"
}

setup_environment() {
    if [ ! -f .env ]; then
        print_status "สร้าง .env file..."
        cp .env.example .env
        print_warning "กรุณาแก้ไข .env file ก่อนเริ่มใช้งาน"
        print_warning "nano .env"
    else
        print_success ".env file มีอยู่แล้ว"
    fi
}

create_mosquitto_users() {
    print_status "สร้าง MQTT users..."

    if [ ! -f mosquitto/config/password_file ]; then
        # สร้าง mosquitto user
        echo "homeassistant:homeassistant" > mosquitto/config/password_file

        # Hash passwords (ถ้า mosquitto_passwd มี)
        if command -v mosquitto_passwd &> /dev/null; then
            mosquitto_passwd -U mosquitto/config/password_file
        else
            print_warning "mosquitto_passwd ไม่พบ - password จะไม่ถูก hash"
        fi

        print_success "สร้าง MQTT users เรียบร้อย"
    else
        print_success "MQTT users มีอยู่แล้ว"
    fi
}

start_services() {
    print_status "เริ่มต้น services..."

    if docker compose version &> /dev/null; then
        docker compose up -d
    else
        docker-compose up -d
    fi

    print_success "Services เริ่มต้นแล้ว"
    print_status "รอ Home Assistant พร้อมใช้งาน..."

    # รอ Home Assistant ready
    timeout=120
    counter=0

    while [ $counter -lt $timeout ]; do
        if curl -s http://localhost:8123 > /dev/null 2>&1; then
            print_success "Home Assistant พร้อมใช้งานแล้ว!"
            break
        fi

        echo -n "."
        sleep 2
        counter=$((counter + 2))
    done

    if [ $counter -ge $timeout ]; then
        print_warning "Home Assistant ใช้เวลานานกว่าปกติ ตรวจสอบ logs: docker compose logs homeassistant"
    fi
}

show_info() {
    echo ""
    print_success "🎉 Setup เสร็จสิ้น!"
    echo ""
    echo "📍 Access URLs:"
    echo "   Home Assistant: http://localhost:8123"
    echo "   Grafana:        http://localhost:3000"
    echo "   MQTT:           localhost:1883"
    echo ""
    echo "🔧 Useful Commands:"
    echo "   docker compose logs -f homeassistant  # ดู logs"
    echo "   docker compose restart homeassistant  # restart"
    echo "   docker compose down                   # stop ทั้งหมด"
    echo ""
    echo "📝 Next Steps:"
    echo "   1. เปิด http://localhost:8123 เพื่อ setup Home Assistant"
    echo "   2. แก้ไข config/configuration.yaml ตามต้องการ"
    echo "   3. เพิ่ม devices และ automations"
    echo ""
}

backup_data() {
    print_status "สร้าง backup..."

    DATE=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="backup_homeassistant_$DATE.tar.gz"

    tar -czf "$BACKUP_FILE" config/ mosquitto/data/ grafana/ .env 2>/dev/null || true

    print_success "Backup สร้างเรียบร้อย: $BACKUP_FILE"
}

show_status() {
    echo ""
    print_status "Service Status:"

    if docker compose version &> /dev/null; then
        docker compose ps
    else
        docker-compose ps
    fi

    echo ""
    print_status "Resource Usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
}

case "${1:-setup}" in
    "setup")
        print_status "🚀 เริ่ม setup Home Assistant..."
        check_dependencies
        create_directories
        setup_environment
        setup_permissions
        create_mosquitto_users
        start_services
        show_info
        ;;
    "start")
        print_status "🔄 เริ่ม services..."
        docker compose up -d
        show_status
        ;;
    "stop")
        print_status "⏹️  หยุด services..."
        docker compose down
        ;;
    "restart")
        print_status "🔄 restart services..."
        docker compose restart
        show_status
        ;;
    "backup")
        backup_data
        ;;
    "status")
        show_status
        ;;
    "logs")
        SERVICE=${2:-homeassistant}
        docker compose logs -f $SERVICE
        ;;
    "update")
        print_status "🔄 อัพเดท images..."
        docker compose pull
        docker compose up -d
        docker image prune -f
        print_success "อัพเดทเรียบร้อย"
        ;;
    *)
        echo "Usage: $0 {setup|start|stop|restart|backup|status|logs|update}"
        echo ""
        echo "Commands:"
        echo "  setup   - Initial setup (default)"
        echo "  start   - Start all services"
        echo "  stop    - Stop all services"
        echo "  restart - Restart all services"
        echo "  backup  - Create backup"
        echo "  status  - Show service status"
        echo "  logs    - Show logs (add service name as 2nd arg)"
        echo "  update  - Update Docker images"
        exit 1
        ;;
esac
