# AudioTracked
Audio steganography is a technique of hiding data within an audio file by modifying its properties in a way that the changes remain imperceptible to human ears. 

This project is a great way to hide multimodal files by concealing their bits in the least significant bit (LSB) of each sample in an audio file. Currently, it supports only mono audio files and does not have stereo support.

Below is the visualization of how the audio waveform appears after embedding an input in it.

![graph2](assets/Unknown-3.png)
![graph1](assets/Unknown.png)
![graph3](assets/Unknown-2.png)

This project has been evaluated using some of the finest, most pristine, and sonically exquisite audio compositions known to humankind. Thus Radiohead.
![creepy man](assets/Thom-Yorke-GQ-03112019_16x9.jpg.webp)

## Repository layout
- `app.py`: Flask API entrypoint
- `utils.py`: watermarking/extraction primitives
- `web_interface.html`: local web UI
- `scripts/deploy/`: AWS and EC2 deployment scripts
- `config/aws/`: AWS policy/config JSON
- `secrets/`: local key material (ignored from git by `*.pem`)
- `docs/`: deployment and implementation notes
- `examples/`: quick demo scripts for audio/image/text flows
