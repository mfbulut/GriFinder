# GriFinder

An music recognition experiment.

## Usage

1. Put songs (mp3, flac, wav) into the `songs` directory.
2. Run the program using:
   ```bash
   odin run . -o:speed -no-bounds-check -microarch:native
   ```

## Overview

`GriFinder` aims to implement audio fingerprinting and recognition techniques. It analyzes audio signals, extracts robust acoustic features (such as spectrograms and peaks), and compares them against a database of known fingerprints to recognize matching songs.

**Status:** This project is currently in an early experimental phase. It successfully identifies and finds songs, though the recognition process is currently very slow and unoptimized.

In the future, `GriFinder` may be integrated as a feature into [**GriPlayer**](https://github.com/mfbulut/GriPlayer).

## Acknowledgments & Inspiration

This project drew reference and inspiration from [seek-tune](https://github.com/cgzirim/seek-tune).
