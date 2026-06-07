#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/systemworld"
SERVICE_NAME="systemworld-ai"
ENV_FILE="/etc/systemworld-ai.env"
REPO_URL="https://github.com/zhaodadao-chengxu/SystemWorld.git"
MODEL_ID="doubao-seed-2-0-lite-260428"

if [ "$(id -u)" -ne 0 ]; then
  echo "请用 root 身份运行：sudo bash tencent-ubuntu.sh"
  exit 1
fi

echo "==> 更新服务器组件"
apt-get update -y
apt-get install -y ca-certificates curl git

if ! command -v node >/dev/null 2>&1 || [ "$(node -p 'Number(process.versions.node.split(\".\")[0])')" -lt 20 ]; then
  echo "==> 安装 Node.js 22"
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt-get install -y nodejs
fi

echo "==> 下载 SystemWorld 后端"
if [ -d "$APP_DIR/.git" ]; then
  git -C "$APP_DIR" fetch --all
  git -C "$APP_DIR" reset --hard origin/main
else
  rm -rf "$APP_DIR"
  git clone "$REPO_URL" "$APP_DIR"
fi

echo "==> 安装后端依赖"
npm --prefix "$APP_DIR/Backend" install --omit=dev

if [ ! -f "$ENV_FILE" ]; then
  echo
  echo "请粘贴豆包/火山方舟 API Key，输入时屏幕不会显示，粘贴后按回车："
  read -r -s ARK_API_KEY
  echo
  if [ -z "$ARK_API_KEY" ]; then
    echo "API Key 不能为空"
    exit 1
  fi
  cat > "$ENV_FILE" <<EOF
PORT=80
ARK_API_KEY=$ARK_API_KEY
DOUBAO_MODEL=$MODEL_ID
EOF
  chmod 600 "$ENV_FILE"
else
  echo "==> 已存在 $ENV_FILE，继续使用原来的 API Key"
fi

echo "==> 配置开机自启服务"
cat > "/etc/systemd/system/$SERVICE_NAME.service" <<EOF
[Unit]
Description=SystemWorld AI Backend
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$APP_DIR/Backend
EnvironmentFile=$ENV_FILE
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=3
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

echo "==> 测试后端"
sleep 2
curl -fsS "http://127.0.0.1/health"
echo
echo "部署完成。公网测试地址："
echo "http://$(curl -fsS https://ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')/health"
