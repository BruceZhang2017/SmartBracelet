//
//  ImageCropper.swift
//  WatchFaceSDK
//
//  Created by bruce on 2025/12/30.
//

import UIKit
import CoreImage
import WatchProtocolSDK

// MARK: - 图片裁剪工具
public class ImageCropper {

    // MARK: - 公开方法

    /// 裁剪为圆形（高质量，边缘柔和抗锯齿）
    /// - Parameters:
    ///   - image: 原始图片
    ///   - blurRadius: 边缘模糊半径，范围 1.2~2.5，默认 1.8
    ///   - upscaleFactor: 超采样倍数，默认 2.0，提高边缘质量
    /// - Returns: 裁剪后的圆形图片
    public static func cropToCircle(
        image: UIImage,
        blurRadius: Double = 1.8,
        upscaleFactor: CGFloat = 2.0
    ) -> UIImage? {
        return image.croppedToCircleSmooth(blurRadius: blurRadius, upscaleFactor: upscaleFactor)
    }

    /// 裁剪为方形（居中裁剪）
    /// - Parameters:
    ///   - image: 原始图片
    ///   - targetSize: 目标尺寸
    /// - Returns: 裁剪后的方形图片
    public static func cropToSquare(image: UIImage, targetSize: CGSize) -> UIImage? {
        guard let cgImage = image.cgImage else {
            XLogger.shared.log("❌ cropToSquare: 无法获取 CGImage")
            return nil
        }

        let originalSize = image.size
        let minDimension = min(originalSize.width, originalSize.height)

        // 计算居中裁剪区域
        let scale = image.scale
        let cropRect = CGRect(
            x: ((originalSize.width - minDimension) / 2) * scale,
            y: ((originalSize.height - minDimension) / 2) * scale,
            width: minDimension * scale,
            height: minDimension * scale
        )

        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            XLogger.shared.log("❌ cropToSquare: 裁剪失败")
            return nil
        }

        // 缩放到目标尺寸
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0
        format.opaque = false

        let result = UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            UIImage(cgImage: croppedCGImage).draw(in: CGRect(origin: .zero, size: targetSize))
        }

        XLogger.shared.log("✅ cropToSquare: 成功裁剪方形图片 (尺寸: \(targetSize))")
        return result
    }

    /// 根据屏幕形状自动裁剪
    /// - Parameters:
    ///   - image: 原始图片
    ///   - shape: 屏幕形状
    ///   - targetSize: 目标尺寸
    /// - Returns: 裁剪后的图片
    public static func cropForScreenShape(
        image: UIImage,
        shape: ScreenShape,
        targetSize: CGSize
    ) -> UIImage? {
        switch shape {
        case .round:
            // 圆形屏幕：先裁剪为正方形，再裁剪为圆形
            let squareSize = CGSize(width: max(targetSize.width, targetSize.height),
                                   height: max(targetSize.width, targetSize.height))
            guard let squareImage = cropToSquare(image: image, targetSize: squareSize) else {
                return nil
            }
            return cropToCircle(image: squareImage)

        case .square:
            // 方形屏幕：直接裁剪为指定尺寸
            return cropToSquare(image: image, targetSize: targetSize)
        }
    }
}

// MARK: - UIImage 扩展（圆形裁剪）
extension UIImage {

    /// 高质量圆形裁剪 - 边缘柔和抗锯齿
    /// - Parameters:
    ///   - blurRadius: 边缘模糊半径，范围 1.2~2.5，默认 1.8
    ///   - upscaleFactor: 超采样倍数，默认 2.0，提高边缘质量
    /// - Returns: 裁剪后的圆形图片，失败返回 nil
    func croppedToCircleSmooth(blurRadius: Double = 1.8, upscaleFactor: CGFloat = 2.0) -> UIImage? {
        guard let cgImage = self.cgImage else {
            XLogger.shared.log("❌ croppedToCircleSmooth: 无法获取 CGImage")
            return nil
        }

        let originalSize = size
        let diameter = min(originalSize.width, originalSize.height)

        // 参数校验
        guard diameter > 0 else {
            XLogger.shared.log("❌ croppedToCircleSmooth: 无效的图片尺寸")
            return nil
        }

        // 1. 高效裁剪正方形（使用 scale 考虑 Retina 屏幕）
        let scale = self.scale
        let cropRect = CGRect(
            x: ((originalSize.width - diameter) / 2) * scale,
            y: ((originalSize.height - diameter) / 2) * scale,
            width: diameter * scale,
            height: diameter * scale
        )

        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            XLogger.shared.log("❌ croppedToCircleSmooth: 裁剪失败")
            return nil
        }

        // 2. 计算超采样尺寸
        let bigSize = diameter * upscaleFactor
        let finalSize = CGSize(width: diameter, height: diameter)

        // 3. 创建圆形遮罩
        guard let maskImage = createCircleMask(size: bigSize, blurRadius: blurRadius) else {
            XLogger.shared.log("❌ croppedToCircleSmooth: 遮罩创建失败")
            return nil
        }

        // 4. 处理内容图像（超采样提升质量）
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0  // 使用固定 scale 避免设备差异
        format.opaque = false

        let enhancedContent = UIGraphicsImageRenderer(
            size: CGSize(width: bigSize, height: bigSize),
            format: format
        ).image { _ in
            UIImage(cgImage: croppedCGImage).draw(
                in: CGRect(origin: .zero, size: CGSize(width: bigSize, height: bigSize))
            )
        }

        // 5. 合成最终图像
        let result = UIGraphicsImageRenderer(size: finalSize, format: format).image { context in
            // 先缩放内容到最终尺寸
            enhancedContent.draw(in: CGRect(origin: .zero, size: finalSize))
            // 缩放遮罩到最终尺寸
            maskImage.draw(in: CGRect(origin: .zero, size: finalSize), blendMode: .destinationIn, alpha: 1.0)
        }

        XLogger.shared.log("✅ croppedToCircleSmooth: 成功裁剪圆形图片 (直径: \(diameter))")
        return result
    }

    /// 创建带模糊边缘的圆形遮罩
    private func createCircleMask(size: CGFloat, blurRadius: Double) -> UIImage? {
        // 1. 创建纯白圆形
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0
        format.opaque = false

        let circleMask = UIGraphicsImageRenderer(
            size: CGSize(width: size, height: size),
            format: format
        ).image { context in
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
        }

        guard let maskCGImage = circleMask.cgImage else { return nil }

        // 2. 应用高斯模糊
        let ciImage = CIImage(cgImage: maskCGImage)

        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else {
            XLogger.shared.log("⚠️ 高斯模糊滤镜创建失败，使用无模糊遮罩")
            return circleMask
        }

        blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter.setValue(blurRadius, forKey: kCIInputRadiusKey)

        guard let outputCI = blurFilter.outputImage else { return circleMask }

        // 使用共享的 CIContext（避免重复创建）
        let ciContext = CIContext.shared
        guard let blurredCGImage = ciContext.createCGImage(outputCI, from: outputCI.extent) else {
            return circleMask
        }

        return UIImage(cgImage: blurredCGImage)
    }
}

// MARK: - CIContext 共享实例
private extension CIContext {
    static let shared: CIContext = {
        let options: [CIContextOption: Any] = [
            .useSoftwareRenderer: false,  // 使用 GPU 加速
            .priorityRequestLow: false     // 高优先级处理
        ]
        return CIContext(options: options)
    }()
}
