# 🎬 Kubernetes Media Center Stack

Infrastructure de centre multimédia auto-hébergé déployée sur Kubernetes.  
Ce projet regroupe Jellyfin, qBittorrent, Radarr, Sonarr, Jackett, exposés via MetalLB, et utilisant des volumes persistants montés localement. Il met l'accent sur **la vie privée, l'automatisation, et la clarté de l'architecture**.

---

## FluxCD Deployment Structure

This media stack follows FluxCD best practices:

- **Base**: Contains the core Kubernetes manifests for all media applications
- **Staging/Production**: Environment-specific configurations that inherit from base
- **Kustomize**: Used for configuration variants and environment overlays
- **GitOps**: All changes are declarative and managed through Git

