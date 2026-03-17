# Issue SSL certificates with `certbot`

This guide goes through the setup process of `certbot` with nginx already installed.

## Installation

```sh
sudo apt install certbot python3-certbot-nginx
```

## Nginx configuration

To avoid any issues, keep the configuration file as simple as possible.

```nginx
server {
    server_name example.com www.example.com;
    root /var/www/example.com;
    access_log /var/log/nginx/example.com.access.log;

    # Only necessary for issuing SSL certificates with certbot.
    location / {
      # First attempt to serve request as file, then
      # as directory, then fall back to displaying a 404.
      try_files $uri /index.html =404;
    }
}
```

Test the configuration and reload the Nginx service:

```sh
sudo nginx -s reload

# Or by doing it separately
sudo nginx -t && sudo systemctl reload nginx
```

Test if domain is available:

```sh
echo '<h1>Success</h1>' > /var/www/example.com/test.html
curl -I http://example.com/test.html
```

Proceed, if the HTTP response code is 200. Otherwise, check file permissions
and modify accordingly.

**File Permission Example**

```sh
sudo chgrp -R www-data /var/www/example.com && sudo chmod 2750 "$_"
```

## Certbot setup

First, let's test if generating SSL certificates will succeed with the `certonly`
subcommand and `--dry-run` flag. This also avoid rate limit issues:

```sh
sudo certbot certonly --nginx -d exmaple.com,www.exmaple.com --dry-run
```

If the tests succeeded, we can generate the certificates:

```sh
sudo certbot --nginx --agree-tos --redirect --hsts --staple-ocsp -d example.com,www.example.com
```

-  `--nginx`: Use the Nginx authenticator and installer
-  `--agree-tos`: Agree to Let’s Encrypt terms of service
-  `--redirect`: Add 301 redirect.
-  `--uir`: Add the “Content-Security-Policy: upgrade-insecure-requests” header to every HTTP response.
-  `--hsts`: Add the Strict-Transport-Security header to every HTTP response.
-  `--must-staple`: ~~Adds the OCSP Must Staple extension to the certificate.~~ (obsolete[^1])
-  `--staple-ocsp`: Enables OCSP Stapling.[^2]
-  `-d` flag is followed by a list of domain names, separated by comma.
-  `--email`: Email used for registration and recovery contact.

> [!NOTE]
> I initially ran this command with the `--uir` flag, which was not supported by nginx. Since the certificates were successfully generated, I had to ran `sudo certbot install --cert-name example.com` to finish the setup.

### Automatic certificate renewal

Certbot runs a renewal process twice daily using a systemd timer or a cron job, depending on your distribution and Certbot installation method. It attempts to renew certificates that are expiring within 30 days.

To verify if Certbot is using a systemd timer:

```sh
systemctl list-timers | grep certbot
```

You should see something like this:

```
Sat 2024-11-25 03:30:00 UTC  13h left  certbot.timer
```
If you installed Certbot using apt or another package manager and systemd timers are not in use, a cron job might have been created. Check for it with:

```sh
cat /etc/cron.d/certbot
```
#### Testing Renewal

You can manually test the renewal process to ensure everything is working as expected:

```sh
sudo certbot renew --dry-run
```

### Troubleshooting

#### DNS

If the tests fail, verify your DNS records:

```sh
dig www.exmaple.com A +short
dig exmaple.com A +short

# The output should match with the IP address of the server:
curl -4 icanhazip.com
```
To also check which name servers are used, run:

```sh
dig example.com NS +short
```

#### Remove existing certificates

List existing certificates and delete:

```sh
sudo certbot certificates
sudo certbot delete --cert-name example.com
```

---

**References**

- https://eff-certbot.readthedocs.io/en/stable/index.html
- https://chatgpt.com/c/674229b1-f93c-8003-b83f-38001a75d1aa
- https://www.linuxbabe.com/ubuntu/nginx-lets-encrypt-ubuntu-certbot
- https://serverfault.com/questions/896711/how-to-totally-remove-a-certbot-created-ssl-certificate

**Footnotes**

[^1]: Omit `--must-staple`; OCSP must-staple extension is no longer available (https://letsencrypt.org/2024/12/05/ending-ocsp)
[^2]: The `--staple-oscp` flag should or must also be omitted, but not completely sure, check next time.
