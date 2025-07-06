# 🏠 Homelab GitOps Infrastructure

[![Flux](https://img.shields.io/badge/GitOps-Flux-5C7CFA.svg)](https://fluxcd.io/)
[![SOPS](https://img.shields.io/badge/Secrets-SOPS-orange.svg)](https://github.com/mozilla/sops)
[![Renovate](https://img.shields.io/badge/Dependencies-Renovate-1f8ceb.svg)](https://renovatebot.com/)
[![Kubernetes](https://img.shields.io/badge/Platform-Kubernetes-326CE5.svg)](https://kubernetes.io/)

A production-ready, cloud-native homelab infrastructure managed entirely through GitOps principles using Flux CD. This repository contains the complete configuration for a Kubernetes-based homelab running media services, cloud storage, monitoring, and more.

> **🎯 This is a reference implementation showcasing enterprise-grade practices in a homelab environment.**

## 📋 Quick Overview

| **Component** | **Technology** | **Purpose** |
|---------------|----------------|-------------|
| **GitOps** | Flux CD + SOPS | Declarative infrastructure management |
| **Storage** | Longhorn | Distributed block storage with automated backups |
| **Database** | CloudNative PostgreSQL | Managed PostgreSQL with HA and continuous backup |
| **Monitoring** | Prometheus + Grafana | Comprehensive observability stack |
| **Media** | Jellyfin + *Arr Stack | Complete media automation and streaming |
| **Networking** | Traefik + Cloudflare | SSL termination and secure external access |
| **Security** | cert-manager + age encryption | Automated certificates and encrypted secrets |

## ️ Architecture

### 🗺️ System Architecture

```mermaid
graph TB
    subgraph "🌐 External Access"
        CF[Cloudflare Tunnels]
        DNS[DNS: justindesio.com]
        LOCAL[Local DNS: *.justindesio.com → 192.168.1.x]
    end
    
    subgraph "📦 GitOps Repository"
        REPO[GitHub: Justin-De-Sio/homelab]
        FLUX[Flux CD]
        SOPS[SOPS Secrets]
        RENO[Renovate]
    end
    
    subgraph "☸️ Kubernetes Cluster"
        subgraph "Infrastructure"
            TRAF[Traefik Ingress]
            CERT[cert-manager]
            LONG[Longhorn Storage]
            CNPG[CloudNative-PG]
        end
        
        subgraph "Applications"
            subgraph "Media Stack"
                JELLY[Jellyfin]
                SONARR[Sonarr]
                RADARR[Radarr]
                QBIT[qBittorrent]
                PROWL[Prowlarr]
                JACK[Jackett]
                NZB[NZBGet]
            end
            
            subgraph "Cloud Services"
                NC[Nextcloud]
                LINK[Linkding]
                HOM[Homarr]
                PGA[pgAdmin]
            end
            
            subgraph "Monitoring"
                PROM[Prometheus]
                GRAF[Grafana]
            end
        end
    end
    
    subgraph "💾 External Storage"
        B2[Backblaze B2<br/>Backup Storage]
    end
    
    %% External Access Flow
    DNS --> CF
    LOCAL --> TRAF
    CF --> TRAF
    
    %% GitOps Flow
    REPO --> FLUX
    RENO --> FLUX
    FLUX --> SOPS
    FLUX --> Infrastructure
    FLUX --> Applications
    
    %% Infrastructure Flow
    CERT --> TRAF
    TRAF --> Applications
    
    %% Backup Flow
    LONG --> B2
    CNPG --> B2
    
    %% Monitoring Flow
    PROM --> GRAF
```

### 📁 Repository Structure
```
homelab/
├── apps/                    # Application definitions
│   ├── base/               # Base configurations
│   └── production/         # Production overlays
├── infrastructure/         # Platform components
│   └── controllers/        # Infrastructure controllers
├── monitoring/            # Observability stack
├── clusters/              # Cluster configurations
│   └── homelab/          # Main cluster config
└── renovate.json         # Dependency automation
```

## Service Access
### 🌐 External Access
Secure external access via Cloudflare tunnels:
- `linkding.justindesio.com` - Bookmarks
- `cloud.justindesio.com` - Nextcloud  
- `video.justindesio.com` - Jellyfin
- `tv.justindesio.com` - Jellyfin Vue
- `dashboard.justindesio.com` - Homarr

### 🏠 Local Access

All services accessible via **Traefik ingress** with SSL certificates:

#### 📱 Applications
- `linkding.home.justindesio.com` - Bookmark manager (local-only)
- `jellyfin.justindesio.com` - Media server
- `cloud.justindesio.com` - Nextcloud file sync

#### 🎬 Media Management
- `sonarr.justindesio.com` - TV series automation
- `radarr.justindesio.com` - Movie automation  
- `prowlarr.justindesio.com` - Indexer management
- `jackett.justindesio.com` - Torrent trackers
- `qbittorrent.justindesio.com` - Torrent client
- `nzbget.justindesio.com` - Usenet downloader

#### ⚙️ Infrastructure
- `monitoring.justindesio.com` - Grafana dashboards
- `longhorn.justindesio.com` - Storage management
- `pgadmin.justindesio.com` - Database administration

## 🔄 Backup & Recovery

### **Storage (Longhorn)**
- **Daily** (2 AM, 7-day retention) + **Weekly** (Sunday 1 AM, 4-week retention) + **Monthly** (1st midnight, 6-month retention)
- **Snapshot cleanup** daily at 3 AM (7-day retention)
- Automated backups to **Backblaze B2** for `critical-data` volumes

### **Databases (CloudNative-PG)**
- **Continuous WAL streaming** with gzip compression to Backblaze B2
- **Linkding:** 3-day retention | **Nextcloud:** 7-day retention
- **Hourly WAL archiving** for point-in-time recovery