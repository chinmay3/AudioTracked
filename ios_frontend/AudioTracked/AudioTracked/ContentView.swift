import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AudioWatermarkView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "waveform.circle.fill" : "waveform.circle")
                    Text("Audio")
                }
                .tag(0)
            
            ImageWatermarkView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "photo.circle.fill" : "photo.circle")
                    Text("Image")
                }
                .tag(1)
            
            TextWatermarkView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "text.bubble.fill" : "text.bubble")
                    Text("Text")
                }
                .tag(2)
        }
        .accentColor(.purple)
        .preferredColorScheme(.dark)
    }
}

struct AudioWatermarkView: View {
    @StateObject private var viewModel = WatermarkViewModel()
    @State private var animateGradient = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header Section
                    headerSection
                    
                    // File Selection Cards
                    VStack(spacing: 20) {
                        fileSelectionCard(
                            title: "Host Audio",
                            subtitle: "The main audio file",
                            fileName: viewModel.hostAudioName,
                            icon: "waveform.circle.fill",
                            color: .blue,
                            action: { viewModel.showHostAudioPicker = true }
                        )
                        
                        fileSelectionCard(
                            title: "Watermark Audio", 
                            subtitle: "The audio to hide inside",
                            fileName: viewModel.watermarkAudioName,
                            icon: "waveform.badge.plus",
                            color: .purple,
                            action: { viewModel.showWatermarkAudioPicker = true }
                        )
                    }
                    
                    // Process Button
                    processButton
                    
                    // Results Section
                    resultsSection
                    
