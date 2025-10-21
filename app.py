from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import os
import tempfile
import uuid
import boto3
import shutil
from werkzeug.utils import secure_filename
import json
from utils import (
    audio_watermark, extract_audio_watermark, extract_audio_watermark_direct,
    image_watermark, extract_image_watermark, extract_image_watermark_direct,
    text_watermark, extract_text_watermark,
    load_audio, save_audio
)

app = Flask(__name__)
CORS(app)

# AWS Configuration
S3_BUCKET = os.getenv('S3_BUCKET', 'audiotracked-files')
AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')

# Initialize S3 client
s3_client = boto3.client('s3', region_name=AWS_REGION)

# Ensure upload directory exists
UPLOAD_FOLDER = 'temp_uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def upload_to_s3(file_path, s3_key):
    """Upload file to S3 bucket"""
    try:
        s3_client.upload_file(file_path, S3_BUCKET, s3_key)
        # Return a signed URL that works for 7 days instead of public URL
        url = s3_client.generate_presigned_url(
            'get_object',
            Params={'Bucket': S3_BUCKET, 'Key': s3_key},
            ExpiresIn=604800  # 7 days
        )
        return url
    except Exception as e:
        raise Exception(f"Failed to upload to S3: {str(e)}")

def download_from_s3(s3_key, local_path):
    """Download file from S3 bucket"""
    try:
        s3_client.download_file(S3_BUCKET, s3_key, local_path)
        return True
    except Exception as e:
        raise Exception(f"Failed to download from S3: {str(e)}")

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "service": "AudioTracked API"})

