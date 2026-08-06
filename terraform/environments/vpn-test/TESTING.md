# VPN Test Procedure

## Provisioning

- [ ] Create or verify `backend.hcl`
- [ ] Create or verify `terraform.tfvars`
- [ ] Run the required backend initialization command
- [ ] Run `terraform fmt -check -recursive`
- [ ] Run `terraform validate`
- [ ] Review `terraform plan`
- [ ] Confirm there are no unexpected replacement or destroy actions
- [ ] Apply the reviewed plan

## Connectivity validation

- [ ] Wait until the Client VPN endpoint is available
- [ ] Download the Client VPN configuration
- [ ] Connect using the approved client certificate
- [ ] Verify both target-network associations are available
- [ ] Retrieve the management EC2 private IP
- [ ] Ping the management EC2 instance
- [ ] SSH to the management EC2 instance
- [ ] Verify Client VPN connection logs in CloudWatch
- [ ] Confirm the instance has no public IP address

## Idempotency and cleanup

- [ ] Run a second plan and confirm no changes
- [ ] Review a destroy plan
- [ ] Destroy the environment
- [ ] Confirm `terraform state list` is empty
