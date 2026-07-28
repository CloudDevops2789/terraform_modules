# AWS Managed Microsoft AD Module

## Overview

This module provisions an AWS Managed Microsoft Active Directory within an existing Amazon VPC.

AWS Managed Microsoft AD is a fully managed Microsoft Active Directory service that provides domain services, Kerberos authentication, LDAP, Group Policy, DNS, and domain join capabilities without requiring administrators to deploy or maintain Domain Controllers.

Within the Isolated Recovery Environment (IRE), this directory provides the **Recovery Management Forest**, supporting administrative identity, automation, and shared platform services while remaining isolated from restored production workloads.

---

## Architecture

```

Recovery Access VPC
│
│ AWS Client VPN
│
▼
Core Recovery VPC
├──────────────────────────────────────┐
│ AWS Managed Microsoft AD             │
│ Route 53 Resolver                    │
│ Recovery Automation                  │
│ Shared Platform Services             │
└──────────────────────────────────────┘
│
▼
Protected Data VPC
┌──────────────────────────────────────┐
│ Restored Windows Servers             │
│ Restored Production Active Directory │
└──────────────────────────────────────┘


```
          Foundation
         ┌─────────────────────────────┐
         │ VPC / TGW / Security Groups │
         └──────────────┬──────────────┘
                        │
                        ▼
                  Identity Layer
         ┌─────────────────────────────┐
         │ AWS Managed Microsoft AD    │ 
         └──────────────┬──────────────┘
                        │
                        ▼
                    DNS Layer
         ┌─────────────────────────────┐
         │ Route 53 Resolver           │
         └──────────────┬──────────────┘
                        │
          ┌─────────────┼──────────────┐
          ▼             ▼              ▼
      Windows EC2   FSx Windows    Automation
          │             │              │
          └─────────────┼──────────────┘
                        ▼
              Recovery Validation