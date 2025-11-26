Quantum Computing Simulations Tracker
=====================================

This note expands the README TODO entry for the quantum computing simulations tracker and outlines concrete next steps.

Simulator Survey
----------------

1. Compile comparison matrix for Qiskit Aer, Cirq, and PennyLane covering feature depth (gate sets, noise models), licensing, and CPU vs GPU support.
2. Identify Windows Subsystem for Linux compatibility notes, including Python version constraints and required system packages.
3. Capture installation quick checks (sample circuit execution, benchmark scripts) to validate toolchain readiness.

Packaging Prototype
-------------------

1. Decide whether to embed the simulator in Buildroot proper or provide an OCI container image for off-target experimentation.
2. For a native Buildroot integration, draft a `package/` skeleton with dependency mapping, configuration flags, and minimal sample code deployment.
3. For containerisation, outline a lightweight base image (e.g., Debian slim) plus simulator install steps scripted via Dockerfile or Podman recipe.

Benchmark and Evaluation Plan
-----------------------------

1. Select representative algorithms (e.g., quantum Fourier transform, variational circuits) that mirror the learning objectives.
2. Define metrics such as circuit depth, simulation runtime, memory footprint, and noise resilience under default backends.
3. Automate benchmarking using Python scripts so results can be reproduced across simulators and hardware configurations.

Learning Artifacts
------------------

1. Maintain a `docs/quantum-notes/` folder storing circuit examples, tutorial summaries, and key takeaways per simulator.
2. Version control Jupyter notebooks or Markdown walkthroughs demonstrating how each simulator integrates with classical control loops.
3. Track open questions or pain points to revisit during future iterations (e.g., scaling limits, hybrid execution APIs).
