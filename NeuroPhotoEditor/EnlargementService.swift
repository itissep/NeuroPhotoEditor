import UIKit
import CoreImage
import Vision
import CoreImage.CIFilterBuiltins

class EnlargementService {
    
    static func execute(
        on image: UIImage,
        eyesScale: CGFloat,
        browsScale: CGFloat,
        faceScale: CGFloat,
        noseScale: CGFloat,
        lipsScale: CGFloat,
        completion: @escaping (UIImage?) -> Void
    ) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let request = VNDetectFaceLandmarksRequest { (request, error) in
            guard let results = request.results as? [VNFaceObservation], !results.isEmpty else {
                completion(nil)
                return
            }
            var ciImage = CIImage(cgImage: cgImage)
            
            for face in results {
                if let landmarks = face.landmarks {
                    
                    if let leftEyebrowPoints = landmarks.leftEyebrow?.normalizedPoints {
                        ciImage = edit(
                            unnormalize(leftEyebrowPoints, boundingBox: face.boundingBox, imageSize: image.size),
                            on: ciImage,
                            with: browsScale
                        )
                    }
                    
                    if let rightEyebrowPoints = landmarks.rightEyebrow?.normalizedPoints {
                        ciImage = edit(
                            unnormalize(rightEyebrowPoints, boundingBox: face.boundingBox, imageSize: image.size),
                            on: ciImage,
                            with: browsScale
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
                    
                    if let facePoints = landmarks.faceContour?.normalizedPoints {
                        ciImage = edit(
                            unnormalize(facePoints, boundingBox: face.boundingBox, imageSize: image.size),
                            on: ciImage,
                            with: faceScale
                        )
                    }
                }
            }
            
            let context = CIContext()
            if let outputCGImage = context.createCGImage(ciImage, from: ciImage.extent) {
                completion(UIImage(cgImage: outputCGImage))
            } else {
                completion(nil)
            }
        }
        
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
