## How it works

The design implements a hardware-driven real-time VGA plasma pattern generator by racing the beam, eliminating the need for an external frame buffer or memory storage. 

An internal synchronous counter framework tracks the horizontal and vertical pixel coordinates ($X$ and $Y$) to match standard VESA 640x480 @ 60Hz video timing specifications. During the active visible display region, the pixel coordinates are combined using bit-shifts, additions, and bitwise XOR operations alongside a dynamic frame counter. This mathematical interference pattern creates a moving, organic plasma fractal effect directly on the display.

## How to test

1. Connect the output pins of the chip to a standard TinyVGA Pmod module.
2. Apply a standard 25.175 MHz pixel clock to the `clk` input pin.
3. Pull the active-low reset pin `rst_n` high to release the hardware logic from reset.
4. The display will instantly start rendering the real-time dynamic plasma pattern grid.

## External hardware

* TinyVGA Pmod (or equivalent resistor-ladder DAC VGA interface)
