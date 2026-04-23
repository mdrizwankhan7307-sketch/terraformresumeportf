#!/bin/bash
set -e

dnf update -y
dnf install -y python3-pip

pip3 install flask gunicorn pymysql flask-sqlalchemy

mkdir -p /home/ec2-user/app
cd /home/ec2-user/app

cat <<EOF > app.py
from flask import Flask

app = Flask(__name__)

@app.route("/")
def home():
    return {"message": "Flask working on EC2"}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF

cat <<EOF > /etc/systemd/system/flask.service
[Unit]
Description=Flask App
After=network.target

[Service]
User=root
WorkingDirectory=/home/ec2-user/app
ExecStart=/usr/local/bin/gunicorn -w 2 -b 0.0.0.0:5000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable flask
systemctl start flask

# 1. Set variables globally (This makes them survive reboots)
echo "DB_HOST=${db_host}" | sudo tee -a /etc/environment
echo "DB_NAME=${db_name}" | sudo tee -a /etc/environment
echo "DB_USER=${db_user}" | sudo tee -a /etc/environment
echo "DB_PASSWORD=${db_pass}" | sudo tee -a /etc/environment

# 2. Export them for this specific execution session
export DB_HOST=${db_host}
export DB_NAME=${db_name}
export DB_USER=${db_user}
export DB_PASSWORD=${db_pass}

# System Update
sudo apt update -y
sudo apt install -y python3 python3-pip python3-venv git
sudo apt install -y python3-venv python3-pip
sudo  apt install python3-pip -y
sudo  pip3 install flask
cd /home/ubuntu


python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip
pip install -r requirements.txt

# Start Gunicorn (It now has access to the exported variables)
nohup gunicorn -w 2 -b 0.0.0.0:5000 app:app > app.log 2>&1 &


