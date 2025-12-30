//
//  ImageProcessor.swift
//  WatchFaceSDK
//
//  Created by ANKER on 2025/12/30.
//

import UIKit
import ABParTool
import WatchProtocolSDK

// MARK: - 图片处理器
public class ImageProcessor {

    // MARK: - 公开方法

    /// 压缩并转换图片为 PAR 格式
    /// - Parameters:
    ///   - image: 原始图片
    ///   - targetSize: 目标尺寸
    ///   - maxFileSize: 最大文件大小（字节），默认 120KB
    /// - Returns: PAR 格式数据
    /// - Throws: WatchFaceError
    public static func convertToPAR(
        image: UIImage,
        targetSize: CGSize,
        maxFileSize: Int = 120 * 1024
    ) throws -> Data {

        XLogger.shared.log("🔄 开始转换图片为PAR格式 - 目标尺寸: \(targetSize)")

        // 1. 调整图片尺寸
        guard let resizedImage = resizeImage(image, to: targetSize) else {
            XLogger.shared.log("❌ 图片尺寸调整失败")
            throw WatchFaceError.imageProcessFailed
        }

        // 2. 循环压缩直到满足大小要求
        var currentImage = resizedImage
        var attemptCount = 0
        let maxAttempts = 10

        while attemptCount < maxAttempts {
            guard let rawImageData = currentImage.rawImageData else {
                XLogger.shared.log("❌ 无法获取图片原始数据")
                throw WatchFaceError.rawDataConversionFailed
            }

            XLogger.shared.log("📊 尝试 \(attemptCount + 1): 原始数据大小 = \(rawImageData.count) bytes")

            // 转换为 PAR 格式
            if let parData = ParTool.par(
                fromRaw: rawImageData,
                width: Int32(targetSize.width),
                height: Int32(targetSize.height),
                runAlpha: false,
                useFilter: false,
                supportRotate: false
            ) {
                XLogger.shared.log("📦 PAR 数据大小: \(parData.count) bytes (限制: \(maxFileSize) bytes)")

                if parData.count <= maxFileSize {
                    XLogger.shared.log("✅ PAR 转换成功: \(parData.count) bytes")
                    return parData
                }

                XLogger.shared.log("⚠️ PAR 文件过大，继续压缩...")

                // 继续压缩
                let quality = max(0.1, 0.9 - Double(attemptCount) * 0.1)
                guard let compressedData = currentImage.jpegData(compressionQuality: quality),
                      let compressedImage = UIImage(data: compressedData) else {
                    XLogger.shared.log("❌ JPEG 压缩失败")
                    throw WatchFaceError.compressionFailed
                }
                currentImage = compressedImage
                XLogger.shared.log("🔄 图片已压缩，质量系数: \(quality)")
            } else {
                XLogger.shared.log("❌ PAR 转换失败")
                throw WatchFaceError.imageProcessFailed
            }

            attemptCount += 1
        }

        XLogger.shared.log("❌ 超过最大尝试次数 (\(maxAttempts))，无法满足文件大小要求")
        throw WatchFaceError.exceedMaxAttempts
    }

    /// 调整图片尺寸
    /// - Parameters:
    ///   - image: 原始图片
    ///   - targetSize: 目标尺寸
    /// - Returns: 调整后的图片
    public static func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0  // 固定 scale 避免设备差异
        format.opaque = false

        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    /// 压缩图片到指定文件大小
    /// - Parameters:
    ///   - image: 原始图片
    ///   - maxLength: 最大文件大小（KB）
    /// - Returns: 压缩后的图片数据
    public static func compressImage(_ image: UIImage, maxLength: Int) -> Data? {
        var quality: CGFloat = 1.0
        var imageData = image.jpegData(compressionQuality: quality)

        let maxSize = maxLength * 1024

        guard var data = imageData else { return nil }

        // 逐步降低质量直到满足大小要求
        while data.count > maxSize && quality > 0.1 {
            quality -= 0.1
            if let compressed = image.jpegData(compressionQuality: quality) {
                data = compressed
                imageData = compressed
            } else {
                break
            }
        }

        XLogger.shared.log("🔄 图片压缩完成: \(data.count) bytes (质量: \(quality))")
        return data
    }

    /// 降低图片 RGB 值（从 256 降到 64）
    /// - Parameters:
    ///   - image: 原始图片
    ///   - targetSize: 目标尺寸
    /// - Returns: 处理后的图片
    public static func reduceRGBValues(image: UIImage, targetSize: CGSize) -> UIImage? {
        // 首先调整图像大小
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = resizedImage?.cgImage else {
            return nil
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        let bytesPerRow = bytesPerPixel * width
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        if let pixelData = context.data {
            let data = pixelData.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
            for y in 0..<height {
                for x in 0..<width {
                    let index = (y * width + x) * bytesPerPixel

                    // 将 RGB 值从 256 降到 64
                    data[index] = (data[index] / 4) * 4
                    data[index + 1] = (data[index + 1] / 4) * 4
                    data[index + 2] = (data[index + 2] / 4) * 4
                }
            }
        }

        guard let newCGImage = context.makeImage() else {
            return nil
        }

        return UIImage(cgImage: newCGImage)
    }
}

// MARK: - UIImage 扩展
extension UIImage {

    /// 获取图片的原始数据
    var rawImageData: Data? {
        guard let cgImage = self.cgImage else {
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height
        let bitsPerComponent = 8
        let bytesPerRow = width * 4

        var rawData = Data(count: height * bytesPerRow)

        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return rawData
    }
}
