Architecture Pattern Coverage
=============================

Minimal Initramfs + Full Rootfs Handoff
---------------------------------------
- **Status**: Implemented.
- **Coverage Details**: Two-stage boot using Buildroot initramfs as Stage 0 (`./rebuild_rootfs.sh`) and ROS filesystem image mounted as Stage 1.
- **Tasks**: Expand health checks in Stage 0 to capture kiosk hardware diagnostics before pivot.

Split Filesystem (Fastboot + Payload)
-------------------------------------
- **Status**: Implemented.
- **Coverage Details**: Initrd stays minimal; ROS 2 payload delivered as `ros2.ext4` copied into QEMU and Pi outputs.
- **Tasks**: Add integrity checking (hash/signature) for `ros2.ext4` before mounting.

OverlayFS / UnionFS Runtime Overlay
-----------------------------------
- **Status**: Not started.
- **Implementation Notes**: Currently unused; rootfs is read-write ext4.
- **Tasks**: Prototype overlay mount on QEMU to validate persistent config without touching base image.

Deferred Device Bring-up
------------------------
- **Status**: Not started.
- **Implementation Notes**: All peripherals initialised synchronously.
- **Tasks**: Draft systemd units for kiosk display/touch to stage bring-up after splash.

Service-Oriented Boot Pipeline
------------------------------
- **Status**: Partially implemented.
- **Coverage Details**: systemd orchestrates fastfb init but further decomposition pending.
- **Tasks**: Define dedicated services for ROS stage 1 mount and optional kiosk daemons.

Split Core / Heterogeneous Processing
-------------------------------------
- **Status**: Not started.
- **Implementation Notes**: Pi 4 uses single OS.
- **Tasks**: Evaluate remoteproc on Pi 4 (e.g., leveraging VPU) or document limitations.

Microkernel + Userland Partitioning
-----------------------------------
- **Status**: Not planned.
- **Implementation Notes**: Linux monolithic, no microkernel.
- **Tasks**: None currently; revisit if safety certification emerges.

Hypervisor-Based Mixed-Criticality Partitioning
----------------------------------------------
- **Status**: Not planned.
- **Implementation Notes**: No hypervisor layer.
- **Tasks**: Monitor requirements; if needed, prototype KVM isolation for ROS workloads.

A/B System Partitions with OTA Frameworks
-----------------------------------------
- **Status**: Not started.
- **Implementation Notes**: Single rootfs image.
- **Tasks**: Evaluate RAUC vs Mender; design partition map supporting dual slots.

Delta-Friendly Storage with SquashFS + OSTree
--------------------------------------------
- **Status**: Not started.
- **Implementation Notes**: ROS volume built as ext4 image.
- **Tasks**: Investigate OSTree adoption for ROS bundle delivery.

Containerized ROS 2 Deployment
------------------------------
- **Status**: Partially implemented.
- **Coverage Details**: ROS content delivered via ext4 volume; containers not used yet.
- **Tasks**: Prototype OCI container packaging for ROS nodes.

Hardware Abstraction Layer (HAL) with Stable Contracts
------------------------------------------------------
- **Status**: Not started.
- **Implementation Notes**: fastfb interacts directly with framebuffer.
- **Tasks**: Define HAL boundaries for kiosk I/O; provide mockable interfaces for testing.

Secure Boot Chain and Measured Boot
-----------------------------------
- **Status**: Not started.
- **Implementation Notes**: Stock Pi boot flow.
- **Tasks**: Document secure boot options (Pi OTP keys, U-Boot SPL signing); plan roll-out.

Fault-Tolerant Messaging and Watchdog Mesh
-----------------------------------------
- **Status**: Not started.
- **Implementation Notes**: Basic watchdog not configured.
- **Tasks**: Enable systemd watchdog for fastfb; design heartbeat strategy for ROS nodes.

Deterministic Low-Latency Compute Cluster (HPC Edge)
----------------------------------------------------
- **Status**: Not applicable (Pi prototype).
- **Tasks**: None.

Time-Triggered / Deterministic Robotics Middleware
--------------------------------------------------
- **Status**: Not started.
- **Implementation Notes**: ROS default QoS.
- **Tasks**: Evaluate ROS 2 QoS deadlines if real-time control added.

Data Governance and Edge-to-Cloud Telemetry Bus
-----------------------------------------------
- **Status**: Not started.
- **Implementation Notes**: No telemetry pipeline.
- **Tasks**: Plan telemetry schema for kiosk analytics; choose MQTT or REST collector.

Container-Orchestrated Observability Stacks
------------------------------------------
- **Status**: Not started.
- **Implementation Notes**: No Prometheus/Grafana stack.
- **Tasks**: Determine observability scope; maybe embed node exporter.

Raspberry Pi 4 Feature Coverage
===============================

Cortex-A72 Quad CPU
-------------------
- **Status**: Fully utilised for fastboot app and ROS staging.
- **Tasks**: Benchmark CPU usage under kiosk load; reserve cores if needed.

VideoCore VI GPU (VC4/V3D)
--------------------------
- **Status**: Not used.
- **Tasks**: Investigate use of DRM/KMS or dispmanx for hardware-accelerated UI.

HDMI 2.0 Dual Display
---------------------
- **Status**: In progress.
- **Implementation Notes**: Target 27" kiosk; EDID capture pending.
- **Tasks**: Capture EDID, configure config.txt/fastfb scaling, validate 60 Hz output.

CSI Camera Interface
--------------------
- **Status**: Not planned.
- **Tasks**: None.

DSI Display Interface
---------------------
- **Status**: Not planned.
- **Tasks**: None.

PCIe x1 Lane
------------
- **Status**: Unused.
- **Tasks**: Document potential uses (e.g., NVMe) if storage needs grow.

USB 3.0 Host Ports
-------------------
- **Status**: Unused.
- **Tasks**: Identify kiosk peripherals (touch, sensors) and ensure drivers available.

Gigabit Ethernet
----------------
- **Status**: In use for ROS sync/OTA.
- **Tasks**: Harden network config; test OTA pipeline over wired LAN.

Dual-Band Wi-Fi (802.11ac)
--------------------------
- **Status**: Not evaluated.
- **Tasks**: Validate wpa_supplicant configuration and roaming for kiosk deployments.

Bluetooth 5.0
-------------
- **Status**: Unused.
- **Tasks**: Assess need for BLE peripherals (e.g., beacons) in kiosk scenarios.

microSD Storage
---------------
- **Status**: Primary boot media.
- **Tasks**: Investigate endurance/reliability; consider eMMC alternative if required.

GPIO (I2C/SPI/UART)
-------------------
- **Status**: Unused.
- **Tasks**: Plan for kiosk buttons or sensors; map pinouts upfront.

Audio (HDMI/3.5 mm)
-------------------
- **Status**: Unused.
- **Tasks**: Determine if kiosk needs audio prompts; integrate ALSA settings if so.
