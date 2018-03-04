//
//  AssetDataManager.swift
//  DownloadStack-Example
//
//  Created by William Boles on 15/01/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation
import UIKit

struct LoadAssetResult {
    let asset: GalleryAsset
    let image: UIImage
}

extension LoadAssetResult: Equatable {
    static func ==(lhs: LoadAssetResult, rhs: LoadAssetResult) -> Bool {
        return lhs.asset == rhs.asset &&
            lhs.image == rhs.image
    }
}

class AssetDataManager {
    
    private let assetDownloadManager = AssetDownloadManager.shared
    private let fileManager = FileManager.default
    
    // MARK: - GalleryAlbum
    
    func loadAlbumThumbnailAsset(_ asset: GalleryAsset, completionHandler: @escaping ((_ result: DataRequestResult<LoadAssetResult>) -> ())) {
        if fileManager.fileExists(atPath: asset.cachedLocalAssetURL().path) {
            locallyLoadAsset(asset, completionHandler: completionHandler)
        } else {
            remotelyLoadAsset(asset, forceDownload: false, completionHandler: completionHandler)
        }
    }
    
    // MARK: - GalleryItem
    
    func loadGalleryItemAsset(_ asset: GalleryAsset, completionHandler: @escaping ((_ result: DataRequestResult<LoadAssetResult>) -> ())) {
        if fileManager.fileExists(atPath: asset.cachedLocalAssetURL().path) {
            locallyLoadAsset(asset, completionHandler: completionHandler)
        } else {
            remotelyLoadAsset(asset, forceDownload: true, completionHandler: completionHandler)
        }
    }
    
    func cancelLoadingGalleryItemAsset(_ asset: GalleryAsset) {
        assetDownloadManager.cancelDownload(url: asset.url)
    }
    
    // MARK: - Asset
    
    private func locallyLoadAsset(_ asset: GalleryAsset, completionHandler: @escaping ((_ result: DataRequestResult<LoadAssetResult>) -> ())) {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: asset.cachedLocalAssetURL().path))
            
            guard let image = UIImage(data: data) else {
                completionHandler(.failure(APIError.invalidData))
                return
            }
            
            let loadResult = LoadAssetResult(asset: asset, image: image)
            let dataRequestResult = DataRequestResult<LoadAssetResult>.success(loadResult)
            
            DispatchQueue.main.async {
                completionHandler(dataRequestResult)
            }
        } catch {
            remotelyLoadAsset(asset, forceDownload: false, completionHandler: completionHandler)
        }
    }
    
    private func remotelyLoadAsset(_ asset: GalleryAsset, forceDownload: Bool, completionHandler: @escaping ((_ result: DataRequestResult<LoadAssetResult>) -> ())) {
        
        assetDownloadManager.scheduleDownload(url: asset.url, forceDownload: forceDownload) { (result) in
            switch result {
            case .success(let data):
                guard let image = UIImage(data: data) else {
                    completionHandler(.failure(APIError.invalidData))
                    return
                }
                
                do {
                    try data.write(to: asset.cachedLocalAssetURL(), options: .atomic)
                } catch {
                    completionHandler(.failure(APIError.invalidData))
                }
                
                let loadResult = LoadAssetResult(asset: asset, image: image)
                let dataRequestResult = DataRequestResult<LoadAssetResult>.success(loadResult)
                
                DispatchQueue.main.async {
                    completionHandler(dataRequestResult)
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
}