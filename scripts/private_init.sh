#!/bin/bash
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
sudo apt install unzip -y
#AWS cli installation
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
#fetching file from s3 
export AWS_DEFAULT_REGION=${aws_region}
export AWS_DEFAULT_OUTPUT=json
mkdir /home/ubuntu/site-content/
aws s3 cp s3://${bucket_name}/index.html /home/ubuntu/site-content/index.html
#docker run
docker run -it --rm -d -p 8080:80 --name web -v /home/ubuntu/site-content:/usr/share/nginx/html -v /var/log/serverlogs:/var/log/nginx nginx
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
            "file_path": "/var/log/serverlogs/access.log",
            "log_group_name": "{instance_id}",
            "log_stream_name": "{instance_id}/access.log",
            "timestamp_format": "%b %d %H:%M:%S"
          },
          {
            "file_path": "/var/log/serverlogs/error.log",
            "log_group_name": "{instance_id}",
            "log_stream_name": "{instance_id}/error.log",
            "timestamp_format": "%b %d %H:%M:%S"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "private-ec2-metrics",

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
