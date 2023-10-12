from litex.gen import *
from migen import *

from litex.soc.cores.spi import SPISlave


class TestSpi(LiteXModule):
    def __init__(self, spi_pads):
        self.spi = SPISlave(spi_pads, 32)
        self.spi.miso.eq(0x12345678)
