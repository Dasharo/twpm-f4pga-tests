from litex.build.generic_platform import *
from litex.build.quicklogic import QuickLogicPlatform
from litex.soc.integration.soc import SoCRegion
from litex.soc.integration.soc_core import *
from litex.soc.integration.builder import *
from litex.gen import *


class Platform(QuickLogicPlatform):
    def __init__(self, toolchain="f4pga"):
        QuickLogicPlatform.__init__(self, "ql-eos-s3", [], toolchain=toolchain)

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

def main():
    builder = Builder(Soc())
    builder.compile_software = False
    builder.build()


if __name__ == "__main__":
    main()

