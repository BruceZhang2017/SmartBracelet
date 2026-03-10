//
//  WatchFaceInfo.swift
//  WatchFaceSDK
//
//  Created by bruce on 2025/12/30.
//

import Foundation

// MARK: - 表盘信息模型
public struct WatchFaceInfo: Codable {
    public let id: String
    public let name: String
    public let previewURL: URL
    public let resourceURL: URL
    public let fileSize: Int
    public let category: String
    public let supportedScreenSizes: [ScreenSize]
    public let shape: ScreenShape

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case previewURL = "previewPic"
        case resourceURL = "resourcesUrl"
        case fileSize
        case category
        case supportedScreenSizes
        case shape
    }

    public init(
        id: String,
        name: String,
        previewURL: URL,
        resourceURL: URL,
        fileSize: Int,
        category: String,
        supportedScreenSizes: [ScreenSize],
        shape: ScreenShape
    ) {
        self.id = id
        self.name = name
        self.previewURL = previewURL
        self.resourceURL = resourceURL
        self.fileSize = fileSize
        self.category = category
        self.supportedScreenSizes = supportedScreenSizes
        self.shape = shape
    }
}

// MARK: - 屏幕形状
public enum ScreenShape: String, Codable {
    case round = "round"
    case square = "square"
}

// MARK: - 屏幕尺寸
public struct ScreenSize: Codable, Hashable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    public var cgSize: CGSize {
        return CGSize(width: width, height: height)
    }
}

// MARK: - 表盘分类
public struct WatchFaceCategory: Codable {
    public let id: String
    public let name: String
    public let watchFaces: [WatchFaceInfo]

    enum CodingKeys: String, CodingKey {
        case id = "type"
        case name = "typeName"
        case watchFaces = "items"
    }

    public init(id: String, name: String, watchFaces: [WatchFaceInfo]) {
        self.id = id
        self.name = name
        self.watchFaces = watchFaces
    }
}

// MARK: - 设备屏幕信息
public struct DeviceScreenInfo {
    public let width: Int
    public let height: Int
    public let shape: ScreenShape
    public let mtu: Int

    public init(width: Int, height: Int, shape: ScreenShape, mtu: Int) {
        self.width = width
        self.height = height
        self.shape = shape
        self.mtu = mtu
    }

    public var size: ScreenSize {
        return ScreenSize(width: width, height: height)
    }
}
