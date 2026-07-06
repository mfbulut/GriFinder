package main

import "base:intrinsics"

import "core:math"
import "core:slice"

FFT_SIZE :: 4096
FFT_BITS :: 12
HOP_SIZE :: 512

fft_buffer: [FFT_SIZE]complex64
twiddle_table: [FFT_SIZE / 2]complex64
hann_table: [FFT_SIZE]f32

@(init)
fft_init :: proc "contextless" () {
	for i in 0 ..< FFT_SIZE {
		hann_table[i] = 0.54 - 0.46 * math.cos(2.0 * math.PI *  f32(i) / (FFT_SIZE - 1.0));
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
			mag := math.sqrt(real(c) * real(c) + imag(c) * imag(c))
			freq = 20.0 * math.ln(mag + math.F32_EPSILON) / math.LN10
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

	bands := [?]int{0, 40, 80, 160, 320, 640, 2048}

	for &freqs, t in spectrogram {
		Max :: struct {
			mag:  f32,
			freq: u32,
		}
		maxes: [6]Max

		for i in 0 ..< len(bands) - 1 {
			min_freq := bands[i]
			max_freq := bands[i + 1]
			index := min_freq + slice.max_index(freqs[min_freq:max_freq])
			maxes[i] = Max{freqs[index], u32(index)}
		}

		sum_mag := f32(0)
		for m in maxes {
			sum_mag += m.mag
		}
		avg_mag := sum_mag / f32(len(maxes))

		for m in maxes {
			if m.mag > avg_mag {
				p := Peak {
					time = u32(t),
					freq = m.freq,
				}
				append(&peaks, p)
			}
		}
	}

	return peaks[:]
}
