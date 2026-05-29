import Foundation
import LocalMindKitCore
import Photos
import UIKit

struct PhotoLibrarySource {
  func requestAuthorization() async -> PHAuthorizationStatus {
    await withCheckedContinuation { continuation in
      PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
        continuation.resume(returning: status)
      }
    }
  }

  func fetchScreenshotAssets(limit: Int = 200) -> [PHAsset] {
    let options = PHFetchOptions()
    options.fetchLimit = limit
    let screenshots = PHAssetCollection.fetchAssetCollections(
      with: .smartAlbum, subtype: .smartAlbumScreenshots, options: nil)
    guard let screenshotsAlbum = screenshots.firstObject else { return [] }

    let fetch = PHAsset.fetchAssets(in: screenshotsAlbum, options: options)
    var assets: [PHAsset] = []
    fetch.enumerateObjects { asset, _, _ in assets.append(asset) }
    return assets
  }

  func makeIngestItem(asset: PHAsset, targetSize: CGSize = CGSize(width: 2048, height: 2048)) async
    -> IngestItem?
  {
    await withCheckedContinuation { continuation in
      let options = PHImageRequestOptions()
      options.deliveryMode = .highQualityFormat
      options.isSynchronous = false
      options.resizeMode = .fast
      options.isNetworkAccessAllowed = false

      PHImageManager.default().requestImage(
        for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options
      ) { image, _ in
        guard let image, let data = image.jpegData(compressionQuality: 0.85) else {
          continuation.resume(returning: nil)
          return
        }
        let item = IngestItem(
          externalID: asset.localIdentifier,
          displayName: "Screenshot \(asset.localIdentifier.prefix(8))",
          fileType: .image,
          sizeBytes: Int64(data.count),
          data: data,
          createdAt: asset.creationDate,
          modifiedAt: asset.modificationDate
        )
        continuation.resume(returning: item)
      }
    }
  }
}
