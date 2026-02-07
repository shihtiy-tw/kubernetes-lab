# metallb
**Category**: Networking | **Source**: Manifest | **Platform**: Kind
## Overview
LoadBalancer implementation for bare metal/Kind.
## Quick Start
```bash
# Get Docker network range first
docker network inspect kind | jq '.[0].IPAM.Config[0].Gateway'
./install.sh --ip-range 172.18.255.200-172.18.255.250
```
## See Also
- [MetalLB](https://metallb.universe.tf/)
