PolarFire SoC Learning Project
=============================

Overview
--------

This project uses Microchip's Yocto BSP and PolarFire SoC toolchain to build a
learning playground for Yocto, BitBake, board support packages, FPGA
integration, neural network acceleration, and the RISC-V architecture. The
reference target is the PolarFire SoC Discovery Kit, but the flow generalises to
custom boards built around MPFS devices.

Why leverage Microchip's Yocto BSP?
-----------------------------------

- Provides vendor-maintained kernel, U-Boot, and device tree support for the
  PolarFire SoC platform, including clock, DDR, and peripheral bring-up.
- Delivers a validated cross toolchain and sysroots tuned for the MPFS RISC-V
  cores, reducing bootstrap friction compared to rolling a toolchain from
  scratch.
- Ships FPGA-oriented utilities (HSS payload tooling, Libero hooks) that align
  with the Microchip boot architecture.
- Integrates tightly with PolarFire SoC security features, secure boot flows,
  and lifecycle management, which would otherwise demand significant custom
  engineering.

High-Level Architecture
-----------------------

1. **Hardware Layer**
   - PolarFire SoC device with quad RISC-V (U54) application cores and the E51
     monitor core.
   - Discovery Kit carrier board supplying LPDDR4, Gigabit Ethernet, UART,
     and expansion headers (PMOD, mikroBUS) for accelerator I/O.
   - FPGA fabric region programmed with a neural network accelerator (NN
     accelerator), optional DSP blocks, and supporting IP (DMA, AXI interconnect,
     scratchpad RAM).

Target Hardware Specifications
------------------------------

- **SoC**: MPFS095T PolarFire SoC FPGA (≈95K logic elements, 3.8 Mb LSRAM,
  18 Mb uSRAM, 300+ DSP slices) integrating one `E51` monitor core and four
  `U54` 64-bit RISC-V application cores (up to ~667 MHz) with hardware PMP/MMU.
- **Memory**: 1 GB LPDDR4 (32-bit bus) as main memory, 64 MB QSPI NOR flash for
  first-stage boot, and a microSD slot for removable storage or alt rootfs.
- **Connectivity**: Single Gigabit Ethernet port, USB 2.0 OTG (Type-C), three
  UART ports (console + expansion), mikroBUS and dual PMOD headers, plus CAN-FD
  and I²C/SPI general-purpose headers.
- **Clocking & Power**: On-board programmable PLLs and regulators sized for
  FPGA accelerators, powered from 12 V DC or USB-C PD.
- **Debug & Trace**: Dedicated JTAG for MSS and FPGA, on-board USB-to-UART
  bridge, SmartDebug fabric monitor access, and GPIO test headers.

2. **Boot and SoC Management**
   - Hart Software Services (HSS) responsible for loading the FPGA bitstream,
     setting up clocking, and launching the Linux payload on the U54 cores.
   - Optional trusted boot chain leveraging eMMC/QSPI with signed payloads.

3. **Yocto Build System**
   - Base distro: Microchip BSP layers (`meta-microchip`, `meta-polarfire-soc`).
   - Custom layer: `meta-polarfire-nn` extending vendor recipes with accelerator
     drivers, userspace libraries, and example applications.
   - Build configurations: one for developer images (SSH, debug tools) and one
     for deployment images (read-only rootfs, OTA hooks).

4. **Software Stack**
   - Linux kernel from Microchip BSP with device-tree overlays enabling the NN
     accelerator, AXI bridges, DMA engines, and optional DSP soft IP.
   - Userspace components packaged via BitBake: 
     - Accelerator kernel module (out-of-tree if required).
     - Userspace HAL/driver library exposing ioctl or RPC interface.
     - Sample RISC-V applications and Python bindings for inference workflows.
     - Telemetry and diagnostics tools for monitoring accelerator performance.
   - Optional container runtime (Podman) for portable ML workloads.

5. **FPGA & Accelerator Tooling**
   - Libero SoC project describing the accelerator, using DSP slices and
     inference-friendly datapaths.
   - Exported bitstream packaged as an HSS payload, consumed during boot or
     delivered via dynamic partial reconfiguration.
   - Synthesis scripts capture neural network model quantisation and mapping to
     FPGA resources, with optional integration to frameworks (e.g., FINN,
     hls4ml).

6. **Development Workflow**
   - Use Yocto to generate images, SDKs, and rootfs overlays.
   - Deploy bitstreams and firmware using HSS and HSS payload utility.
   - Cross compile NN workloads with the Yocto SDK, run profiling on-board, and
     iterate on accelerator design through Libero+Yocto integration.

Relevant Architecture Patterns
------------------------------

- **Split Filesystem and Payload Delivery**: Pair a minimal rootfs (for fast
  boot and system services) with a secondary partition or artifact carrying the
  ML models and accelerator binaries. Useful for OTA updates and rollback.
- **Service-Oriented Boot Pipeline**: Use systemd to serialise hardware init
  orders, ensuring the FPGA accelerator and supporting drivers are ready before
  inference services start.
- **A/B System Partitions**: Maintain redundant root partitions so that
  experiments with accelerator firmware or NN stacks can roll back safely.
- **Data Governance & Telemetry Bus**: Route accelerator metrics (latency,
  throughput, thermal sensors) into an edge-to-cloud telemetry pipeline for
  DSP and ML workload analysis.
- **Hardware Abstraction Layer**: Wrap accelerator functionality behind a HAL
  that exposes standard interfaces to RISC-V applications, easing experimentation
  with different accelerator revisions.

Next Exploration Steps
----------------------

1. Clone Microchip's Yocto BSP and study the layer structure (`meta-polarfire-soc`,
   `meta-microchip-bsp`).
2. Create `meta-polarfire-nn` with recipes for the accelerator driver, HAL,
   sample inference application, and telemetry agent.
3. Draft a Libero project instantiating a simple neural network accelerator,
   and script its generation for integration with the Yocto build (bitstream
   packaging and deployment hooks).
4. Define an OTA/update story (SWUpdate or RAUC) aligned with the A/B partition
   pattern.
5. Document profiling workflows that measure accelerator throughput versus
   pure RISC-V or DSP implementations, validating architecture choices.
