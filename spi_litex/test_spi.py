from litex.gen import *
from migen import *

from litex.soc.cores.spi import SPISlave


class TestSpi(LiteXModule):
    def __init__(self, spi_pads):
        self.register0 = Signal(32, reset=0x12345678)

        self.spi = SPISlave(spi_pads, 32)
        self.sync += [
            If(self.spi.irq, self.register0.eq(self.spi.mosi)),
            self.spi.miso.eq(self.register0)
        ]
