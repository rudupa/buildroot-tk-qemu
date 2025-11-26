Raspberry Pi 4 Model B (4 GB) and BrainCraft HAT
===============================================

Raspberry Pi 4 Model B (4 GB)
-----------------------------

### Hardware Overview

The Raspberry Pi 4 Model B pairs a Broadcom BCM2711 SoC with 4 GB of LPDDR4
memory and dual-display capabilities. It retains the familiar 40-pin GPIO
header, enabling drop-in compatibility with legacy HATs while adding faster I/O
links for modern peripherals.

### Technical Specifications

- **SoC**: Broadcom BCM2711 quad-core Cortex-A72 (ARM v8) 64-bit @ 1.5 GHz
- **Memory**: 4 GB LPDDR4-3200 SDRAM (mounted as PoP on top of the SoC)
- **Graphics**: VideoCore VI GPU supporting OpenGL ES 3.0, 4Kp60 decode,
	dual HDMI output up to 4Kp30 (dual-mode micro-HDMI connectors)
- **Networking**: Gigabit Ethernet (via dedicated MAC) with PoE header
- **Wireless**: 802.11b/g/n/ac dual-band Wi-Fi, Bluetooth 5.0 + BLE (Cypress CYW43455)
- **USB**: 2 × USB 3.0, 2 × USB 2.0 (shared via VIA Labs VL805 PCIe controller)
- **Display**: 2 × micro-HDMI (up to 4Kp60 single, 4Kp30 dual)
- **Camera**: 2-lane MIPI CSI connector
- **Storage**: microSD card slot supporting UHS-I
- **Power**: USB-C (5 V / 3 A recommended); supports USB Power Delivery for
	negotiated current up to 3 A
- **GPIO Header**: 40-pin 2.54 mm header with 28 GPIO lines plus power/ground
- **Other I/O**: 2-lane MIPI DSI connector, stereo audio/composite video via
	3.5 mm jack, 4-pole PoE header, debug UART test pads

### Pinout Summary

The 40-pin header matches prior Pi layouts:

- **Power rails**: Pin 1 (3V3), Pin 2 (5V), Pin 4 (5V), Pin 17 (3V3), Pin 6/9/14/20/25/30/34/39 (GND)
- **Primary buses**: I2C (Pins 3,5), SPI0 (Pins 19,21,23,24,26), UART0 (Pins 8,10)
- **Additional functions**: I2S (Pins 18,19,21), GPIO4 for 1-Wire, PCM clock/data
- **GPIO numbering**: Broadcom (BCM) scheme is recommended when configuring in software

Raspberry Pi documentation should be consulted for the full pin matrix, drive
strength notes, and alternate functions.

### Key Features

- Dual-display output with simultaneous 4K support for kiosk and telemetry dashboards
- Enhanced memory bandwidth (LPDDR4) beneficial for ROS 2 workloads and ML inference
- True Gigabit Ethernet and dual USB 3.0 ports for high-speed peripherals
- Integrated wireless connectivity for flexible deployment scenarios
- Maintains compatibility with legacy 40-pin HAT ecosystem, easing reuse of accessories

Adafruit BrainCraft HAT for Raspberry Pi 4
------------------------------------------

### Hardware Overview

The BrainCraft HAT is a machine-learning-focused expansion board providing
visual, audio, and tactile interfaces tailored for edge AI demos on the Pi 4.
It plugs into the 40-pin header and adds connectors for displays, cameras, and
microphones while integrating supporting sensors.

### Technical Specifications

- **Display**: 1.54" IPS TFT (240 × 240) connected via SPI with capacitive touch interface
- **Camera Support**: Two JST-SH connectors routing Pi CSI lines to flat flex cables;
	includes power and I2C for external camera modules (e.g., OV5645 based)
- **Neopixel**: 1 × RGB status LED (chainable) for inference state indication
- **Audio**: MAX98357A I2S Class-D amplifier driving 3 W speaker output;
	pair of STEMMA QT / Qwiic JST-SH connectors for I2C microphones or sensors
- **User Controls**: Five-direction joystick plus two tactile buttons mapped to GPIO
- **Sensing**: APDS9960 gesture/color/proximity sensor via I2C, TMP117 precision temperature sensor
- **Power**: 5 V supplied via Pi header; onboard regulators provide 3V3 for sensors
- **Dimensions**: HAT-compliant footprint (65 mm × 56 mm) with EEPROM for auto-configuration

### Pin Usage / Header Mapping

- **SPI**: Uses SPI0 (GPIO10–11–9–8) for the TFT display
- **I2C**: I2C1 (GPIO2, GPIO3) routed to STEMMA QT/Qwiic connectors and onboard sensors
- **I2S / PCM**: GPIO18/19/20/21 for audio amplifier input
- **GPIO Controls**: Joystick/buttons typically map to GPIO5, GPIO6, GPIO16, GPIO20, GPIO21
- **Other**: PWM-capable pin (GPIO13) often assigned to the NeoPixel indicator

Refer to Adafruit schematics for the precise mapping, especially if remapping
pins for custom accelerator interfaces.

### Key Features

- Integrated display and touch for quick ML model visualization
- Ready-to-use audio subsystem for wake-word detection or spoken feedback
- Onboard sensors enabling gesture, color, and temperature context for demos
- STEMMA QT/Qwiic ecosystem compatibility for rapid sensor prototyping without soldering
- EEPROM holds device tree overlay enabling automatic configuration on boot

Integration Notes
-----------------

- Ensure the Raspberry Pi firmware overlay for the BrainCraft HAT (`braincraft-hat`)
	is enabled in `/boot/config.txt` so the display, audio, and sensors initialise properly.
- When stacking additional accessories, confirm GPIO pin conflicts—especially SPI0
	and I2S lines critical to the HAT.
- For kiosk workloads, the Pi’s dual HDMI outputs can drive external displays while
	the HAT TFT provides a local debug or status UI.
