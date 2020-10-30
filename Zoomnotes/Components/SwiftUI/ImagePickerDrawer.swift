//
//  ImagePickerDrawer.swift
//  Zoomnotes
//
//  Created by Berci on 2020. 10. 01..
//  Copyright © 2020. Berci. All rights reserved.
//

import Foundation
import SwiftUI
import Photos

class PhotoManager: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    private var photos = PHFetchResult<PHAsset>()
    @Published var images: [UIImage] = []

    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)

        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        PHAsset.fetchAssets(with: allPhotosOptions).enumerateObjects { asset, _, _ in
            let requestOptions = PHImageRequestOptions()
            requestOptions.resizeMode = .exact
            requestOptions.deliveryMode = .highQualityFormat

            PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: requestOptions) { image, _ in
                    guard let image = image else { fatalError("no image") }
                    self.images.append(image)
            }
        }
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let changes = changeInstance.changeDetails(for: photos)
            else { return }

        self.images = []
        changes.fetchResultAfterChanges.enumerateObjects { asset, _, _ in
            let requestOptions = PHImageRequestOptions()
            requestOptions.resizeMode = .exact
            requestOptions.deliveryMode = .highQualityFormat

            PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: requestOptions) { image, _ in
                guard let image = image else { fatalError("no image") }
                self.images.append(image)
            }
        }

    }
}

struct ImagePickerDrawer: View {
    var onDismiss: (() -> Void)? = nil
    @ObservedObject var manager = PhotoManager()

    var body: some View {
        VStack(alignment: .leading) {
            Button(action: { self.onDismiss?() },
                   label: { Text("Done").fontWeight(.semibold) }
            ).padding(7)
            ScrollView(.horizontal) {
                HStack {
                    List(self.manager.images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                        .onDrag({
                            let provider = NSItemProvider(object: image)
                            return provider
                        })
                    }
                }
            }
        }
        .background(Color.white)
        .cornerRadius(10)
    }
}