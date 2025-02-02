import SwiftUI
import Vision

struct ContentView: View {
    @State var inputImage: UIImage?
    @State var outputImage: UIImage?
    @State private var showingImagePicker = false
    
    @State var faceOvalScale: CGFloat = 0
    @State var eyeScale: CGFloat = 0
    @State var noseScale: CGFloat = 0
    @State var lipsScale: CGFloat = 0
    @State var browsScale: CGFloat = 0
    
    var body: some View {
        VStack {
            Text("neuro photo editor")
                .font(.largeTitle)
                .monospaced()
                .padding(.vertical, Constants.spacing)
                .foregroundStyle(.text)
                
                Group {
                    if let outputImage = outputImage {
                        Image(uiImage: outputImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: Constants.imageSize, height: Constants.imageSize)
                            .clipShape(.rect(cornerRadius: Constants.cornerRadius))
                            .padding()
                    } else {
                        if let inputImage {
                            Image(uiImage: inputImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: Constants.imageSize, height: Constants.imageSize)
                                .clipShape(.rect(cornerRadius: Constants.cornerRadius))
                                .padding()
                                .opacity(Constants.disabledOpacity)
                                .overlay {
                                    Text("edit something")
                                        .monospaced()
                                        .foregroundStyle(.text)
                                }
                            
                        } else {
                            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                                .foregroundStyle(Constants.secondaryBackground)
                                .frame(width: Constants.imageSize, height: Constants.imageSize)
                                .overlay {
                                    Text("tap hare")
                                        .monospaced()
                                        .foregroundStyle(.text)
                                }
                        }
                    }
                }.onTapGesture {
                    showingImagePicker = true
                }
                .padding(.horizontal, Constants.spacing)
            
            VStack(spacing: Constants.spacing) {
                VStack(alignment: .leading) {
                    SliderLabel(text: "eyes")
                    Slider(value: $eyeScale, in: 0...1.0, step: 0.1) { _ in update() }
                }
                VStack(alignment: .leading) {
                    SliderLabel(text: "nose")
                    Slider(value: $noseScale, in: 0...1.5, step: 0.1) { _ in update() }
                }
                VStack(alignment: .leading) {
                    SliderLabel(text: "lips")
                    Slider(value: $lipsScale, in: 0...1.0, step: 0.1) { _ in update() }
                }
                VStack(alignment: .leading) {
                    SliderLabel(text:"brows")
                    Slider(value: $browsScale, in: 0...1.5, step: 0.1) { _ in update() }
                }
                VStack(alignment: .leading) {
                    SliderLabel(text: "face")
                    Slider(value: $faceOvalScale, in: 0...0.5, step: 0.1) { _ in update() }
                }
            }
            .padding()
            .opacity(inputImage == nil ? Constants.disabledOpacity : 1)
            .disabled(inputImage == nil)
            
            VStack {
                Button("pick new photo") {
                    showingImagePicker = true
                }
                .monospaced()
                .frame(maxWidth: .infinity)
                .frame(height: Constants.buttonHeight)
                .foregroundStyle(.background)
                .background {
                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                        .foregroundStyle(.accent)
                }
                
                
                Button("drow face features") {
                    if inputImage != nil {
                        drawFeatures()
                    }
                }
                .monospaced()
                .frame(maxWidth: .infinity)
                .frame(height: Constants.buttonHeight)
                .background {
                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                        .foregroundStyle(Constants.secondaryBackground)
                }
                .disabled(inputImage == nil)
            }
            .padding()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $inputImage) {
                outputImage = nil
            }
        }
    }
    
    private func update() {
        if let inputImage {
            EyeEnlargementService.enlargeEyes(
                on: inputImage,
                eyesScale: eyeScale,
                faceScale: faceOvalScale,
                noseScale: noseScale,
                lipsScale: lipsScale
            ) { image in
                DispatchQueue.main.async {
                    outputImage = image
                }
            }
        }
    }
}

extension ContentView {
    enum Constants {
        static let buttonHeight: CGFloat = 42
        static let imageSize: CGFloat = 250
        
        static let cornerRadius: CGFloat = 10
        
        static let disabledOpacity: CGFloat = 0.64
        
        static let secondaryBackground: Color = .accentColor.opacity(0.2)
        
        static let spacing: CGFloat = 20
    }
}

struct SliderLabel: View {
    var text: String
    
    var body: some View {
        Text(text)
            .font(.footnote)
            .monospaced()
            .foregroundStyle(.text)
    }
}
