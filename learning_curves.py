#!/usr/bin/env python3

import argparse
import os
import re

import matplotlib.pyplot as plt
import mpld3


def values_from_log(path, pattern):
    steps = []
    values = []

    with open(path) as f_log:
        for line in f_log:
            match = pattern.match(line)
            if match:
                steps.append(int(match[1]))
                values.append(float(match[2]))
    return steps, values


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument(
        "language_pair", type=str,
        choices=["ende", "deen", "csen", "encs", "fren", "enfr"])
    parser.add_argument(
        "--metric", type=str,
        choices=["cross-entropy", "perplexity", "translation"],
        default="cross-entropy")
    parser.add_argument(
        "--regex", type=str, default=None,
        help="Pattern of what directories to include.")
    args = parser.parse_args()

    pattern = re.compile(
        ".*Up\\. ([0-9]+) : {} : ([0-9]+\\.[0-9]+)".format(args.metric))

    experiments = [
        dirname for dirname in os.listdir("models")
        if dirname.startswith(args.language_pair)]

    if args.regex is not None:
        cmd_pattern = re.compile(args.regex)
        experiments = [
            e for e in experiments if cmd_pattern.match(e)]

    print(f"Found {len(experiments)} experiemnts: {' '.join(experiments)}")
    if not experiments:
        print("Nothing to plot.")
        exit()

    fig, ax = plt.subplots()
    ax.figure.set_size_inches((20, 10))

    ax.set_title(f"{args.language_pair}: {args.metric}")
    ax.set_xlabel('Steps')
    ax.set_ylabel(args.metric)

    line_styles = ["-", "--", "-.", ":"]

    for i, experiment in enumerate(sorted(experiments)):
        name = experiment[5:]
        steps, values = values_from_log(
            os.path.join("models", experiment, "valid.log"), pattern)
        if steps:
            ax.plot(
                steps, values,
                line_styles[(i // 10) % len(line_styles)],
                label=name)

    ax.legend()

    mpld3.save_html(fig, f"{args.language_pair}_{args.metric}.html")


if __name__ == "__main__":
    main()
