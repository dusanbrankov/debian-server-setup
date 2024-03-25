#!/bin/bash

# https://contabo.com/blog/how-to-setup-a-software-firewall-in-linux-and-windows/

# Delete the current firewall setup:
iptables -F

# Define default rules for all chains:
iptables -P INPUT DROP
iptables -P FORWARD DROP

# Allow incoming/outgoing localhost frames for tests (e.g.  Webserver, Mailserver):
# iptables -A INPUT -d 127.0.0.1 -j ACCEPT
# iptables -A OUTPUT -s 127.0.0.1 -j ACCEPT

# Allow loopback frames for the internal process management:
iptables -A INPUT -i lo -j ACCEPT

# Allow incoming/outgoing related-established connections:
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# Allow incoming PING-Requests:
iptables -A INPUT -p icmp -j ACCEPT

# Allow incoming SSH connections: 
iptables -A INPUT -p tcp --dport 836 -j ACCEPT

# Allow incoming HTTP/HTTPS requests:
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Allow incoming DNS requests:
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -j ACCEPT

# The next time your system starts, iptables will automatically reload the firewall rules:
/sbin/iptables-save
