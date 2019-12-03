#!/usr/bin/env python3

"""Coefficient for noise sensitivity evaluation."""

import argparse
import math
import os
import sys

import numpy as np
from scipy.stats import linregress


def load_file(path):
    with open(path) as f:
        return np.array([float(line.strip()) for line in f])


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument(
        "files", nargs="+", type=str, help="File with numbers.")
    args = parser.parse_args()

    non_existing = [path for path in args.files if not os.path.exists(path)]
    if non_existing:
        print(f"Files do not exists: {', '.join(non_existing)}",
              file=sys.stderr)
        exit(1)

    if len(args.files) < 2:
        print("Provide at least two series of numbers", file=sys.stderr)
        exit(1)

    all_series = [load_file(path) for path in args.files]

    for path, series in zip(args.files, all_series):
        if len(series) != 11:
            print(f"Missing measurements in {path}.", file=sys.stderr)
            exit(1)

    noise_probailities = np.arange(0, 1.1, 0.1)

    for i, series in enumerate(all_series):
        slope, intercept, r_value, p_value, std_err = linregress(
            noise_probailities, series)
        print(slope / intercept)


if __name__ == "__main__":
    main()
