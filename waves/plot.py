import sys
import csv
import argparse
import matplotlib.pyplot as plt
from vcdvcd import VCDVCD

def twos_complement_to_int(value_str: str, bits: int) -> int:
    """Convert binary string (two's complement) into signed integer."""
    value = int(value_str, 2)
    if value & (1 << (bits - 1)):
        value -= (1 << bits)
    return value

def extract_signal(vcd_file: str, signal_name: str, bits: int = 32):
    # Parse VCD file
    vcd = VCDVCD(vcd_file, signals=[signal_name], store_tvs=True)

    if signal_name not in vcd.signals:
        print(f"Error: Signal '{signal_name}' not found in {vcd_file}")
        sys.exit(1)

    signal = vcd[signal_name]
    times, values = [], []

    for timestamp, value_str in signal.tv:
        if value_str in ('x', 'z', None):
            continue
        signed_value = twos_complement_to_int(value_str, bits)
        times.append(timestamp)
        values.append(signed_value)

    return times, values

def save_csv(signal_name: str, times, values):
    filename = f"{signal_name.replace('.', '_')}.csv"
    with open(filename, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["time", signal_name])
        for t, v in zip(times, values):
            writer.writerow([t, v])
    print(f"CSV saved as {filename}")

def plot_signal(signal_name: str, times, values):
    plt.figure(figsize=(10, 5))
    plt.plot(times, values, label=signal_name)
    plt.xlabel("Time")
    plt.ylabel("Value")
    plt.title(f"Signal Trace: {signal_name}")
    plt.legend()
    plt.grid(True)
    plt.show()

def main():
    parser = argparse.ArgumentParser(description="Extract and plot a 32-bit two's complement signal from VCD")
    parser.add_argument("vcd_file", help="Input VCD file")
    parser.add_argument("signal_name", help="Full hierarchical signal name (e.g. top.uut.signal)")
    args = parser.parse_args()

    times, values = extract_signal(args.vcd_file, args.signal_name)
    save_csv(args.signal_name, times, values)
    plot_signal(args.signal_name, times, values)

if __name__ == "__main__":
    main()
