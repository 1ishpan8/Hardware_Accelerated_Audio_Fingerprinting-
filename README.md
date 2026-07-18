# Hardware Accelerated Audio Fingerprinting 
* Architected a 100MHz zero-wait-state ZCU106 FPGA pipeline integrating a 1024-point AXI-Stream XFFT, 16-stage Verilog CORDIC, and a cascading insertion sort network 
to dynamically extract top-5 frequency peaks.
* Engineered a cache-aligned AXI DMA architecture to continuously stream and compress audio into highly efficient 64-bit temporal fingerprints while successfully
bypassing OS bottlenecks. Deployed a fixed-point 1D Temporal CNN directly into the hardware wrapper to classify the full 50-class ESC-50 dataset utilizing parallel
MAC units and an optimized FSM.
