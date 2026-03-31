#!/usr/bin/env python3
"""
Wrapper to force torchaudio to use soundfile backend before running demucs.
Avoids TorchCodec/FFmpeg DLL loading errors on Windows.
"""
import sys
import os

# Patch torchaudio.save to use soundfile instead of torchcodec
import torchaudio

_original_save = torchaudio.save

def patched_save(filepath, waveform, sample_rate, **kwargs):
    """Use soundfile backend instead of native TorchCodec."""
    import soundfile as sf
    import numpy as np
    
    # Convert tensor to numpy and transpose if needed (soundfile expects shape (frames, channels))
    wav_np = waveform.cpu().numpy()
    if len(wav_np.shape) == 1:
        wav_np = wav_np.reshape(-1, 1)
    elif wav_np.shape[0] < wav_np.shape[1]:
        # If shape is (channels, frames) transpose to (frames, channels)
        wav_np = wav_np.T
    
    # Write with soundfile
    sf.write(filepath, wav_np, int(sample_rate))

# Replace torchaudio.save globally
torchaudio.save = patched_save

# Now run demucs
from demucs.__main__ import main
main()
