`redis`
```bash

sudo apt install redis-server
sudo systemctl restart redis-server

redis-cli

redis-cli --raw

KEYS *

TTL products:None:7:荧光

redis-cli DEL key_name

FLUSHDB

```

`nginx`
```bash
sudo apt install nginx
sudo systemctl restart nginx

sudo nginx -t
sudo systemctl reload nginx

sudo systemctl status nginx

tail -f /var/log/nginx/error.log

curl -I https://mini.msbiox.com/images/1.webp

```

`Certbot`
```bash
sudo chown ubuntu:ubuntu /etc/nginx/sites-enabled/default

sudo apt update
sudo apt install certbot python3-certbot-nginx

sudo certbot --nginx -d mini.msbiox.com

sudo certbot delete --cert-name mini.msbiox.com

```
`单公网IP申请SSL证书`
```bash
sudo apt update
sudo apt install snapd -y
sudo snap install core
sudo snap refresh core
sudo snap install --classic certbot

sudo certbot renew --force-renewal
```

```bash
nginx -T | grep -n "root "

sudo certbot certonly \
  --preferred-profile shortlived \
  --webroot \
  --webroot-path /var/www/html \
  --ip-address 175.4.50.58
```


`xelatex-all`
```bash
sudo apt update

sudo apt install texlive-full

xelatex --version
```

```bash
# 用符号链接命令启用配置
sudo ln -s /etc/nginx/sites-available/my-site.conf /etc/nginx/sites-enabled/my-site.conf

# 想禁用时只要删除对应符号链接，而不是直接删掉原配置文件
sudo rm /etc/nginx/sites-enabled/my-site.conf
```
`Nginx 运行在 www-data 或 nginx 用户下，它默认没有权限访问 /home/ubuntu/ 目录。需要确保 Nginx 对该路径有读取和执行权限。`
```bash
# 允许其他用户（包括 www-data）进入 ubuntu 及其子目录
sudo chmod +x /home/ubuntu
sudo chmod +x /home/ubuntu/miniP-backend
```

`/etc/nginx/sites-available/default`
```Perl
server {
    listen 80;
    server_name mini.csxhcloud.com;

    location /device-api/ {
        proxy_pass http://127.0.0.1:8001/api/;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 60s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        proxy_buffering off;
    }

    location / {
        proxy_pass http://127.0.0.1:8000/;
    
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    
        limit_rate_after 3m;
        limit_rate 300k;
    }

}
```

```Perl
server {
    listen 80;
    listen [::]:80;

    server_name 175.4.50.58;

    # Let's Encrypt HTTP-01 challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    # 其他 HTTP 请求跳转 HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}


server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name 175.4.50.58;

    ssl_certificate /etc/letsencrypt/live/175.4.50.58/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/175.4.50.58/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8080;

        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```
