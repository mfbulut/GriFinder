package main

import "base:intrinsics"

import "core:math"
import "core:slice"

FFT_SIZE :: 2048
FFT_BITS :: 11
HOP_SIZE :: 512

fft_buffer: [FFT_SIZE]complex64
twiddle_table: [FFT_SIZE / 2]complex64
hann_table: [FFT_SIZE]f32

@(init)
fft_init :: proc "contextless" () {
	for i in 0 ..< FFT_SIZE {
		hann_table[i] = 0.5 - 0.5 * math.cos(2.0 * math.PI * f32(i) / (FFT_SIZE - 1.0))
	}

	for i in 0 ..< FFT_SIZE / 2 {
		angle := -2.0 * math.PI * f32(i) / FFT_SIZE
		twiddle_table[i] = complex(math.cos(angle), math.sin(angle))
	}
}

fft :: proc() {
	for i in 0 ..< u32(FFT_SIZE) {
		j := intrinsics.reverse_bits(i) >> (32 - FFT_BITS)
		if i < j {
			fft_buffer[i], fft_buffer[j] = fft_buffer[j], fft_buffer[i]
		}
	}

	for length := u32(2); length <= FFT_SIZE; length <<= 1 {
		for i := u32(0); i < FFT_SIZE; i += length {
			for k in 0 ..< length / 2 {
				w := twiddle_table[k * FFT_SIZE / length]
				u := fft_buffer[i + k]
				v := fft_buffer[i + k + length / 2] * w
				fft_buffer[i + k] = u + v
				fft_buffer[i + k + length / 2] = u - v
			}
		}
	}
}

samples_to_spectrogram :: proc(samples: []f32) -> [][]f32 {
	window_count := (len(samples) - FFT_SIZE) / HOP_SIZE + 1
	spectrogram := make([][]f32, window_count)

	for &freqs, t in spectrogram {
		offset := t * HOP_SIZE

		for sample, i in samples[offset:offset + FFT_SIZE] {
			fft_buffer[i] = sample * hann_table[i]
		}

		fft()

		freqs = make([]f32, FFT_SIZE / 2)
		for &freq, i in freqs {
			c := fft_buffer[i]
			freq = math.sqrt(real(c) * real(c) + imag(c) * imag(c))
		}
	}

	return spectrogram
}

Peak :: struct {
	time: u32,
	freq: u32,
}

spectrogram_to_peaks :: proc(spectrogram: [][]f32) -> []Peak {
	peaks := make([dynamic]Peak)

	time_frames := len(spectrogram)
	freq_bins := len(spectrogram[0])

	BLOCK_SIZE :: 15

	for t := 0; t < time_frames; t += BLOCK_SIZE {
		for f := 0; f < freq_bins; f += BLOCK_SIZE {
			max_mag := f32(-10000.0)
			max_t := t
			max_f := f

			t_end := min(time_frames, t + BLOCK_SIZE)
			f_end := min(freq_bins, f + BLOCK_SIZE)

			for dt in t ..< t_end {
				for df in f ..< f_end {
					mag := spectrogram[dt][df]
					if mag > max_mag {
						max_mag = mag
						max_t = dt
						max_f = df
					}
				}
			}

			append(&peaks, Peak{u32(max_t), u32(max_f)})
		}
	}

	return peaks[:]
}
