from litex.gen import *
from migen import *

from litex.soc.cores.spi import SPISlave


class Slave(LiteXModule):
    def __init__(self, spi_pads):
        self.scratch = Signal(32)

        self.addr = Signal(24, reset_less=True)
        self.transfer_size = Signal(6, reset_less=True)

        self.spi = SPISlave(spi_pads, 32)
        self.fsm = FSM(reset_state="COMM")
        self.fsm.act(
            "COMM",
            # Don't insert wait state
            self.spi.miso.eq(0xFFFFFFFF),
            If(
                # IRQ is triggered when CS goes high so we need short CS pulses
                # for SPI to actually work. This is not fully compatible with TPM
                # protocol and needs to be fixed.
                self.spi.irq,
                # Make sure we have full header
                If(
                    self.spi.length == 32,
                    self.addr.eq(self.spi.mosi[0:24]),
                    self.transfer_size.eq(self.spi.mosi[24:30]),
                    If(self.spi.mosi[31], NextState("READ")).Else(NextState("WRITE")),
                    # Reset IRQ status
                    NextValue(self.spi.irq, 0),
                ),
            ),
        )
        self.fsm.act(
            "READ",
            self.spi.miso.eq(self.scratch),
            If(self.spi.irq, NextState("COMM"), NextValue(self.spi.irq, 0)),
        )
        self.fsm.act(
            "WRITE",
            If(
                self.spi.irq,
                self.scratch.eq(self.spi.mosi),
                NextState("COMM"),
                NextValue(self.spi.irq, 0),
            ),
        )
