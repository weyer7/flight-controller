import sys
import csv
import argparse
import matplotlib.pyplot as plt
from vcdvcd import VCDVCD

def twos_complement_to_int(value_str: str, bits: int = 32) -> int:
    """Convert binary string (two's complement) into signed integer."""
    value = int(value_str, 2)
    if value & (1 << (bits - 1)):
        value -= (1 << bits)
    return value

def extract_signals(vcd_file: str, signal_names, bits: int = 32):
    # Parse all requested signals in one go
    vcd = VCDVCD(vcd_file, signals=signal_names, store_tvs=True)

    results = {}
    for sig in signal_names:
        # Try exact match first
        if sig in vcd.signals:
            signal = vcd[sig]
        else:
            # Try to match by ending substring (e.g., "pos")
            matches = [s for s in vcd.signals if s.endswith(sig)]
            if not matches:
                print(f"Error: Signal '{sig}' not found in {vcd_file}")
                continue
            if len(matches) > 1:
                print(f"Warning: Multiple matches for '{sig}': {matches}. Taking first.")
            signal = vcd[matches[0]]

        # Extract timestamps and values
        times, values = [], []
        last_value = None
        for timestamp, value_str in signal.tv:
            if value_str in ('x', 'z', None):
                continue
            signed_value = twos_complement_to_int(value_str, bits)

            # If this isn’t the first point, extend the last value up to this timestamp
            if last_value is not None:
                times.append(timestamp)
                values.append(last_value)

            # Add the actual change
            times.append(timestamp)
            values.append(signed_value)

            last_value = signed_value

        results[sig] = (times, values)

    return results

def save_csv(signal_name: str, times, values):
    filename = f"{signal_name.replace('.', '_')}.csv"
    with open(filename, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["time", signal_name])
        for t, v in zip(times, values):
            writer.writerow([t, v])
    print(f"CSV saved as {filename}")

def plot_signals(results):
    plt.figure(figsize=(12, 6))
    for sig, (times, values) in results.items():
        plt.plot(times, values, label=sig, drawstyle="steps-post")  # step plot to show hold
    plt.xlabel("Time")
    plt.ylabel("Value")
    plt.title("Signal Traces")
    plt.legend()
    plt.grid(True)
    plt.show()

def main():
    parser = argparse.ArgumentParser(description="Extract and plot 32-bit two's complement signals from VCD")
    parser.add_argument("vcd_file", help="Input VCD file")
    parser.add_argument("signals", nargs="+", help="Signal names (e.g. pos error_new pid_out)")
    args = parser.parse_args()

    results = extract_signals(args.vcd_file, args.signals)

    for sig, (times, values) in results.items():
        save_csv(sig, times, values)

    plot_signals(results)

if __name__ == "__main__":
    main()
