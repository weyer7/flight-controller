from vcdvcd import VCDVCD

vcd = VCDVCD("pid.vcd")
print("Signals found in VCD:")
for s in vcd.signals:
    print(s)
