# 990prep Architecture Overview

## Purpose

990prep is a SaaS platform that helps nonprofit organizations and their accountants prepare and file IRS Form 990 tax returns. The platform simplifies the complex process of annual tax compliance for 501(c)(3) organizations.

## System Context

### Users

| Actor | Description |
|-------|-------------|
| **Nonprofit Staff** | Executive directors and finance staff who need to file Form 990 for their organization |
| **Accountants/CPAs** | Tax professionals who prepare Form 990 returns on behalf of nonprofit clients |

### External Dependencies

| System | Purpose | Integration Method |
|--------|---------|-------------------|
| **Supabase** | PostgreSQL database + authentication | Supabase Client SDK |
| **Stripe** | Subscription billing and payments | Stripe API |
| **PostHog** | Product analytics and feature flags | PostHog JS SDK |
| **TikTok Ads** | Conversion tracking for marketing | TikTok Pixel |
| **IRS** | Form 990 submission (future e-file) | HTTPS |

## Container Architecture

990prep uses a modern SvelteKit monolith that serves both the web UI and API:

```
┌─────────────────────────────────────────┐
│            990prep System               │
│  ┌─────────────────────────────────┐   │
│  │      Web Application            │   │
│  │  (SvelteKit SSR + Client)       │   │
│  └──────────────┬──────────────────┘   │
│                 │                       │
│  ┌──────────────▼──────────────────┐   │
│  │        API Layer                │   │
│  │   (SvelteKit Server Routes)     │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### Web Application
- **Technology**: SvelteKit with server-side rendering
- **Responsibilities**:
  - Form 990 data entry wizards
  - Document management UI
  - User authentication flows
  - Analytics event tracking

### API Layer
- **Technology**: SvelteKit server routes (Node.js)
- **Responsibilities**:
  - Business logic and form validation
  - Supabase database operations
  - Stripe payment orchestration
  - External service integrations

## Deployment Architecture

990prep runs in a Kubernetes homelab environment using GitOps:

```
┌─────────────────────────────────────────────────────────┐
│                  Kubernetes Cluster                      │
│                                                          │
│  ┌─────────────────┐  ┌─────────────────┐               │
│  │ flux-system     │  │ ingress-nginx   │               │
│  │                 │  │                 │               │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │               │
│  │ │  Flux CD    │ │  │ │   NGINX     │ │               │
│  │ │  (GitOps)   │ │  │ │  Ingress    │ │               │
│  │ └─────────────┘ │  │ └─────────────┘ │               │
│  └─────────────────┘  └────────┬────────┘               │
│                                │                         │
│  ┌─────────────────────────────▼────────────────────┐   │
│  │              app-990prep namespace                │   │
│  │  ┌──────────────────────────────────────────┐    │   │
│  │  │         990prep Deployment               │    │   │
│  │  │            (2 replicas)                  │    │   │
│  │  │  ┌────────────┐  ┌────────────┐         │    │   │
│  │  │  │  Pod 1     │  │  Pod 2     │         │    │   │
│  │  │  │ (Web+API)  │  │ (Web+API)  │         │    │   │
│  │  │  └────────────┘  └────────────┘         │    │   │
│  │  └──────────────────────────────────────────┘    │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
   ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
   │  Supabase   │ │   Stripe    │ │   PostHog   │
   │   Cloud     │ │   Cloud     │ │   Cloud     │
   └─────────────┘ └─────────────┘ └─────────────┘
```

### Key Infrastructure Components

| Component | Namespace | Purpose |
|-----------|-----------|---------|
| **Flux CD** | flux-system | GitOps continuous delivery from this repository |
| **NGINX Ingress** | ingress-nginx | Routes external traffic to services |
| **990prep** | app-990prep | Main application deployment |

## Data Flow

1. **User Request** → NGINX Ingress → 990prep Pod
2. **Authentication** → Supabase Auth (JWT tokens)
3. **Form Data** → SvelteKit API → Supabase PostgreSQL
4. **Payments** → Stripe Checkout Sessions → Stripe API
5. **Analytics** → PostHog JS SDK → PostHog Cloud

## Security Considerations

- All external traffic encrypted via TLS (cert-manager)
- Authentication handled by Supabase (JWT-based)
- Secrets managed via SOPS encryption in Git
- No PII stored in application logs
