#!/usr/bin/env python3

import argparse
import multiprocessing
import sys
import yaml

def get_vocab(lines):
    vocabulary = {}

    for line in lines:
        for token in line.rstrip().split():
            if token not in vocabulary:
                vocabulary[token] = 0
            vocabulary[token] += 1
    return vocabulary


def merge_in_vocab(orig, new):
    for token, count in new.items():
        if token not in orig:
            orig[token] = count
        else:
            orig[token] += count

def main():
    parser = argparse.ArgumentParser("Get vocabulary from plain text files.")
    parser.add_argument(
        "input", nargs="+",  type=argparse.FileType('r'),
        help="List of input files, use - for stdin.")
    parser.add_argument(
        "--min-count", type=int, default=10)
    parser.add_argument(
        "--num-threads", type=int, default=4,
        help="Number of threads")
    parser.add_argument(
        "--marian-yaml", action="store_true", default=False,
        help="Get the vocabulary in the Marian YAML format.")
    args = parser.parse_args()


    pool = multiprocessing.Pool(processes=args.num_threads)
    vocabulary = {}

    for input_file in args.input:
        print(f"Reading file '{input_file}'", file=sys.stderr)
        line_buffers = []
        current_buffer = []

        for line in input_file:
            current_buffer.append(line)

            if len(current_buffer) > 200:
                line_buffers.append(current_buffer)
                current_buffer = []

            if len(line_buffers) > args.num_threads:
                for vocab in pool.map(get_vocab, line_buffers):
                    merge_in_vocab(vocabulary, vocab)
                line_buffers = []

        line_buffers.append(current_buffer)
        for vocab in pool.map(get_vocab, line_buffers):
            merge_in_vocab(vocabulary, vocab)


    if args.marian_yaml:
        yaml_vocabulary = {
            "</s>": 0,
            "<unk>": 1}

        for token, count in sorted(
                vocabulary.items(), key=lambda x: x[1], reverse=True):
            if count > args.min_count:
                yaml_vocabulary[token] = len(yaml_vocabulary)

        yaml.dump(yaml_vocabulary, sys.stdout, default_flow_style=False, allow_unicode=True)
    else:
        for token, count in sorted(
                vocabulary.items(), key=lambda x: x[1], reverse=True):
            print("{}\t{}".format(token, count))


if __name__ == "__main__":
    main()
