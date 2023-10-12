from litex.build.generic_platform import *
from litex.build.quicklogic import QuickLogicPlatform
from litex.build.quicklogic.f4pga import F4PGAToolchain
from litex.soc.integration.soc import SoCRegion
from litex.soc.integration.soc_core import *
from litex.soc.integration.builder import *
from litex.gen import *

from test_spi import TestSpi

_io = [
    (
        "user_rgb_led",
        0,
        Subsignal("r", Pins("34")),
        Subsignal("g", Pins("39")),
        Subsignal("b", Pins("38")),
    ),
    (
        "spi",
        0,
        Subsignal("clk", Pins("63")),
        Subsignal("cs_n", Pins("59")),
        Subsignal("mosi", Pins("64")),
        Subsignal("miso", Pins("56")),
        IOStandard("LVCMOS33"),
    ),
]


class Platform(QuickLogicPlatform):
    def __init__(self):
        class Toolchain(F4PGAToolchain):
            def __init__(self):
                super().__init__()

            def build_timing_constraints(self, vns):
                # FIXME: dirty hack to inject timing constraints for C16 clock.
                # This must be done on net that is directly connected to ASSP.
                # eos_s3_eos_s3_0_clk net is connected to ASSP, while "sys"
                # clock is connected to eos_s3_eos_s3_0_clk.
                x, y = super().build_timing_constraints(vns)
                if self.platform.c16_freq > 0:
                    with open(x, "a") as file:
                        c16_period_ns = 1 / self.platform.c16_freq * 1000000000
                        file.write(f"create_clock -period {c16_period_ns} eos_s3_eos_s3_0_clk\n")

                return (x, y)

        self.c16_freq = 0.0
        QuickLogicPlatform.__init__(self, "ql-eos-s3", _io, toolchain=Toolchain())

    def set_c16_freq(self, freq: float):
        self.c16_freq = freq


class _CRG(LiteXModule):
    def __init__(self, cpu_type):
        self.rst = Signal()
        self.cd_sys = ClockDomain()

        if cpu_type == "eos_s3":
            self.comb += ClockSignal("sys").eq(ClockSignal("eos_s3_0"))
            self.comb += ResetSignal("sys").eq(ResetSignal("eos_s3_0") | self.rst)


class Soc(SoCCore):
    def __init__(self, cpu_type, c16_freq):
        platform = Platform()
        args = {
            "with_uart": False,
            "with_timer": False,
            "with_ctrl": False,
            "cpu_type": cpu_type,
            "integrated_sram_size": 0,
        }
        self.crg = _CRG(cpu_type)
        platform.set_c16_freq(c16_freq)
        SoCCore.__init__(
            self,
            platform,
            c16_freq,
            ident="LiteX SoC on QuickLogic QuickFeather",
            **args,
        )

        self.bus.add_region(
            "rom",
            SoCRegion(origin=self.mem_map["rom"], size=4 * 128 * 1024, linker=True),
        )

        led = platform.request("user_rgb_led")
        spi_pads = platform.request("spi")
        self.submodules.test_spi = TestSpi(spi_pads)
        # platform.add_period_constraint(spi_pads.clk, 41.6) # 24 MHz


def main():
    c16_freq = 60000000

    soc = Soc(cpu_type="eos_s3", c16_freq=c16_freq)
    builder = Builder(soc)
    builder.compile_software = False
    builder.build()


if __name__ == "__main__":
    main()
