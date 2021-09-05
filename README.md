Hello everyone.  This HDMI / DVI encoder was originally implemented by Sameer Puri -> https://github.com/sameer.

See original full project, source files and schematics from Jan 24, 2021 here:

https://www.eevblog.com/forum/fpga/hdmi-dvi-encoder-with-audio-smart-quartus-pll-integration-in-systemverilog/


I have made a bunch of tweaks/changes and created a smart parameter configurable PLL module for Quartus which allows one to trick Quartus's 'toggle rate limit' on the LVDS ports so that modes like 720p and above may be compiled for.  Tests have been performed on the https://www.eevblog.com/forum/fpga/fpga-vga-controller-for-8-bit-computer/ thread and we can confirm that a CycloneIV-8 (Should be the same for CycloneIII/IV/10/MAX10 variants) series FPGAs using the slower LVDS_E_3R IO ports can run up to 1080mbps, IE 1280x1024@60Hz / 1440x960@59.95Hz fine.

The attached project has an example design using a CycloneIV whose top hierarchy is 'HDMI_Encoder.sv' and all the used source files are in the 'src' folder.  All the instructions for the parameters are located in the source files.

These are the list of changes/improvements:

1.  The original software serializer using the DDR was replaced with Altera's altlvds_tx serializer megafunction.  In the source 'hdmi.sv', this is a module initiated at line 367, calling source file 'HDMI_serializer_altlvds.sv'.  A dummy spot for Xilinx 'OSERDESE2' serializer was left at line 375, however, I am not familiar or setup to make and test a 'HDMI_serializer_OSERDESE2.sv' module.
2.  A bit/polarity inversion for each of the LVDS channels allowing you to swap the +&- pins on the LVDS outputs for PCB routing.
3.  A number of patches were made to offer support all the way back to Quartus 13.0 sp1 giving support to earlier Cyclones.
4.  A smart single/dual PLL generator, 'HDMI_PLL.sv' which generates the video pixel clock plus a 5x clock used by the serializer when the serializer's built in PLL is disabled.  It also offers a parameter to trick Quartus that the LVDS serial output is running at a lower frequency to allow compilation on slower FPGAs.  (Warnings in the source code.)
5.  The 'HDMI_PLL.sv' also generates an audio clock enable pulse and audio clock synchronous to the pixel clock, with a sub-pixel floating-point clock divider/remainder capable of correcting for audio sample frequencies which do not divide evenly in into the pixel clock.
6.  The original 'hdmi.sv' audio input section now can run in 100% synchronous pixel clock mode, using an 'clk_audio_ena' strobe input to advance the audio sample.  This removes the crossing of clock domain boundaries in the timing report.
7.  New video mode IDs, 34,964,965,969,1024,1084,1085.  See: 'HDMI_Encoder.sv' for the resolutions. 
8.  1KHz sine wave test tone.


Extras, Simulation (At minimal, a basic setup and display of the inner workings):
In Quartus, when doing/running an RTL simulation, in the transcript type:
 - do ../../hdmi_rtl.do
To setup the simulation waveform window and get access to all the core.

In Quartus, when doing an GATE simulation, in the transcript type:
 - do ../../hdmi_gate.do
To setup the simulation waveform to see the N&P TMDS output timing.

For our test bench, we use a 90 cent NXP IC, PTN3366BSMP, for static protection of the IOs, and 5v to 3.3v conversion for the EDID I2C and hot-plug-detect signals.  It is also a 3GHz amplifier/cable driver which may be why we have had no problems making a 550mbps -8 cyclone output a 1280x1024 video mode at 1080mbps.  See our schematic here: (note we are not using resistors R8,R10,R11,R12,R16,R15,R14,R13, and the TXD[0..2] polarity has been swapped to allow straight PCB traces while TXD[3]/TXC has the correct polarity.)
[url=https://www.eevblog.com/forum/fpga/hdmi-dvi-encoder-with-audio-smart-quartus-pll-integration-in-systemverilog/msg3430892/#msg3430892]https://www.eevblog.com/forum/fpga/hdmi-dvi-encoder-with-audio-smart-quartus-pll-integration-in-systemverilog/msg3430892/#msg3430892[/url]

(The parameters INV_TMDS#s need to be set accordingly if you are to use that example schematic exactly as-is with the swapped +&- pins.)

Things not done, but maybe in the future:  Re-do the audio sampling sub-system to use a true dual-clock M9K ram block instead of logic elements.  This will remove ~700 wasted logic elements on the audio input buffer and when using an external 48KHz audio clock, there wont be a potential list of cross-clock domain timing violations.

Note that the attached .zip is a Quartus project.  If you want to simulate, just compile and then do an RTL or Gate level simulation.  RTL gives you full access to the real time source logic during simulation while the gate level shows you the actual timing of the +&- TMDS outputs pins.



-------------------------------------------------
Stand Alone PLL Simulator HDMI_PLL_ALTERA_tb.zip 
-------------------------------------------------

Here is a stand-alone Altera ModelSim test bench just for my parameter configurable PLL module 'HDMI_PLL.sv'.

It allows you to follow the cascade of parameters and how the audio clock generator creates a perfect overall sample frequency even though it may not divide evenly into the pixel clock.

The simulation runs for 1 full millisecond, this means almost 1 minute to simulate (unless you clock stop midway).
(The testbench sim has 2 frequency counters counting the pixel & audio clock outputs for 1ms exactly after the PLL has started up.)

Since it is a stand-alone simulation project, these are the setup instructions:

1.  Un-zip the the source files into it's own directory.
2.  Run ModelSim for Altera, no Quartus...
3.  In ModelSim, select 'File - Change Directory...' and select the folder you have un-zipped the source files to.
4.  In the 'Transcript', type:  ' do setup.do ' to initialize & setup.  (includes including altera's PLL megafunction library...)
5.  In the 'Transcript', type:  ' do run.do ' to re-compile the source files, setup the waveform display and run the simulation.  (IE: make a parameter or code change and just type once again 'do run.do' to re-compile the source code and re-run the simulation.)

