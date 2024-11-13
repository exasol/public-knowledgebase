# Virtualisation as platform

## Introduction

Exasol is a high-performance analytic database designed for a shared-nothing architecture that prioritizes redundancy and performance. While modern hypervisors introduce minimal overhead thanks to paravirtualization, there are still key considerations for achieving optimal Exasol performance in virtualized environments.

## Key Considerations and Recommendations

### Dedicated Resources

*	**CPU:** Assign dedicated CPU cores to Exasol VMs. Avoid CPU oversubscription and, where possible, ensure VMs reside within a single CPU socket (NUMA node) to minimize cross-socket communication overhead. Select vCPUs with comparable performance to physical cores in a bare-metal installation.
*	**RAM:** Allocate dedicated RAM equivalent to what would be used in a physical machine.
*	**Storage:**
    * Prioritize storage solutions that offer performance characteristics similar to local disks used in a bare-metal cluster.
    * Provision dedicated LUNs to each Exasol node, ensuring these LUNs do not share underlying disk arrays.
    * Use low-latency SAN interfaces such as Fibre Channel (FC). NFS is generally not recommended for data disks due to potential performance limitations.
* **Network:** Provide network throughput across VMs that aligns with the capabilities of a physical Exasol cluster. Consider high-bandwidth network interfaces.

### Hypervisor Configuration

*	**Performance Tuning:** Disable any hypervisor-level power saving features that can throttle CPU performance. Configure the hypervisor for maximum performance.
*	**Resource Management:** Ensure that resource oversubscription (CPU, memory) is minimized or avoided, especially for Exasol VMs.
*	**NUMA Awareness:** If possible, configure VMs to remain within a single NUMA socket to reduce latency associated with cross-socket communication.

## Additional Considerations

*	**Virtualization Technology:** Choose a hypervisor that has a proven track record of high-performance I/O and efficient resource management (e.g., VMware vSphere, KVM).
*	**Network Virtualization:** Carefully consider your network virtualization approach (e.g., overlay networks) as it can introduce overhead. Optimize network configuration to minimize latency and maximize throughput.

## Conclusion

By following these recommendations and carefully planning your virtualized Exasol deployment, you can achieve performance levels that are close to, or potentially on par with, a bare-metal Exasol cluster.

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 
