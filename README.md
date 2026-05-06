# 🛒 Shell Ecommerce Project

A fully automated, shell-scripted deployment of the **RoboShop** ecommerce application on AWS EC2. This project provisions infrastructure and configures each microservice using Bash scripts, with systemd integration for process management.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Services](#services)
- [Logging](#logging)
- [Configuration](#configuration)
- [Notes](#notes)

---

## Overview

This project automates the end-to-end deployment of a multi-tier ecommerce application (RoboShop) using pure Bash scripting. It provisions AWS EC2 instances, configures DNS via Route 53, and sets up each microservice independently — from databases to the frontend reverse proxy.

Each service script handles:
- Dependency installation
- Application artifact download and extraction
- systemd service registration and startup
- Validation with colored output and structured logging

---

## Architecture

```
                        Internet
                            |
                       [Frontend]
                      Nginx Reverse Proxy
                            |
          ┌─────────────────┼────────────────────┐
          |                 |                     |
      [Catalogue]        [User]               [Cart]
       Node.js           Node.js             Node.js
          |                 |                     |
       [MongoDB]         [Redis]              [MySQL]
                                                  |
                                           [Shipping]   [Payment]
                                             Java          Python
                                                  |
                                           [RabbitMQ]   [Dispatch]
                                                          Golang
```

All backend services communicate via private DNS (e.g., `catalogue.ellamma.fun`) registered in Route 53. The frontend is exposed publicly.

---

## Tech Stack

| Layer        | Technology           |
|--------------|----------------------|
| Frontend     | Nginx 1.24           |
| Catalogue    | Node.js 20 + MongoDB |
| User         | Node.js 20 + MySQL   |
| Cart         | Node.js 20 + Redis   |
| Shipping     | Java (Maven)         |
| Payment      | Python               |
| Dispatch     | Golang               |
| Message Queue| RabbitMQ             |
| Database     | MongoDB, MySQL, Redis|
| Infra        | AWS EC2, Route 53    |
| Scripting    | Bash                 |

---

## Prerequisites

- AWS CLI configured with appropriate IAM permissions (EC2, Route 53)
- A registered domain with a Route 53 hosted zone
- An EC2 AMI ID compatible with RHEL/Amazon Linux (DNF-based)
- A security group ID allowing required ports
- Root/sudo access on target EC2 instances

---

## Project Structure

```
Shell-Ecommerce-Project/
├── create-ec2.sh          # Provisions EC2 instances and registers DNS in Route 53
│
├── frontend.sh            # Installs and configures Nginx, deploys frontend assets
├── nginx.conf             # Custom Nginx reverse proxy configuration
│
├── catalogue.sh           # Node.js catalogue service + MongoDB data load
├── catalogue.service      # systemd unit for catalogue
│
├── user.sh                # Node.js user service + MySQL schema setup
├── user.service           # systemd unit for user service
│
├── cart.sh                # Node.js cart service + Redis connection
├── cart.service           # systemd unit for cart
│
├── shipping.sh            # Java shipping service + MySQL schema
├── shipping.service       # systemd unit for shipping
│
├── payment.sh             # Python payment service
├── payment.service        # systemd unit for payment
│
├── dispatch.sh            # Golang dispatch service
├── dispatch.service       # systemd unit for dispatch
│
├── mongodb.sh             # MongoDB installation and configuration
├── mongo.repo             # MongoDB DNF repository definition
│
├── mysql.sh               # MySQL installation and configuration
│
├── redis.sh               # Redis installation and configuration
│
├── rabbitmq.sh            # RabbitMQ installation and configuration
└── rabbitmq.repo          # RabbitMQ DNF repository definition
```

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/Shankar-codes/Shell-Ecommerce-Project.git
cd Shell-Ecommerce-Project
```

### 2. Provision EC2 Instances

Use `create-ec2.sh` to launch EC2 instances and register them in Route 53. Pass service names as arguments:

```bash
bash create-ec2.sh mongodb mysql redis rabbitmq catalogue user cart shipping payment dispatch frontend
```

This will:
- Launch a `t3.micro` instance per service using the configured AMI and security group
- Register each service with a private DNS record (e.g., `catalogue.ellamma.fun`)
- Register the `frontend` with a public IP at the apex domain

> **Before running**, update the following variables in `create-ec2.sh`:
> ```bash
> AMI_ID="<your-ami-id>"
> SG_ID="<your-security-group-id>"
> ZONE_ID="<your-route53-hosted-zone-id>"
> DOMAIN_NAME="<your-domain>"
> ```

### 3. Deploy Each Service

SSH into each respective EC2 instance and run the corresponding script as root. For example, to set up the catalogue service:

```bash
sudo bash catalogue.sh
```

**Recommended deployment order:**

```
1. mongodb.sh
2. mysql.sh
3. redis.sh
4. rabbitmq.sh
5. catalogue.sh
6. user.sh
7. cart.sh
8. shipping.sh
9. payment.sh
10. dispatch.sh
11. frontend.sh
```

---

## Services

### Frontend (`frontend.sh`)
Installs Nginx 1.24, downloads the RoboShop frontend artifact from S3, deploys it to `/usr/share/nginx/html`, and applies the custom reverse proxy config.

### Catalogue (`catalogue.sh`)
Installs Node.js 20, creates a `roboshop` system user, deploys the catalogue app to `/app`, installs npm dependencies, and seeds MongoDB with product data if not already loaded.

### User (`user.sh`)
Similar to catalogue but connects to MySQL for user data persistence.

### Cart (`cart.sh`)
Node.js service that manages shopping cart state via Redis.

### Shipping (`shipping.sh`)
Java-based service for shipping calculations. Connects to MySQL.

### Payment (`payment.sh`)
Python-based payment processing service. Uses RabbitMQ for async order messaging.

### Dispatch (`dispatch.sh`)
Golang-based order dispatch service. Consumes messages from RabbitMQ.

### Databases
- **MongoDB** (`mongodb.sh`): Product catalogue storage
- **MySQL** (`mysql.sh`): User and shipping data
- **Redis** (`redis.sh`): Session/cart caching
- **RabbitMQ** (`rabbitmq.sh`): Async message queue for payment/dispatch

---

## Logging

All scripts write structured logs to:

```
/var/log/Shell-Ecommerce-Project/<script-name>.log
```

Console output is color-coded:
- 🔴 **Red** — Failure
- 🟢 **Green** — Success
- 🟡 **Yellow** — Skipped (already configured)

Every step is validated; the script exits immediately on any failure, making it easy to debug.

---

## Configuration

Domain-specific settings are hardcoded in the scripts. Before deploying, update the domain references to match your Route 53 hosted zone:

| Variable / Hostname       | File(s)                          | Description                    |
|--------------------------|----------------------------------|--------------------------------|
| `ellamma.fun`            | `create-ec2.sh`, `catalogue.sh`  | Base domain name               |
| `mongodb.ellamma.fun`    | `catalogue.sh`, `user.sh`        | MongoDB private DNS endpoint   |
| `mysql.ellamma.fun`      | `user.sh`, `shipping.sh`         | MySQL private DNS endpoint     |
| `redis.ellamma.fun`      | `cart.sh`                        | Redis private DNS endpoint     |
| `rabbitmq.ellamma.fun`   | `payment.sh`, `dispatch.sh`      | RabbitMQ private DNS endpoint  |

---

## Notes

- All scripts must be executed as **root** (`sudo` or `su -`).
- Scripts are idempotent where possible — e.g., user creation and DB seeding are skipped if already done.
- Artifacts are pulled from `roboshop-artifacts.s3.amazonaws.com` at deploy time.
- Each service is registered as a **systemd** unit, ensuring it auto-starts on reboot.
- The `roboshop` system user (`/app`, no login shell) runs all application processes.

---

## Author

**Shankar** — [GitHub](https://github.com/Shankar-codes)
