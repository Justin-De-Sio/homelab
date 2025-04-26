# 🎬 Kubernetes Media Center Stack

Infrastructure de centre multimédia auto-hébergé déployée sur Kubernetes.  
Ce projet regroupe Jellyfin, qBittorrent (avec VPN), Radarr, Sonarr, Jackett, exposés via MetalLB, et utilisant des volumes persistants montés localement. Il met l’accent sur **la vie privée, l’automatisation, et la clarté de l’architecture**.

---

## 🗂️ Sommaire

- [Architecture générale](#architecture-générale)
- [Stack applicative](#stack-applicative)
- [Stockage persistant](#stockage-persistant)
- [VPN avec qBittorrent](#vpn-avec-qbittorrent)
- [Services LoadBalancer (MetalLB)](#services-loadbalancer-metallb)
- [Secrets & sécurité](#secrets--sécurité)
- [Utilisation & déploiement](#utilisation--déploiement)
- [Améliorations futures](#améliorations-futures)

---

## 🧱 Architecture générale

```
Namespace: media
  ├── Jellyfin        -> Streaming local
  ├── qBittorrentVPN  -> Téléchargement via VPN
  ├── Jackett         -> Indexeur torrents
  ├── Radarr          -> Gestion des films
  ├── Sonarr          -> Gestion des séries
Stockage:
  ├── Configs         -> /var/mnt/media/configs/
  ├── Downloads       -> /var/mnt/media/downloads/
  └── Videos/TV       -> /var/mnt/media/videos/
Exposition:
  ├── LoadBalancer IPs via MetalLB
  └── Accès local HTTP
```

---

## 🧩 Stack applicative

| Service        | Image                        | Port | LoadBalancer IP | Description                         |
|----------------|------------------------------|------|------------------|-------------------------------------|
| Jellyfin       | `jellyfin/jellyfin`          | 8096 | `192.168.1.2`    | Streaming local                     |
| Radarr         | `linuxserver/radarr`         | 7878 | `192.168.1.4`    | Téléchargement automatique de films |
| Sonarr         | `linuxserver/sonarr`         | 8989 | `192.168.1.5`    | Téléchargement automatique de séries |
| Jackett        | `linuxserver/jackett`        | 9117 | `192.168.1.6`    | Fournisseur de sources torrents     |
| qBittorrentVPN | `binhex/arch-qbittorrentvpn` | 8081 | `192.168.1.7`    | Client torrent avec VPN obligatoire |

---

## 💾 Stockage persistant

Volumes manuels montés en `hostPath` (non cloud).  
> Tous les PVC utilisent `storageClassName: manual` et la `reclaimPolicy: Retain`.

| Volume              | Monté dans les containers            | Utilisé par            |
|---------------------|--------------------------------------|------------------------|
| `media-videos`      | `/data/videos`, `/tv`, `/movies`     | Jellyfin, Sonarr, Radarr |
| `media-downloads`   | `/data`, `/downloads`                | qBittorrent, Radarr, Sonarr |
| `*-config`          | `/config`                            | Tous les services       |

---

## 🔐 VPN avec qBittorrent

qBittorrent est encapsulé dans un conteneur avec **OpenVPN obligatoire** via un fichier `.ovpn` HotspotShield, injecté sous forme de secret.

### 🧷 Secret utilisé

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: qbittorrentvpn-secret
type: Opaque
stringData:
  VPN_USER: "<ton_login>"
  VPN_PASS: "<ton_mot_de_passe>"
  custom.ovpn: |
    # contenu complet du fichier .ovpn (avec <cert>, <key>, <ca>)
```

### 🧱 Montage dans le conteneur

- Le `.ovpn` est monté en tant que fichier unique via `subPath` :
  ```yaml
  mountPath: /config/openvpn/custom.ovpn
  subPath: custom.ovpn
  ```

- L’image détecte ce fichier car `VPN_PROV=custom` est défini :
  ```yaml
  - name: VPN_PROV
    value: "custom"
  ```

---

## 🌐 Services LoadBalancer (MetalLB)

Chaque service est exposé via un `Service` de type `LoadBalancer` avec une IP locale fixe (via MetalLB) :

| App         | IP              | Accessible à… |
|-------------|------------------|----------------|
| Jellyfin    | `192.168.1.2`    | http://192.168.1.2 |
| Radarr      | `192.168.1.4`    | http://192.168.1.4 |
| Sonarr      | `192.168.1.5`    | http://192.168.1.5 |
| Jackett     | `192.168.1.6`    | http://192.168.1.6 |
| qBittorrent | `192.168.1.7`    | http://192.168.1.7 |

> ℹ️ Tous les services utilisent le port 80 côté cluster, mappé vers leur port d’écoute interne.

---

## 🔒 Secrets & sécurité

- Les credentials VPN sont stockés dans un secret Kubernetes (`Opaque`)
- Le fichier `.ovpn` est injecté directement dans ce secret (clé : `custom.ovpn`)
- Le montage se fait proprement via `subPath`, évitant tout conflit
- La variable `VPN_PROV` est obligatoire pour l’image utilisée (binhex/qbittorrent)

---

## ✨ Améliorations futures

- ✅ Intégration HTTPS via Ingress + Cert-Manager
- 🔐 Authentification via Authelia ou Keycloak
- 📈 Monitoring avec Prometheus/Grafana
