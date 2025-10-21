import wave
import numpy as np
import os
from PIL import Image

def load_audio(filename):
    # Handle both absolute paths and relative paths with 'files/' prefix
    if not os.path.isabs(filename) and not os.path.exists(filename):
        filepath = 'files/' + filename
    else:
        filepath = filename
    with wave.open(filepath, 'rb') as audio_file:
        num_channels = audio_file.getnchannels()
        sample_width = audio_file.getsampwidth()
        frame_rate = audio_file.getframerate()
        audio_data = bytearray(list(audio_file.readframes(audio_file.getnframes())))
    return audio_data, num_channels, sample_width, frame_rate

def save_audio(filename, audio_data, num_channels, sample_width, frame_rate):
    # Handle both absolute paths and relative paths with 'files/' prefix
    if not os.path.isabs(filename) and not filename.startswith('files/'):
        filepath = 'files/' + filename
    else:
        filepath = filename
    with wave.open(filepath, 'wb') as audio_file:
        audio_file.setnchannels(num_channels)
        audio_file.setsampwidth(sample_width)
        audio_file.setframerate(frame_rate)
        audio_file.writeframes(audio_data)
    
def text_watermark(message, filename):
    audio_data, num_channels, sample_width, frame_rate= load_audio(filename)
    message = message+ '#####'
    message = message + int((len(audio_data)-(len(message)*8*8))/8) *'#'
    bits = list(map(int, ''.join([bin(ord(i)).lstrip('0b').rjust(8,'0') for i in message])))
    for i, bit in enumerate(bits):
        audio_data[i] =bit | (2**8-2 & audio_data[i])
    
    audio_data_modified = bytes(audio_data)
    save_audio('wtext.wav', audio_data_modified, num_channels, sample_width, frame_rate)
    print('Watermarking done')

def extract_text_watermark(filename):
    audio_data, _, _, _ = load_audio(filename)
    extracted = [audio_data[i] & 1 for i in range(len(audio_data))]
    string = "".join(chr(int("".join(map(str,extracted[i:i+8])),2)) for i in range(0,len(extracted),8))
    decode = string.split("#####")[0]
    return decode

def audio_watermark(filename_audio, filename_watermark):
    audio_data, num_channels, sample_width, frame_rate = load_audio(filename_audio)
    watermark_data, _, _, _ = load_audio(filename_watermark)

    small_audio_bits = []
    for byte in watermark_data:
        small_audio_bits.extend([int(bit) for bit in bin(byte)[2:].rjust(8, '0')])
    if len(small_audio_bits) > len(audio_data):
        raise ValueError('Watermark too large for audio file')
    else:
        for i, bit in enumerate(small_audio_bits):
            audio_data[i] = (audio_data[i] & 0xFE) | bit
    
    # Save to a temp location that can be moved later
    temp_output = "files/waudio.wav"
    save_audio(temp_output, audio_data, num_channels, sample_width, frame_rate)
    return(small_audio_bits)


def extract_audio_watermark(filename, small_audio_bits):
    # Use the provided filename instead of hardcoded path
    audio_data, num_channels, sample_width, frame_rate = load_audio(filename)
    extracted_bits = []

    for byte in audio_data:
        lsb = byte & 1  
        extracted_bits.append(lsb)

    if extracted_bits[:len(small_audio_bits)] == small_audio_bits:
        num_bits_in_hidden_audio = len(extracted_bits)
        num_bytes_in_hidden_audio = num_bits_in_hidden_audio // 8

        extracted_audio_data = bytearray()
        for i in range(0, num_bytes_in_hidden_audio * 8, 8):
            byte_bits = extracted_bits[i:i + 8]
            byte = int(''.join(map(str, byte_bits)), 2)  
            extracted_audio_data.append(byte)

        save_audio("ewaudio.wav", extracted_audio_data, num_channels, sample_width, frame_rate)

