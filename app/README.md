# Application Modules

This directory contains application-level modules that deploy on top of the core infrastructure.

## Purpose

Application modules are distinct from infrastructure modules in that they:

- **Deploy applications and services** on existing infrastructure
- **Depend on infrastructure modules** (VPC, EKS, Security)
- **Can be deployed/destroyed independently** without affecting core infrastructure
- **Are environment-specific** and may have different configurations per environment

## Structure

```
app/
├── aws_load_balancer_controller/    # AWS Load Balancer Controller for EKS
│   ├── main.tf                     # Helm deployment with IRSA
│   ├── variables.tf                # Configuration variables
│   ├── outputs.tf                  # Module outputs
│   ├── versions.tf                 # Provider requirements
│   ├── README.md                   # Module documentation
│   └── examples/                   # Usage examples
└── [future-app-modules]/           # Additional application modules
```

## Module Categories

### **Kubernetes Add-ons**
- `aws_load_balancer_controller/` - Application Load Balancer management
- Future: Ingress controllers, service meshes, monitoring

### **Application Services**
- Future: API gateways, databases, caching layers

### **Observability**
- Future: Monitoring, logging, alerting solutions

## Usage Pattern

Application modules are typically used in environment configurations:

```hcl
# infrastructure/environments/dev/main.tf

# 1. Deploy core infrastructure
module "vpc" {
  source = "../../modules/vpc"
  # ...
}

module "eks" {
  source = "../../modules/eks"
  # ...
}

# 2. Deploy applications on infrastructure
module "aws_load_balancer_controller" {
  source = "../../../app/aws_load_balancer_controller"
  
  # Dependencies on infrastructure
  cluster_name = module.eks.cluster_name
  vpc_id       = module.vpc.vpc_id
  
  # Application-specific configuration
  chart_version = "1.8.1"
  replicas      = 2
  
  depends_on = [module.eks]
}
```

## Development Guidelines

### **Creating New Application Modules**

1. **Follow naming convention**: Use descriptive, kebab-case names
2. **Include comprehensive README**: Document purpose, usage, and examples
3. **Implement proper dependencies**: Ensure correct dependency order
4. **Use structured variables**: Group related configuration logically
5. **Provide examples**: Include usage examples and testing configurations

### **Module Dependencies**

Application modules should:
- ✅ **Depend on infrastructure modules** for foundational resources
- ✅ **Use data sources** to reference existing infrastructure when needed
- ✅ **Implement proper `depends_on`** to ensure correct deployment order
- ✅ **Be idempotent** and handle updates gracefully

### **Configuration Best Practices**

- Use **environment-specific variables** for configuration
- Implement **resource limits** appropriate for the environment
- Include **monitoring and observability** configuration
- Follow **security best practices** (IRSA, least privilege, etc.)

## Integration with Infrastructure

```
Infrastructure (Core)           Application (On Top)
├── VPC (networking)           ├── Load Balancers
├── EKS (compute)         →    ├── Ingress Controllers
├── Security (access)          ├── Application Services
└── Storage (persistence)      └── Monitoring/Observability
```

Application modules build upon the foundation provided by infrastructure modules, creating a clear separation of concerns and enabling independent lifecycle management.