                    // Extraction Section
                    extractionSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(
                LinearGradient(
                    colors: [.black, .purple.opacity(0.1), .black],
                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                )
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
            )
            .navigationTitle("Audio Steganography")
            .navigationBarTitleDisplayMode(.large)
            .fileImporter(
                isPresented: $viewModel.showHostAudioPicker,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false
            ) { result in
                viewModel.handleHostAudioSelection(result: result)
            }
            .fileImporter(
                isPresented: $viewModel.showWatermarkAudioPicker,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false
            ) { result in
                viewModel.handleWatermarkAudioSelection(result: result)
            }
            .fileImporter(
                isPresented: $viewModel.showExtractAudioPicker,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false
            ) { result in
                viewModel.handleExtractAudioSelection(result: result)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Audio in Audio")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Hide secret audio within another")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func fileSelectionCard(
        title: String,
        subtitle: String,
        fileName: String?,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let fileName = fileName {
                        Text(fileName)
                            .font(.caption)
                            .foregroundColor(.green)
                            .lineLimit(1)
                    } else {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption.weight(.semibold))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(fileName != nil ? color.opacity(0.5) : .white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var processButton: some View {
        Button(action: {
            Task {
                await viewModel.embedAudioWatermark()
            }
        }) {
            HStack {
                if viewModel.isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    
                    Text("Processing...")
                        .fontWeight(.semibold)
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(.title3)
                    
                    Text("Embed Audio Watermark")
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: canProcess ? [.purple, .blue, .purple] : [.gray.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
        }
        .disabled(!canProcess || viewModel.isProcessing)
        .scaleEffect(viewModel.isProcessing ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: viewModel.isProcessing)
    }
    
    private var resultsSection: some View {
        VStack(spacing: 16) {
            // Embedding Results
            if let resultURL = viewModel.resultURL {
                resultCard(
                    title: "Watermarking Complete!",
                    message: "Your audio has been successfully watermarked",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    actionTitle: "Download Result",
                    action: { viewModel.downloadFile(from: resultURL) }
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            // Extraction Results
            if let extractedURL = viewModel.extractedAudioURL {
                resultCard(
                    title: "Audio Extracted!",
                    message: "Hidden audio has been successfully extracted",
                    icon: "arrow.down.circle.fill",
                    color: .orange,
                    actionTitle: "Download Extracted Audio",
                    action: { viewModel.downloadFile(from: extractedURL) }
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            // Error Messages
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    Text(error)
                        .foregroundColor(.white)
                        .font(.caption)
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.red.opacity(0.3), lineWidth: 1)
                        )
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.resultURL)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.extractedAudioURL)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.errorMessage)
    }
    
    private func resultCard(
        title: String,
        message: String,
        icon: String,
        color: Color,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Button(action: action) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title3)
                    
                    Text(actionTitle)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var extractionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("Extract Hidden Audio")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text("Upload a watermarked audio file to extract the hidden audio")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Button("Extract Audio") {
                viewModel.showExtractAudioPicker = true
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var canProcess: Bool {
        viewModel.hostAudioData != nil && viewModel.watermarkAudioData != nil
    }
}

struct ImageWatermarkView: View {
    @StateObject private var viewModel = ImageWatermarkViewModel()
    @State private var animateGradient = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header Section
                    headerSection
                    
                    // File Selection Cards
                    VStack(spacing: 20) {
                        fileSelectionCard(
                            title: "Audio File",
                            subtitle: "The main audio file",
                            fileName: viewModel.audioName,
                            icon: "waveform.circle.fill",
                            color: .blue,
                            action: { viewModel.showAudioPicker = true }
                        )
                        
                        fileSelectionCard(
                            title: "Secret Image", 
                            subtitle: "The image to hide inside",
                            fileName: viewModel.imageName,
                            icon: "photo.circle.fill",
                            color: .purple,
                            action: { viewModel.showImagePicker = true }
                        )
                    }
                    
                    // Process Button
                    processButton
                    
                    // Results Section
                    resultsSection
                    
                    // Extraction Section
                    extractionSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(
                LinearGradient(
                    colors: [.black, .purple.opacity(0.1), .black],
                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                )
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
            )
            .navigationTitle("Image Steganography")
            .navigationBarTitleDisplayMode(.large)
            .fileImporter(
                isPresented: $viewModel.showAudioPicker,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false
            ) { result in
                viewModel.handleAudioSelection(result: result)
            }
            .fileImporter(
                isPresented: $viewModel.showImagePicker,
                allowedContentTypes: [.image],
                allowsMultipleSelection: false
            ) { result in
                viewModel.handleImageSelection(result: result)
            }
            .fileImporter(
                isPresented: $viewModel.showExtractImagePicker,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false
            ) { result in
                viewModel.handleExtractImageSelection(result: result)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "photo.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Image in Audio")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Hide secret images within audio")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func fileSelectionCard(
        title: String,
        subtitle: String,
        fileName: String?,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let fileName = fileName {
                        Text(fileName)
                            .font(.caption)
                            .foregroundColor(.green)
                            .lineLimit(1)
                    } else {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption.weight(.semibold))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(fileName != nil ? color.opacity(0.5) : .white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var processButton: some View {
        Button(action: {
            Task {
                await viewModel.embedImageWatermark()
            }
        }) {
            HStack {
                if viewModel.isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    
                    Text("Processing...")
                        .fontWeight(.semibold)
                } else {
                    Image(systemName: "photo.badge.plus")
                        .font(.title3)
                    
                    Text("Embed Image Watermark")
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: canProcess ? [.purple, .pink, .purple] : [.gray.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
        }
        .disabled(!canProcess || viewModel.isProcessing)
        .scaleEffect(viewModel.isProcessing ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: viewModel.isProcessing)
    }
    
    private var resultsSection: some View {
        VStack(spacing: 16) {
            // Embedding Results
            if let resultURL = viewModel.resultURL {
                resultCard(
                    title: "Image Watermarking Complete!",
                    message: "Your audio now contains the hidden image",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    actionTitle: "Download Result",
                    action: { viewModel.downloadFile(from: resultURL) }
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            // Extraction Results
            if let extractedURL = viewModel.extractedImageURL {
                resultCard(
                    title: "Image Extracted!",
                    message: "Hidden image has been successfully extracted",
                    icon: "photo.circle.fill",
                    color: .orange,
                    actionTitle: "Download Extracted Image",
                    action: { viewModel.downloadFile(from: extractedURL) }
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    Text(error)
                        .foregroundColor(.white)
                        .font(.caption)
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.red.opacity(0.3), lineWidth: 1)
                        )
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.resultURL)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.extractedImageURL)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.errorMessage)
    }
    
    private func resultCard(
        title: String,
        message: String,
        icon: String,
        color: Color,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Button(action: action) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title3)
                    
                    Text(actionTitle)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var extractionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("Extract Hidden Image")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text("Upload a watermarked audio file to extract the hidden image")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Button("Extract Image") {
                viewModel.showExtractImagePicker = true
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var canProcess: Bool {
        viewModel.audioData != nil && viewModel.imageData != nil
    }
}

struct TextWatermarkView: View {
    @StateObject private var viewModel = TextWatermarkViewModel()
    @State private var animateGradient = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header Section
                    headerSection
                    
                    // Text Input Section
                    textInputSection
                    
                    // File Selection Card
                    fileSelectionCard
                    
                    // Process Button
                    processButton
                    
                    // Results Section
                    resultsSection
                    
                    // Extraction Section
                    extractionSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(
                LinearGradient(
                    colors: [.black, .blue.opacity(0.1), .black],
                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                )
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
            )
            .navigationTitle("Text Steganography")
            .navigationBarTitleDisplayMode(.large)
            .fileImporter(
                isPresented: $viewModel.showAudioPicker,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false
            ) { result in
                viewModel.handleAudioSelection(result: result)
            }
            .fileImporter(
                isPresented: $viewModel.showExtractTextPicker,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false
            ) { result in
                viewModel.handleExtractTextSelection(result: result)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Text in Audio")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Hide secret messages within audio")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Secret Message")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter your secret message:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Type your secret message...", text: $viewModel.secretText, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.white)
                    .lineLimit(3...8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var fileSelectionCard: some View {
        Button(action: { viewModel.showAudioPicker = true }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "waveform.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Audio File")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let audioName = viewModel.audioName {
                        Text(audioName)
                            .font(.caption)
                            .foregroundColor(.green)
                            .lineLimit(1)
                    } else {
                        Text("Select the audio file to watermark")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption.weight(.semibold))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(viewModel.audioName != nil ? .blue.opacity(0.5) : .white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var processButton: some View {
        Button(action: {
            Task {
                await viewModel.embedTextWatermark()
            }
        }) {
            HStack {
                if viewModel.isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    
                    Text("Processing...")
                        .fontWeight(.semibold)
                } else {
                    Image(systemName: "text.badge.plus")
                        .font(.title3)
                    
                    Text("Embed Text Watermark")
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: canProcess ? [.blue, .cyan, .blue] : [.gray.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
        }
        .disabled(!canProcess || viewModel.isProcessing)
        .scaleEffect(viewModel.isProcessing ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: viewModel.isProcessing)
    }
    
    private var resultsSection: some View {
        VStack(spacing: 16) {
            // Embedding Results
            if let resultURL = viewModel.resultURL {
                resultCard(
                    title: "Text Watermarking Complete!",
                    message: "Your audio now contains the hidden message",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    actionTitle: "Download Result",
                    action: { viewModel.downloadFile(from: resultURL) }
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            // Extraction Results
            if let extractedText = viewModel.extractedText {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "text.bubble.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Text Extracted!")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Hidden message found in audio")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Extracted Message:")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text(extractedText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.orange.opacity(0.1))
                            )
                            .foregroundColor(.white)
                            .font(.body)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.orange.opacity(0.3), lineWidth: 1)
                        )
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    Text(error)
                        .foregroundColor(.white)
                        .font(.caption)
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.red.opacity(0.3), lineWidth: 1)
                        )
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.resultURL)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.extractedText)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.errorMessage)
    }
    
    private func resultCard(
        title: String,
        message: String,
        icon: String,
        color: Color,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Button(action: action) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title3)
                    
                    Text(actionTitle)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var extractionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("Extract Hidden Text")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text("Upload a watermarked audio file to extract the hidden message")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Button("Extract Text") {
                viewModel.showExtractTextPicker = true
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var canProcess: Bool {
        !viewModel.secretText.isEmpty && viewModel.audioData != nil
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
