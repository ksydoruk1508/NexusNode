#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

echo -e "${GREEN}"
cat << "EOF"
███    ██ ███████ ██   ██ ██    ██ ███████ 
████   ██ ██       ██ ██  ██    ██ ██      
██ ██  ██ █████     ███   ██    ██ ███████ 
██  ██ ██ ██       ██ ██  ██    ██      ██ 
██   ████ ███████ ██   ██  ██████  ███████ 
                                                                                                                             
________________________________________________________________________________________________________________________________________


███████  ██████  ██████      ██   ██ ███████ ███████ ██████      ██ ████████     ████████ ██████   █████  ██████  ██ ███    ██  ██████  
██      ██    ██ ██   ██     ██  ██  ██      ██      ██   ██     ██    ██           ██    ██   ██ ██   ██ ██   ██ ██ ████   ██ ██       
█████   ██    ██ ██████      █████   █████   █████   ██████      ██    ██           ██    ██████  ███████ ██   ██ ██ ██ ██  ██ ██   ███ 
██      ██    ██ ██   ██     ██  ██  ██      ██      ██          ██    ██           ██    ██   ██ ██   ██ ██   ██ ██ ██  ██ ██ ██    ██ 
██       ██████  ██   ██     ██   ██ ███████ ███████ ██          ██    ██           ██    ██   ██ ██   ██ ██████  ██ ██   ████  ██████  
                                                                                                                                         
                                                                                                                                         
 ██  ██████  ██       █████  ███    ██ ██████   █████  ███    ██ ████████ ███████                                                         
██  ██        ██     ██   ██ ████   ██ ██   ██ ██   ██ ████   ██    ██    ██                                                             
██  ██        ██     ███████ ██ ██  ██ ██   ██ ███████ ██ ██  ██    ██    █████                                                          
██  ██        ██     ██   ██ ██  ██ ██ ██   ██ ██   ██ ██  ██ ██    ██    ██                                                             
 ██  ██████  ██      ██   ██ ██   ████ ██████  ██   ██ ██   ████    ██    ███████

Donate: 0x0004230c13c3890F34Bb9C9683b91f539E809000
EOF
echo -e "${NC}"

function install_node {
    echo -e "${BLUE}Обновляем сервер...${NC}"
    sudo apt update -y && sudo apt upgrade -y

    echo -e "${BLUE}Устанавливаем необходимые пакеты...${NC}"
    sudo apt install -y mc wget curl git htop net-tools unzip jq build-essential ncdu tmux make cmake clang pkg-config libssl-dev protobuf-compiler bc lz4 screen

    echo -e "${BLUE}Устанавливаем Rust...${NC}"
    sudo curl https://sh.rustup.rs -sSf | sh -s -- -y
    source $HOME/.cargo/env
    source ~/.profile

    echo -e "${BLUE}Создаем директорию для ноды Nexus...${NC}"
    mkdir -p ~/.nexus && cd ~/.nexus

    echo -e "${BLUE}Клонируем репозиторий Nexus...${NC}"
    git clone https://github.com/nexus-xyz/network-api
    cd network-api

    echo -e "${BLUE}Переключаемся на последнюю версию...${NC}"
    git -c advice.detachedHead=false checkout $(git rev-list --tags --max-count=1)

    echo -e "${BLUE}Собираем бинарный файл...${NC}"
    cd clients/cli
    cargo build --release --bin prover

    echo -e "${BLUE}Копируем бинарный файл в директорию...${NC}"
    cp target/release/prover ~/.nexus/network-api/clients/cli/prover

    echo -e "${YELLOW}Введите ваш Prover ID:${NC}"
    read PROVER_ID
    echo "$PROVER_ID" > ~/.nexus/prover-id

    echo -e "${BLUE}Создаем сервис Nexus...${NC}"
    sudo tee /etc/systemd/system/nexus.service > /dev/null <<EOF
[Unit]
Description=Nexus prover
After=network-online.target
StartLimitIntervalSec=0
[Service]
User=root
Restart=always
RestartSec=30
LimitNOFILE=65535
Type=simple
WorkingDirectory=/root/.nexus/network-api/clients/cli
ExecStart=/root/.nexus/network-api/clients/cli/prover -- beta.orchestrator.nexus.xyz
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

    echo -e "${BLUE}Перезагружаем системные службы...${NC}"
    sudo systemctl daemon-reload
    sudo systemctl enable nexus
    echo -e "${GREEN}Нода Nexus успешно установлена! Запустите ее вручную после проверки.${NC}"
}

function restart_node {
    echo -e "${BLUE}Перезапускаем сервис Nexus...${NC}"
    sudo systemctl restart nexus
}

function view_logs {
    echo -e "${YELLOW}Просмотр логов (выход из логов CTRL+C)...${NC}"
    sudo journalctl -u nexus -f --no-hostname -o cat
}

function remove_node {
    echo -e "${BLUE}Останавливаем и удаляем сервис Nexus...${NC}"
    sudo systemctl stop nexus
    sudo systemctl disable nexus
    sudo rm -f /etc/systemd/system/nexus.service
    sudo systemctl daemon-reload

    echo -e "${BLUE}Удаляем директорию ноды...${NC}"
    rm -rf ~/.nexus

    echo -e "${GREEN}Нода Nexus успешно удалена.${NC}"
}

function main_menu {
    while true; do
        echo -e "${YELLOW}Выберите действие:${NC}"
        echo -e "${CYAN}1. Установка ноды${NC}"
        echo -e "${CYAN}2. Рестарт ноды${NC}"
        echo -e "${CYAN}3. Просмотр логов${NC}"
        echo -e "${CYAN}4. Удаление ноды${NC}"
        echo -e "${CYAN}5. Выход${NC}"

        echo -e "${YELLOW}Введите номер действия:${NC} "
        read choice
        case $choice in
            1) install_node ;;
            2) restart_node ;;
            3) view_logs ;;
            4) remove_node ;;
            5) break ;;
            *) echo -e "${RED}Неверный выбор, попробуйте снова.${NC}" ;;
        esac
    done
}

main_menu
