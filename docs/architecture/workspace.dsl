workspace "990prep" "C4 Architecture Model for 990prep - Form 990 Preparation SaaS" {

    !identifiers hierarchical

    model {
        # ═══════════════════════════════════════════════════════════
        # LEVEL 1: SYSTEM CONTEXT
        # ═══════════════════════════════════════════════════════════

        # People/Actors
        nonprofitStaff = person "Nonprofit Staff" "Executive directors and finance staff at nonprofit organizations who need to file Form 990" "User"
        accountant = person "Accountant/CPA" "Tax professionals who prepare Form 990 returns for nonprofit clients" "User"

        # External Systems
        irs = softwareSystem "IRS" "Internal Revenue Service - receives Form 990 filings" "External System"
        stripe = softwareSystem "Stripe" "Payment processing platform for subscription billing" "External System"
        supabase = softwareSystem "Supabase" "Backend-as-a-Service providing PostgreSQL database and authentication" "External System"
        posthog = softwareSystem "PostHog" "Product analytics and feature flag platform" "External System"
        tiktok = softwareSystem "TikTok Ads" "Advertising platform for conversion tracking" "External System"
        gitlab = softwareSystem "GitLab Registry" "Container registry hosting Docker images" "External System"

        # The 990prep System
        nineNineZeroPrep = softwareSystem "990prep" "SaaS platform that helps nonprofits and accountants prepare and file IRS Form 990 tax returns" {

            # ═══════════════════════════════════════════════════════════
            # LEVEL 2: CONTAINERS
            # ═══════════════════════════════════════════════════════════

            webApp = container "Web Application" "Provides Form 990 preparation UI, data entry wizards, and document management" "SvelteKit / Node.js" "Web Browser"

            api = container "API Layer" "Handles business logic, form validation, and orchestrates external service calls" "SvelteKit Server / Node.js" "API"

            # ═══════════════════════════════════════════════════════════
            # LEVEL 3: COMPONENTS (within API Layer)
            # ═══════════════════════════════════════════════════════════

            api -> supabase "Reads/writes organization data, form drafts, user accounts" "HTTPS/PostgreSQL"
        }

        # ═══════════════════════════════════════════════════════════
        # RELATIONSHIPS - Context Level
        # ═══════════════════════════════════════════════════════════

        # User interactions
        nonprofitStaff -> nineNineZeroPrep "Prepares and submits Form 990"
        accountant -> nineNineZeroPrep "Manages client 990 filings"

        # System integrations
        nineNineZeroPrep -> irs "Submits completed Form 990 (future e-file)" "HTTPS"
        nineNineZeroPrep -> stripe "Processes subscription payments" "HTTPS/API"
        nineNineZeroPrep -> supabase "Stores data and handles auth" "HTTPS"
        nineNineZeroPrep -> posthog "Sends analytics events" "HTTPS"
        nineNineZeroPrep -> tiktok "Sends conversion pixels" "HTTPS"
        gitlab -> nineNineZeroPrep "Deploys container images" "Docker Pull"

        # ═══════════════════════════════════════════════════════════
        # RELATIONSHIPS - Container Level
        # ═══════════════════════════════════════════════════════════

        nonprofitStaff -> nineNineZeroPrep.webApp "Uses" "HTTPS"
        accountant -> nineNineZeroPrep.webApp "Uses" "HTTPS"

        nineNineZeroPrep.webApp -> nineNineZeroPrep.api "Makes API calls" "HTTPS/JSON"
        nineNineZeroPrep.api -> stripe "Creates checkout sessions, manages subscriptions" "Stripe API"
        nineNineZeroPrep.api -> supabase "CRUD operations on forms, orgs, users" "Supabase Client"
        nineNineZeroPrep.webApp -> posthog "Tracks user behavior" "PostHog JS SDK"
        nineNineZeroPrep.webApp -> tiktok "Fires conversion events" "TikTok Pixel"

        # Deployment model
        production = deploymentEnvironment "Production" {
            deploymentNode "Kubernetes Cluster" "Homelab K8s" "Kubernetes" {
                deploymentNode "app-990prep namespace" "" "Namespace" {
                    deploymentNode "990prep Deployment" "2 replicas" "Deployment" {
                        containerInstance nineNineZeroPrep.webApp
                        containerInstance nineNineZeroPrep.api
                    }
                }

                deploymentNode "flux-system namespace" "" "Namespace" {
                    fluxInfra = infrastructureNode "Flux CD" "GitOps continuous delivery" "Flux"
                }

                deploymentNode "ingress-nginx namespace" "" "Namespace" {
                    ingressInfra = infrastructureNode "Ingress Controller" "Routes external traffic" "NGINX"
                }
            }

            deploymentNode "Supabase Cloud" "Managed PostgreSQL" "Supabase" {
                supabaseInstance = softwareSystemInstance supabase
            }

            deploymentNode "Stripe Cloud" "Payment Processing" "Stripe" {
                stripeInstance = softwareSystemInstance stripe
            }
        }
    }

    views {
        # ═══════════════════════════════════════════════════════════
        # LEVEL 1: SYSTEM CONTEXT DIAGRAM
        # ═══════════════════════════════════════════════════════════
        systemContext nineNineZeroPrep "SystemContext" {
            include *
            autoLayout tb
            title "990prep - System Context (Level 1)"
            description "Shows 990prep and its relationships with users and external systems"
        }

        # ═══════════════════════════════════════════════════════════
        # LEVEL 2: CONTAINER DIAGRAM
        # ═══════════════════════════════════════════════════════════
        container nineNineZeroPrep "Containers" {
            include *
            autoLayout tb
            title "990prep - Container Diagram (Level 2)"
            description "Shows the containers that make up 990prep"
        }

        # ═══════════════════════════════════════════════════════════
        # DEPLOYMENT DIAGRAM
        # ═══════════════════════════════════════════════════════════
        deployment nineNineZeroPrep "Production" "ProductionDeployment" {
            include *
            autoLayout tb
            title "990prep - Production Deployment"
            description "Shows how 990prep is deployed in the Kubernetes homelab"
        }

        # ═══════════════════════════════════════════════════════════
        # STYLING
        # ═══════════════════════════════════════════════════════════
        styles {
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "User" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #1168BD
                color #ffffff
            }
            element "External System" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Web Browser" {
                shape WebBrowser
                background #438DD5
                color #ffffff
            }
            element "API" {
                shape Hexagon
                background #438DD5
                color #ffffff
            }
            element "Database" {
                shape Cylinder
                background #438DD5
                color #ffffff
            }
            element "Component" {
                background #85BBF0
                color #000000
            }
            element "Infrastructure Node" {
                background #ffffff
            }
        }

        themes default
    }
}