@app.route('/api/audio-watermark', methods=['POST'])
def embed_audio_watermark():
    """Embed audio file into another audio file"""
    try:
        if 'host_audio' not in request.files or 'watermark_audio' not in request.files:
            return jsonify({"error": "Both host_audio and watermark_audio files are required"}), 400
        
        host_file = request.files['host_audio']
        watermark_file = request.files['watermark_audio']
        
        if host_file.filename == '' or watermark_file.filename == '':
            return jsonify({"error": "No files selected"}), 400
        
        # Generate unique IDs for files
        session_id = str(uuid.uuid4())
        host_filename = secure_filename(host_file.filename)
        watermark_filename = secure_filename(watermark_file.filename)
        
        # Save temp files
        host_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_host.wav")
        watermark_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_watermark.wav")
        
        host_file.save(host_path)
        watermark_file.save(watermark_path)
        
        # Process watermarking
        small_audio_bits = audio_watermark(host_path, watermark_path)
        
        # Save result - the utils function saves to "files/waudio.wav"
        temp_result = "files/waudio.wav"
        result_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_result.wav")
        if os.path.exists(temp_result):
            shutil.move(temp_result, result_path)
        
        # Upload to S3
        result_s3_key = f"watermarked/{session_id}_result.wav"
        result_url = upload_to_s3(result_path, result_s3_key)
        
        # Store metadata in S3
        metadata = {
            "session_id": session_id,
            "type": "audio_watermark",
            "small_audio_bits": small_audio_bits,
            "result_url": result_url
        }
        s3_client.put_object(
            Bucket=S3_BUCKET,
            Key=f"metadata/{session_id}.json",
            Body=json.dumps(metadata),
            ContentType='application/json'
        )
        
        # Cleanup temp files
        os.remove(host_path)
        os.remove(watermark_path)
        os.remove(result_path)
        
        return jsonify({
            "success": True,
            "session_id": session_id,
            "result_url": result_url,
            "message": "Audio watermarking completed successfully"
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/audio-watermark/extract', methods=['POST'])
def extract_audio_watermark():
    """Extract embedded audio from watermarked file"""
    try:
        data = request.get_json()
        session_id = data.get('session_id')
        
        if not session_id:
            return jsonify({"error": "session_id is required"}), 400
        
        # Download metadata
        try:
            metadata_response = s3_client.get_object(
                Bucket=S3_BUCKET,
                Key=f"metadata/{session_id}.json"
            )
            metadata = json.loads(metadata_response['Body'].read())
            small_audio_bits = metadata['small_audio_bits']
            result_s3_key = metadata['result_url'].split('/')[-1]
        except:
            return jsonify({"error": "Session not found"}), 404
        
        # Download watermarked file
        watermarked_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_watermarked.wav")
        download_from_s3(f"watermarked/{result_s3_key}", watermarked_path)
        
        # Extract watermark
        extract_audio_watermark(watermarked_path, small_audio_bits)
        
        # Upload extracted audio
        extracted_path = "files/ewaudio.wav"
        extracted_s3_key = f"extracted/{session_id}_extracted.wav"
        extracted_url = upload_to_s3(extracted_path, extracted_s3_key)
        
        # Cleanup
        os.remove(watermarked_path)
        os.remove(extracted_path)
        
        return jsonify({
            "success": True,
            "extracted_url": extracted_url,
            "message": "Audio watermark extracted successfully"
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/audio-watermark/direct-extract', methods=['POST'])
def direct_extract_audio_watermark():
    """Directly extract embedded audio from uploaded watermarked file"""
    try:
        if 'audio' not in request.files:
            return jsonify({"error": "Audio file is required"}), 400
        
        audio_file = request.files['audio']
        session_id = str(uuid.uuid4())
        
        # Save temp file
        audio_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_watermarked.wav")
        audio_file.save(audio_path)
        
        # Extract watermark using direct method
        extracted_size = extract_audio_watermark_direct(audio_path)
        
        # Move result - the utils function saves to "files/ewaudio.wav"
        temp_result = "files/ewaudio.wav"
        result_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_extracted.wav")
        if os.path.exists(temp_result):
            shutil.move(temp_result, result_path)
        
        # Upload extracted audio
        extracted_s3_key = f"extracted/{session_id}_extracted.wav"
        extracted_url = upload_to_s3(result_path, extracted_s3_key)
        
        # Cleanup
        os.remove(audio_path)
        os.remove(result_path)
        
        return jsonify({
            "success": True,
            "extracted_url": extracted_url,
            "extracted_size": extracted_size,
            "message": "Audio watermark extracted successfully"
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/image-watermark', methods=['POST'])
def embed_image_watermark():
    """Embed image into audio file"""
    try:
        if 'audio' not in request.files or 'image' not in request.files:
            return jsonify({"error": "Both audio and image files are required"}), 400
        
        audio_file = request.files['audio']
        image_file = request.files['image']
        
        session_id = str(uuid.uuid4())
        
        # Save temp files
        audio_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_audio.wav")
        image_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_image.jpg")
        
        audio_file.save(audio_path)
        image_file.save(image_path)
        
        # Process watermarking
        w, h, index = image_watermark(audio_path, image_path)
        
        # Move result - the utils function saves to "files/wiaudio.wav"
        temp_result = "files/wiaudio.wav"
        result_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_result.wav")
        if os.path.exists(temp_result):
            shutil.move(temp_result, result_path)
        
        # Upload to S3
        result_s3_key = f"image_watermarked/{session_id}_result.wav"
        result_url = upload_to_s3(result_path, result_s3_key)
        
        # Store metadata
        metadata = {
            "session_id": session_id,
            "type": "image_watermark",
            "width": w,
            "height": h,
            "index": index,
            "result_url": result_url
        }
        s3_client.put_object(
            Bucket=S3_BUCKET,
            Key=f"metadata/{session_id}.json",
            Body=json.dumps(metadata),
            ContentType='application/json'
        )
        
        # Cleanup
        os.remove(audio_path)
        os.remove(image_path)
        os.remove(result_path)
        
        return jsonify({
            "success": True,
            "session_id": session_id,
            "result_url": result_url,
            "message": "Image watermarking completed successfully"
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/image-watermark/direct-extract', methods=['POST'])
def direct_extract_image_watermark():
    """Directly extract embedded image from uploaded watermarked file"""
    try:
        if 'audio' not in request.files:
            return jsonify({"error": "Audio file is required"}), 400
        
        audio_file = request.files['audio']
        session_id = str(uuid.uuid4())
        
        # Save temp file
        audio_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_watermarked.wav")
        audio_file.save(audio_path)
        
        # Extract watermark using direct method
        width, height, extracted_bits = extract_image_watermark_direct(audio_path)
        
        # Move result - the utils function saves to "files/extracted_image.jpg"
        temp_result = "files/extracted_image.jpg"
        result_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_extracted.jpg")
        if os.path.exists(temp_result):
            shutil.move(temp_result, result_path)
        
        # Upload extracted image
        extracted_s3_key = f"extracted/{session_id}_extracted.jpg"
        extracted_url = upload_to_s3(result_path, extracted_s3_key)
        
        # Cleanup
        os.remove(audio_path)
        os.remove(result_path)
        
        return jsonify({
            "success": True,
            "extracted_url": extracted_url,
            "width": width,
            "height": height,
            "extracted_bits": extracted_bits,
            "message": "Image watermark extracted successfully"
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/text-watermark', methods=['POST'])
def embed_text_watermark():
    """Embed text into audio file"""
    try:
        if 'audio' not in request.files:
            return jsonify({"error": "Audio file is required"}), 400
        
        text = request.form.get('text', '')
        if not text:
            return jsonify({"error": "Text message is required"}), 400
        
        audio_file = request.files['audio']
        session_id = str(uuid.uuid4())
        
        # Save temp file
        audio_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_audio.wav")
        audio_file.save(audio_path)
        
        # Process watermarking
        text_watermark(text, audio_path)
        
        # Move result - the utils function saves to "files/wtext.wav"
        temp_result = "files/wtext.wav"
        result_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_result.wav")
        if os.path.exists(temp_result):
            shutil.move(temp_result, result_path)
        
        # Upload to S3
        result_s3_key = f"text_watermarked/{session_id}_result.wav"
        result_url = upload_to_s3(result_path, result_s3_key)
        
        # Store metadata
        metadata = {
            "session_id": session_id,
            "type": "text_watermark",
            "text": text,
            "result_url": result_url
        }
        s3_client.put_object(
            Bucket=S3_BUCKET,
            Key=f"metadata/{session_id}.json",
            Body=json.dumps(metadata),
            ContentType='application/json'
        )
        
        # Cleanup
        os.remove(audio_path)
        os.remove(result_path)
        
        return jsonify({
            "success": True,
            "session_id": session_id,
            "result_url": result_url,
            "message": "Text watermarking completed successfully"
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/text-watermark/extract', methods=['POST'])
def extract_text_watermark():
    """Extract text from watermarked audio"""
    try:
        if 'audio' not in request.files:
            return jsonify({"error": "Audio file is required"}), 400
        
        audio_file = request.files['audio']
        session_id = str(uuid.uuid4())
        
        # Save temp file
        audio_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_audio.wav")
        audio_file.save(audio_path)
        
        # Extract text
        extracted_text = extract_text_watermark(audio_path)
        
        # Cleanup
        os.remove(audio_path)
        
        return jsonify({
            "success": True,
            "extracted_text": extracted_text,
            "message": "Text watermark extracted successfully"
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/download/<filename>')
def download_file(filename):
    """Download a file by serving the S3 content directly"""
    try:
        # Get the file from S3
        s3_key = f"downloads/{filename}"
        
        # Check if file exists in different folders
        try:
            s3_client.head_object(Bucket=S3_BUCKET, Key=f"watermarked/{filename}")
            s3_key = f"watermarked/{filename}"
        except:
            try:
                s3_client.head_object(Bucket=S3_BUCKET, Key=f"image_watermarked/{filename}")
                s3_key = f"image_watermarked/{filename}"
            except:
                try:
                    s3_client.head_object(Bucket=S3_BUCKET, Key=f"text_watermarked/{filename}")
                    s3_key = f"text_watermarked/{filename}"
                except:
                    try:
                        s3_client.head_object(Bucket=S3_BUCKET, Key=f"extracted/{filename}")
                        s3_key = f"extracted/{filename}"
                    except:
                        return jsonify({"error": "File not found"}), 404
        
        # Create a temporary file to download from S3
        temp_path = os.path.join(UPLOAD_FOLDER, f"temp_{filename}")
        s3_client.download_file(S3_BUCKET, s3_key, temp_path)
        
        # Send the file
        return send_file(temp_path, as_attachment=True, download_name=filename)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/')
def index():
    """Serve the web interface"""
    return send_file('web_interface.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
