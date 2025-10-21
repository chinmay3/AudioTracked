import SwiftUI
import UniformTypeIdentifiers

// MARK: - Audio Watermark ViewModel
@MainActor
class WatermarkViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var resultURL: String?
    @Published var sessionId: String?
    @Published var hostAudioData: Data?
    @Published var watermarkAudioData: Data?
    @Published var hostAudioName: String?
    @Published var watermarkAudioName: String?
    @Published var showHostAudioPicker = false
    @Published var showWatermarkAudioPicker = false
    @Published var showExtractAudioPicker = false
    @Published var extractedAudioURL: String?
    
    func handleHostAudioSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                self.hostAudioData = data
                self.hostAudioName = url.lastPathComponent
            } catch {
                self.errorMessage = "Failed to load audio file: \(error.localizedDescription)"
            }
        case .failure(let error):
            self.errorMessage = error.localizedDescription
        }
    }
    
    func handleWatermarkAudioSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                self.watermarkAudioData = data
                self.watermarkAudioName = url.lastPathComponent
            } catch {
                self.errorMessage = "Failed to load audio file: \(error.localizedDescription)"
            }
        case .failure(let error):
            self.errorMessage = error.localizedDescription
        }
    }
    
    func embedAudioWatermark() async {
        guard let hostData = hostAudioData,
              let watermarkData = watermarkAudioData else {
            errorMessage = "Please select both audio files"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        do {
            let response = try await APIService.shared.embedAudioWatermark(
                hostAudio: hostData,
                watermarkAudio: watermarkData
            )
            
            self.resultURL = response.resultUrl
            self.sessionId = response.sessionId
            
        } catch {
            self.errorMessage = "Failed to embed watermark: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
    
    func downloadFile(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileName = "watermarked_\(UUID().uuidString).wav"
                let fileURL = documentsPath.appendingPathComponent(fileName)
                
                try data.write(to: fileURL)
                
                // Present share sheet
                await MainActor.run {
                    presentShareSheet(fileURL: fileURL)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to download file: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func handleExtractAudioSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                Task {
                    await extractAudioWatermark(audioData: data)
                }
            } catch {
                self.errorMessage = "Failed to load audio file: \(error.localizedDescription)"
            }
        case .failure(let error):
            self.errorMessage = error.localizedDescription
        }
    }
    
    func extractAudioWatermark(audioData: Data) async {
        isProcessing = true
        errorMessage = nil
        
        do {
            let response = try await APIService.shared.extractAudioWatermarkDirect(audio: audioData)
            self.extractedAudioURL = response.extractedUrl
        } catch {
            self.errorMessage = "Failed to extract audio: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
    
    private func presentShareSheet(fileURL: URL) {
        // This would be implemented in the view to show a share sheet
        // For now, we'll just show a success message
        print("File downloaded to: \(fileURL)")
    }
}

// MARK: - Image Watermark ViewModel
@MainActor
class ImageWatermarkViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var resultURL: String?
    @Published var audioData: Data?
    @Published var imageData: Data?
    @Published var audioName: String?
    @Published var imageName: String?
    @Published var showAudioPicker = false
    @Published var showImagePicker = false
    @Published var showExtractImagePicker = false
    @Published var extractedImageURL: String?
    
    func handleAudioSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                self.audioData = data
                self.audioName = url.lastPathComponent
            } catch {
                self.errorMessage = "Failed to load audio file: \(error.localizedDescription)"
            }
        case .failure(let error):
            self.errorMessage = error.localizedDescription
        }
    }
    
    func handleImageSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                self.imageData = data
                self.imageName = url.lastPathComponent
            } catch {
                self.errorMessage = "Failed to load image file: \(error.localizedDescription)"
            }
        case .failure(let error):
            self.errorMessage = error.localizedDescription
        }
    }
    
    func embedImageWatermark() async {
        guard let audioData = audioData,
              let imageData = imageData else {
            errorMessage = "Please select both audio and image files"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        do {
            let response = try await APIService.shared.embedImageWatermark(
                audio: audioData,
                image: imageData
            )
            
            self.resultURL = response.resultUrl
            
        } catch {
            self.errorMessage = "Failed to embed watermark: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
    
    func downloadFile(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileName = "image_watermarked_\(UUID().uuidString).wav"
                let fileURL = documentsPath.appendingPathComponent(fileName)
                
                try data.write(to: fileURL)
                
                await MainActor.run {
                    print("File downloaded to: \(fileURL)")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to download file: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func handleExtractImageSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                Task {
                    await extractImageWatermark(audioData: data)
                }
            } catch {
                self.errorMessage = "Failed to load audio file: \(error.localizedDescription)"
            }
        case .failure(let error):
            self.errorMessage = error.localizedDescription
        }
    }
    
    func extractImageWatermark(audioData: Data) async {
        isProcessing = true
        errorMessage = nil
        
        do {
            let response = try await APIService.shared.extractImageWatermarkDirect(audio: audioData)
            self.extractedImageURL = response.extractedUrl
        } catch {
            self.errorMessage = "Failed to extract image: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
}

// MARK: - Text Watermark ViewModel
@MainActor
class TextWatermarkViewModel: ObservableObject {
    @Published var secretText = ""
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var resultURL: String?
    @Published var audioData: Data?
    @Published var audioName: String?
    @Published var showAudioPicker = false
    @Published var showExtractTextPicker = false
    @Published var extractedText: String?
    
    func handleAudioSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                self.audioData = data
                self.audioName = url.lastPathComponent
            } catch {
                self.errorMessage = "Failed to load audio file: \(error.localizedDescription)"
            }
        case .failure(let error):
            self.errorMessage = error.localizedDescription
        }
    }
    
    func embedTextWatermark() async {
        guard let audioData = audioData,
              !secretText.isEmpty else {
            errorMessage = "Please select an audio file and enter text"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        do {
            let response = try await APIService.shared.embedTextWatermark(
                audio: audioData,
                text: secretText
            )
            
            self.resultURL = response.resultUrl
            
        } catch {
            self.errorMessage = "Failed to embed watermark: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
    
    func downloadFile(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileName = "text_watermarked_\(UUID().uuidString).wav"
                let fileURL = documentsPath.appendingPathComponent(fileName)
                
                try data.write(to: fileURL)
                
                await MainActor.run {
                    print("File downloaded to: \(fileURL)")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to download file: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func handleExtractTextSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                Task {
                    await extractTextWatermark(audioData: data)
                }
            } catch {
                self.errorMessage = "Failed to load audio file: \(error.localizedDescription)"
            }
        case .failure(let error):
            self.errorMessage = error.localizedDescription
        }
    }
    
    func extractTextWatermark(audioData: Data) async {
        isProcessing = true
        errorMessage = nil
        
        do {
            let response = try await APIService.shared.extractTextWatermark(audio: audioData)
            self.extractedText = response.extractedText
        } catch {
            self.errorMessage = "Failed to extract text: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
}
