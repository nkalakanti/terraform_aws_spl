#!/bin/bash
#Installing Docker
#Removing pre-installed docker installing Docker
sudo apt-get remove docker docker-engine docker.io
sudo apt-get update
sudo apt-get install -y \
apt-transport-https \
ca-certificates \
curl \
software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) \
stable" -y
sudo apt-get update
sudo apt-get install docker-ce -y
sudo usermod -a -G docker $USER
sudo systemctl enable docker
sudo systemctl restart docker
#creating reverse proxy config
sudo tee -a /home/ubuntu/nginx.conf >/dev/null <<EOT
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    multi_accept       on;
    worker_connections 65535;
}

http {
    server {
        listen       80;
        listen  [::]:80;
        server_name  localhost;

        access_log  /var/log/nginx/localhost.access.log;
        error_log   /var/log/nginx/localhost.error.log warn;
        
        location / {
            proxy_pass http://${private_ip}:8080/;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }
    }
}
EOT
cat /home/ubuntu/nginx.conf
#docker run
docker run -it --rm -p 80:80 --name web -v /home/ubuntu/nginx.conf:/etc/nginx/nginx.conf:ro -v /var/log/serverlogs:/var/log/nginx -d nginx
#installing unified cloudwatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
sudo usermod -aG adm cwagent
#configuring cloud watch agent
sudo tee -a /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json >/dev/null <<EOT
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "cwagent"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/localhost.access.log;",
            "log_group_name": "{instance_id}",
            "log_stream_name": "{instance_id}/access.log",
            "timestamp_format": "%b %d %H:%M:%S"
          },
          {
            "file_path": "/var/log/serverlogs/localhost.error.log",
            "log_group_name": "{instance_id}",
            "log_stream_name": "{instance_id}/error.log",
            "timestamp_format": "%b %d %H:%M:%S"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "public-ec2-metrics",

    "metrics_collected": {
      "cpu": {
        "namespace": "CPU",
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_iowait",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 30,
        "resources": ["*"],
        "totalcpu": false
      },
      "disk": {
        "namespace": "Disk",
        "measurement": ["used_percent", "inodes_free"],
        "metrics_collection_interval": 30,
        "resources": ["*"]
      },
      "diskio": {
        "namespace": "Disk Operations",
        "measurement": [
          "io_time",
          "write_bytes",
          "read_bytes",
          "writes",
          "reads"
        ],
        "metrics_collection_interval": 30,
        "resources": ["*"]
      },
      "mem": {
        "namespace": "RAM and Network",
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 30
      },
      "netstat": {
        "namespace": "RAM and Network",
        "measurement": ["tcp_established", "tcp_time_wait"],
        "metrics_collection_interval": 30
      },
      "statsd": {
        "metrics_aggregation_interval": 60,
        "metrics_collection_interval": 60,
        "service_address": ":8125"
      },
      "swap": {
        "namespace": "RAM and Network",
        "measurement": ["swap_used_percent"],
        "metrics_collection_interval": 30
      }
    }
  }
}
EOT
#starting cloudwatch agent
sudo systemctl enable amazon-cloudwatch-agent.service
sudo service amazon-cloudwatch-agent start