def extract_audio_watermark_direct(filename):
    """Extract embedded audio from watermarked file without requiring original bits"""
    audio_data, num_channels, sample_width, frame_rate = load_audio(filename)
    extracted_bits = []

    for byte in audio_data:
        lsb = byte & 1  
        extracted_bits.append(lsb)

    # Try to extract audio by analyzing the bit pattern
    # We'll extract up to a reasonable length (e.g., first 100KB worth of bits)
    max_bits = min(len(extracted_bits), 100000 * 8)  # 100KB max
    
    # Convert bits to bytes
    num_bits_for_extraction = (max_bits // 8) * 8  # Round down to nearest byte
    extracted_audio_data = bytearray()
    
    for i in range(0, num_bits_for_extraction, 8):
        byte_bits = extracted_bits[i:i + 8]
        if len(byte_bits) == 8:  # Only process complete bytes
            byte = int(''.join(map(str, byte_bits)), 2)  
            extracted_audio_data.append(byte)

    # Save the extracted audio
    save_audio("ewaudio.wav", extracted_audio_data, num_channels, sample_width, frame_rate)
    return len(extracted_audio_data)

def image_watermark(audio, wimage):
    audio_data, num_channels, sample_width, frame_rate = load_audio(audio)
    # Handle both absolute paths and relative paths with 'files/' prefix
    if not os.path.isabs(wimage) and not os.path.exists(wimage):
        image_path = 'files/' + wimage
    else:
        image_path = wimage
    image = Image.open(image_path).convert('L')
    width, height = image.size
    image_array = np.array(image)
    image_1d_array = image_array.flatten()
    image_bits = [format(pixel, '08b') for pixel in image_1d_array] 
    image_bits = ''.join(image_bits)

    watermark_bits = list(map(int, image_bits)) 

    if len(watermark_bits) > len(audio_data):
        raise ValueError("The image is too large to fit into the audio!")
    for i, bit in enumerate(watermark_bits):
        audio_data[i] = (audio_data[i] & 0xFE) | bit  

    save_audio('wiaudio.wav', audio_data, num_channels, sample_width, frame_rate)
    return width, height, len(watermark_bits)

def extract_image_watermark(audio, width, height, index):
    audio_data, _, _, _ = load_audio(audio)

    extracted_bits = []
    for byte in audio_data:
        lsb = byte & 1  
        extracted_bits.append(lsb)

    extracted_bits = extracted_bits[:index]
    byte_values = [int(''.join(map(str, extracted_bits[i:i+8])), 2) for i in range(0, len(extracted_bits), 8)]
    image_array = np.array(byte_values, dtype=np.uint8).reshape((height, width))
    image = Image.fromarray(image_array, mode='L')  
    image.save('files/'+'ewimate.jpg')

def extract_image_watermark_direct(filename):
    """Extract embedded image using YOUR exact logic from extract_image_watermark
    Just need to find the right width, height, and index parameters
    """
    # Load audio data once to avoid repeated loading
    audio_data, _, _, _ = load_audio(filename)
    
    # Extract all LSB bits once
    extracted_bits = []
    for byte in audio_data:
        lsb = byte & 1  
        extracted_bits.append(lsb)
    
    # Common image sizes to test - prioritize most common sizes first
    test_dimensions = [
        # Most common sizes first - these are likely to be the correct ones
        (500, 375), (640, 480), (800, 600), (400, 300), (320, 240),
        # Square sizes (common for smaller images)
        (256, 256), (128, 128), (512, 512), (64, 64),
        # Other rectangle sizes  
        (100, 80), (120, 90), (150, 100), (200, 150), (300, 200),
        (80, 100), (90, 120), (100, 150), (150, 200), (240, 320),
        (300, 400), (480, 640), (600, 800)
    ]
    
    # Try each dimension combination
    for width, height in test_dimensions:
        index = width * height * 8  # Total bits needed
        
        # Make sure we have enough bits
        if len(extracted_bits) < index:
            continue
            
        try:
            # YOUR EXACT LOGIC FROM extract_image_watermark:
            extracted_bits_for_image = extracted_bits[:index]
            byte_values = [int(''.join(map(str, extracted_bits_for_image[i:i+8])), 2) for i in range(0, len(extracted_bits_for_image), 8)]
            
            # Only proceed if we got the right number of bytes
            expected_pixels = width * height
            if len(byte_values) >= expected_pixels:
                # YOUR EXACT RESHAPE LOGIC:
                image_array = np.array(byte_values[:expected_pixels], dtype=np.uint8).reshape((height, width))
                
                # Quick quality check - real images have reasonable variance and mean
                variance = np.var(image_array.astype(float))
                mean_val = np.mean(image_array)
                
                # Good image characteristics: reasonable variance and not too extreme brightness
                if variance > 100 and 30 < mean_val < 225:
                    # This looks like a good image, save it
                    image = Image.fromarray(image_array, mode='L')
                    image.save('files/extracted_image.jpg')
                    return width, height, index
                    
        except Exception:
            continue
    
    # If no good image found with exact dimensions, fallback to reasonable size
    try:
        # Try a reasonable fallback size using the already extracted bits
        fallback_width = fallback_height = 256
        fallback_index = fallback_width * fallback_height * 8
        
        if len(extracted_bits) >= fallback_index:
            # YOUR EXACT LOGIC:
            extracted_bits_fallback = extracted_bits[:fallback_index]
            byte_values = [int(''.join(map(str, extracted_bits_fallback[i:i+8])), 2) for i in range(0, len(extracted_bits_fallback), 8)]
            
            if len(byte_values) >= fallback_width * fallback_height:
                image_array = np.array(byte_values[:fallback_width * fallback_height], dtype=np.uint8).reshape((fallback_height, fallback_width))
                image = Image.fromarray(image_array, mode='L')
                image.save('files/extracted_image.jpg')
                return fallback_width, fallback_height, fallback_index
                
    except Exception:
        pass
    
    # Ultimate fallback - return default values
    return 256, 256, 0


