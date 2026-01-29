import wave
import math
import struct
import os

def generate_tone_sequence(filename, freqs, duration=0.1, volume=0.5, sample_rate=44100):
    n_frames_total = int(duration * sample_rate)
    data = []
    
    # Generate mix of frequencies
    for i in range(n_frames_total):
        t = i / sample_rate
        value = 0
        for f in freqs:
            # Add subtle vibrato (LFO)
            lfo = 1.0 + 0.005 * math.sin(2 * math.pi * 3 * t) 
            term = math.sin(2 * math.pi * f * lfo * t)
            value += term
        
        # Normalize and scale
        value = (value / len(freqs)) * volume * 32767.0
        
        # Apply envelope
        envelope = 1.0
        if i < 2000: envelope = i / 2000
        if i > n_frames_total - 2000: envelope = (n_frames_total - i) / 2000
        
        data.append(struct.pack('<h', int(value * envelope)))
    
    with wave.open(filename, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(sample_rate)
        f.writeframes(b''.join(data))
    print(f"Generated {filename}")

def main():
    os.makedirs('mobile/assets/audio/sfx', exist_ok=True)
    os.makedirs('mobile/assets/audio/music', exist_ok=True)
    
    # Click (High blip)
    generate_tone_sequence('mobile/assets/audio/sfx/click.wav', [1200], 0.05, 0.3)
    
    # Pop (Lower blop)
    generate_tone_sequence('mobile/assets/audio/sfx/pop.wav', [600], 0.08, 0.4)
    
    # Success (Major triad arpeggio - simulated by playing chord for now for simplicity or overwrite function)
    # Re-using simple chord generator for success for now
    generate_tone_sequence('mobile/assets/audio/sfx/success.wav', [523.25, 659.25, 783.99], 0.4, 0.5)

    # Music: Cozy Lo-Fi Drone (Cmaj7 chord: C, E, G, B)
    # 4 seconds loop
    generate_tone_sequence(
        'mobile/assets/audio/music/cozy_lofi.wav', 
        [261.63, 329.63, 392.00, 493.88], 
        4.0, 
        0.2 # low volume for background
    )

if __name__ == "__main__":
    main()
