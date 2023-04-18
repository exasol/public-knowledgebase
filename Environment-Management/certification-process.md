# Certification Process 
## Background

Exasol is designed for high-performance analytics and has certain requirements on the used hardware. General requirements and a minimal configuration are described in the article [system_requirements](https://docs.exasol.com/administration/on-premise/installation/system_requirements.htm). A list of standard and certified hardware is found [here](https://community.exasol.com/t5/certified-hardware-list/tkb-p/certified_HW)

Exasol clusters are composed of one or more database nodes and at least one management node (called "license server"). Database nodes are the powerhouse of a cluster and operate both the Exasol Database instances as well as the EXAStorage volumes.  

Database nodes are expected to be equipped with homogeneous hardware. Exasol and EXAStorage are designed and optimized to distribute processing load and database payload equally across the cluster. Odd hardware (especially differences in RAM and disk sizes) may cause undesired effects from poor performance to service disruptions.

The same applies to any sort of shared environments like AWS, a combination of blades with SAN, a virtual environment with shared resources beneath. Exasol has no concept for concurrently shared, dynamically varying resources.

We strongly encourage customers to use standard rack-mount server hardware with locally attached storage.

If you intend to deploy Exasol in a non-certified environment, it will need to undergo a certification process by Exasol to determine the extent of support provided for Exasol products in the projected environment. Please be aware that the certification process will be a subject of extra charge.

## Explanation

## Certification process

Certification of a cluster setting (hardware, network and specific setup) usually includes functional-, stress- and performance tests.

The process is iterative and individual to the setting.

### Prerequisites

The customer provides Exasol with a reference-environment consisting of at least three nodes.

### Functional tests

* Installation of Exasuite and basic configuration
* Familiarization with hardware and infrastructure (e.g. BIOS options for best practice advice)
* Checks on the functionality of the hardware (what happens if a component fails, if applicable)

### Stress tests

Stress and burn-in tests set the major hardware subsystems (CPU, RAM, disk) under heavy load to examine their stability and quality.

### Performance tests

Exasol carries out disk and network tests to get an impression of the basic performance.

In addition, database level tests will be executed (for example, TPC-H benchmarks of appropriate scale factors).

Please note that the benchmarks don't allow statements about the performance for a specific scenario in every-day use. We hence encourage customers to develop a benchmark to baseline and monitor the underlying architecture. Such a benchmark should consist of typical writing statements and reading queries based on a fixed dataset.

## Certification results

The new certified hardware will be added to the list of certified [hardware](https://community.exasol.com/t5/certified-hardware-list/tkb-p/certified_HW)

In the cases of a shared or virtual environment, Exasol recognizes errors as defined in our terms and conditions only if they are reproducible on the standard hardware. Moreover, as it is not possible for us to properly analyze performance issues in a shared environment, they may not be recognized as errors. Please be aware, the same applies to the incident management: Exasol operation engineers will handle incidents from the operating system level only.

