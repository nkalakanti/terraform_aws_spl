#Custom dashboard for public ec2. for widget json use cloudwatch metrices section to copy json source
resource "aws_cloudwatch_dashboard" "public-dashboard" {
  dashboard_name = "public-ec2-dashboard"

  dashboard_body = jsonencode({
    "widgets" : [
      {
        "type" : "metric",
        "x" : 0,
        "y" : 0,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["public-ec2-metrics", "cpu_usage_iowait", "host", "ip-10-0-100-50", "cpu", "cpu0"],
            [".", "cpu_usage_user", ".", ".", ".", "."],
            [".", "cpu_usage_system", ".", ".", ".", "."],
            [".", "cpu_usage_idle", ".", ".", ".", "."]
          ],
          "period" : 300,
          "stat" : "Average",
          "region" : "${var.aws_region}",
          "title" : "Public EC2 Instance CPU"
        }
      },
      {
        "type" : "log",
        "x" : 12,
        "y" : 24,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "region" : "${var.aws_region}",
          "title" : "Nginx Logs",
          "query" : "SOURCE '${aws_instance.public-ec2.id}' | fields @timestamp, @message | sort @timestamp desc | limit 25",
          "view" : "table"
        }
      }
    ]
  })
}

#Custom dashboard for private ec2. for widget json use cloudwatch metrices section to copy json source
resource "aws_cloudwatch_dashboard" "private-dashboard" {
  dashboard_name = "private-ec2-dashboard"

  dashboard_body = jsonencode({
    "widgets" : [
      {
        "type" : "metric",
        "x" : 0,
        "y" : 0,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["private-ec2-metrics", "cpu_usage_iowait", "host", "ip-10-0-1-50", "cpu", "cpu0"],
            [".", "cpu_usage_user", ".", ".", ".", "."],
            [".", "cpu_usage_system", ".", ".", ".", "."],
            [".", "cpu_usage_idle", ".", ".", ".", "."]
          ],
          "period" : 300,
          "stat" : "Average",
          "region" : "${var.aws_region}",
          "title" : "Private EC2 Instance CPU"
        }
      },
      {
        "type" : "log",
        "x" : 12,
        "y" : 24,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "region" : "${var.aws_region}",
          "title" : "Nginx Logs",
          "query" : "SOURCE '${aws_instance.private-ec2.id}' | fields @timestamp, @message | sort @timestamp desc | limit 25",
          "view" : "table"
        }
      }
    ]
  })
}