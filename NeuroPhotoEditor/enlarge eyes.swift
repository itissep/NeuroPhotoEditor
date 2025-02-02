import UIKit
import CoreImage
import Vision
import CoreImage.CIFilterBuiltins

class EyeEnlargementService {
    static func enlargeEyes(
        on image: UIImage,
        eyesScale: CGFloat,
        faceScale: CGFloat,
        noseScale: CGFloat,
        lipsScale: CGFloat,
        completion: @escaping (UIImage?) -> Void
    ) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        // Создаем запрос для распознавания лиц
        let request = VNDetectFaceLandmarksRequest { (request, error) in
            guard let results = request.results as? [VNFaceObservation], !results.isEmpty else {
                completion(nil)
                return
            }
            
            // Преобразуем изображение в CIImage для дальнейшей обработки
            var ciImage = CIImage(cgImage: cgImage)
            
            // Обрабатываем каждое лицо
            for face in results {
                if let landmarks = face.landmarks {
                    
                    if let facePoints = landmarks.faceContour?.normalizedPoints {
                        ciImage = edit(
                            unnormalize(facePoints, boundingBox: face.boundingBox, imageSize: image.size),
                            on: ciImage,
                            with: faceScale
                        )
                    }
                    
                    if let leftEyePoints = landmarks.leftEye?.normalizedPoints {
                        ciImage = edit(
                            unnormalize(leftEyePoints, boundingBox: face.boundingBox, imageSize: image.size),
                            on: ciImage,
                            with: eyesScale
                        )
                    }
                    if let rightEyePoints = landmarks.rightEye?.normalizedPoints {
                        ciImage = edit(
                            unnormalize(rightEyePoints, boundingBox: face.boundingBox, imageSize: image.size),
                            on: ciImage,
                            with: eyesScale
                        )
                    }
                    
                    if let nosePoints = landmarks.nose?.normalizedPoints {
                        ciImage = edit(
                            unnormalize(nosePoints, boundingBox: face.boundingBox, imageSize: image.size),
                            on: ciImage,
                            with: noseScale
                        )
                    }
                    
                    if let lipsPoints = landmarks.outerLips?.normalizedPoints {
                        ciImage = edit(
                            unnormalize(lipsPoints, boundingBox: face.boundingBox, imageSize: image.size),
                            on: ciImage,
                            with: lipsScale
                        )
                    }
                }
            }
            
            // Конвертируем обработанное изображение обратно в UIImage
            let context = CIContext()
            if let outputCGImage = context.createCGImage(ciImage, from: ciImage.extent) {
                completion(UIImage(cgImage: outputCGImage))
            } else {
                completion(nil)
            }
        }
        
        // Создаем обработчик изображения
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            completion(nil)
        }
    }
    
    private static func edit(_ points: [CGPoint], on image: CIImage, with scale: CGFloat) -> CIImage {
        applyBumpDistortion(
            to: image,
            center: calculateCenter(from: points),
            radius: calculateRadius(from: points),
            scale: scale
        )
    }
    
    private static func calculateRadius(from points: [CGPoint]) -> CGFloat {
        guard
            let minX = points.sorted(by: { $0.x < $1.x }).first,
            let minY = points.sorted(by: { $0.y < $1.y }).first,
            let maxX = points.sorted(by: { $0.x > $1.x }).first,
            let maxY = points.sorted(by: { $0.y > $1.y }).first
        else { return 0 }
        
        let width = maxX.x - minX.x
        let height = maxY.y - minY.y
        
        return max(width, height) + 10
    }
    
    private static func unnormalize(_ points: [CGPoint], boundingBox: CGRect, imageSize: CGSize) -> [CGPoint] {
        points.map { point -> CGPoint in
            let x = boundingBox.origin.x + point.x * boundingBox.size.width
            let y = boundingBox.origin.y + point.y * boundingBox.size.height
            return CGPoint(x: x * imageSize.width, y: y * imageSize.height)
        }
    }
    
    private static func calculateCenter(from points: [CGPoint]) -> CGPoint {
        let centerX = points.map { $0.x }.reduce(0, +) / CGFloat(points.count)
        let centerY = points.map { $0.y }.reduce(0, +) / CGFloat(points.count)
        
        return CGPoint(x: centerX, y: centerY)
    }
    
    private static func applyBumpDistortion(to image: CIImage, center: CGPoint, radius: CGFloat, scale: CGFloat) -> CIImage {
        let filter = CIFilter.bumpDistortion()
        filter.center = center
        filter.scale = Float(scale)
        filter.radius = Float(radius)
        filter.inputImage = image
        
        return filter.outputImage!
    }
}
