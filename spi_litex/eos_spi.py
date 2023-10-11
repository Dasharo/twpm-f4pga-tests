from litex.build.generic_platform import *
from litex.build.quicklogic import QuickLogicPlatform
from litex.soc.integration.soc import SoCRegion
from litex.soc.integration.soc_core import *
from litex.soc.integration.builder import *
from litex.gen import *

from litex.soc.cores.spi import SPISlave

_io = [
    ("user_led",   0, Pins("38"), IOStandard("LVCMOS33")), # blue
    ("user_led",   1, Pins("39"), IOStandard("LVCMOS33")), # green
    ("user_led",   2, Pins("34"), IOStandard("LVCMOS33")), # red
    ("spi", 0,
        Subsignal("clk", Pins("63")),
        Subsignal("cs_n", Pins("59")),
        Subsignal("mosi", Pins("64")),
        Subsignal("miso", Pins("56")),
        IOStandard("LVCMOS33")
    )
]

class Platform(QuickLogicPlatform):
    def __init__(self, toolchain="f4pga"):
        QuickLogicPlatform.__init__(self, "ql-eos-s3", _io, toolchain=toolchain)

class _CRG(LiteXModule):
    def __init__(self):
        self.rst = Signal()
        self.cd_sys = ClockDomain()

        # LiteX needs at least one clock domain, use C16 clock.
        self.comb += ClockSignal("sys").eq(ClockSignal("eos_s3_0"))
        self.comb += ResetSignal("sys").eq(ResetSignal("eos_s3_0") | self.rst)

class Soc(SoCCore):
    def __init__(self):
        platform = Platform()
        args = {
            'with_uart': False,
            'with_timer': False,
            'with_ctrl': False,
            'cpu_type': 'eos_s3',
            'integrated_sram_size': 0
        }
        self.crg = _CRG()
        SoCCore.__init__(self, platform, 10e6, ident="LiteX SoC on QuickLogic QuickFeather", **args)

        self.bus.add_region("rom", SoCRegion(
            origin = self.mem_map["rom"],
            size   = 4 * 128 * 1024,
            linker = True)
        )

        spi_pads = platform.request("spi")
        self.spi = SPISlave(spi_pads, 8)
        platform.add_period_constraint(spi_pads.clk, 41.6) # 24 MHz

def main():
    soc = Soc()
    builder = Builder(soc)
    builder.compile_software = False
    builder.build()


if __name__ == "__main__":
    main()

