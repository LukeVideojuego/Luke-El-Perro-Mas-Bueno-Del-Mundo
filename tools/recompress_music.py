"""Re-codifica la musica de assets/audio/music/ a MP3 VBR V5 (~130 kbps).

MP3 porque es el unico formato que reproducen seguro Safari de iPhone y
Chrome de Android. Los originales (~256 kbps) estan en musica_candidata/.
Necesita:  pip install lameenc miniaudio
    python tools/recompress_music.py
"""
import array
import pathlib
import sys

import lameenc
import miniaudio

VBR_QUALITY = 5

root = pathlib.Path(__file__).resolve().parent.parent
for mp3 in sorted((root / "assets" / "audio" / "music").glob("*.mp3")):
    before = mp3.stat().st_size
    # (decode desde bytes: decode_file falla con la "á" de la ruta del proyecto)
    dec = miniaudio.decode(mp3.read_bytes(), output_format=miniaudio.SampleFormat.SIGNED16)
    enc = lameenc.Encoder()
    enc.set_in_sample_rate(dec.sample_rate)
    enc.set_channels(dec.nchannels)
    enc.set_vbr(4)  # vbr_mtrh, el VBR por defecto de LAME
    enc.set_vbr_quality(VBR_QUALITY)
    enc.set_quality(2)
    data = enc.encode(array.array("h", dec.samples).tobytes()) + enc.flush()
    mp3.write_bytes(data)
    print("%-32s %5.2f MB -> %5.2f MB" % (mp3.name, before / 1e6, len(data) / 1e6))
    sys.stdout.flush()
