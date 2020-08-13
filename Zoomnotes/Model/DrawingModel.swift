//
//  DrawingModel.swift
//  Zoomnotes
//
//  Created by Berci on 2020. 08. 13..
//  Copyright © 2020. Berci. All rights reserved.
//

import UIKit
import PencilKit
import os

struct DrawingModel : Codable {
    static let canvasWidth: CGFloat = 768
    static let defaultDrawingNames: [String] = ["Notes"]
    
    var drawings: [PKDrawing] = []
}

protocol DataModelControllerObserver {
    func dataModelChanged()
}

class DataModelController {
    static let thumbnailSize = CGSize(width: 192, height: 256)
    
    var dataModel = DrawingModel()
    
    var thumbnails: [UIImage] = []
    var thumbnailTraitCollection = UITraitCollection() {
        didSet {
            if oldValue.userInterfaceStyle != thumbnailTraitCollection.userInterfaceStyle {
                generateAllThumbnails()
            }
        }
    }
    
    private let thumbnailQueue = DispatchQueue(label: "ThumbnailQueue", qos: .background)
    private let serializationQueue = DispatchQueue(label: "SerializationQueue", qos: .background)
    
    var observers: [DataModelControllerObserver] = []
    
    var drawings: [PKDrawing] {
        get { dataModel.drawings }
        set { dataModel.drawings = newValue }
    }
    
    init() {
        loadDataModel()
    }
    
    func updateDrawing(_ drawing: PKDrawing, at index: Int) {
        dataModel.drawings[index] = drawing
        generateThumbnail(index)
        saveDataModel()
    }
    
    private func generateAllThumbnails() {
        for index in drawings.indices {
            generateThumbnail(index)
        }
    }
    
    private func generateThumbnail(_ index: Int) {
        let drawing = drawings[index]
        let aspectRatio = DataModelController.thumbnailSize.width / DataModelController.thumbnailSize.height
        let thumbnailRect = CGRect(x: 0, y: 0, width: DrawingModel.canvasWidth, height: DrawingModel.canvasWidth / aspectRatio)
        let thumbnailScale = UIScreen.main.scale * DataModelController.thumbnailSize.width / DrawingModel.canvasWidth
        let traitCollection = thumbnailTraitCollection
        
        thumbnailQueue.async {
            traitCollection.performAsCurrent {
                let image = drawing.image(from: thumbnailRect, scale: thumbnailScale)
                DispatchQueue.main.async {
                    self.updateThumbnail(image, at: index)
                }
            }
        }
    }
    
    private func updateThumbnail(_ image: UIImage, at index: Int) {
        thumbnails[index] = image
        didChange()
    }
    
    private func didChange() {
        for observer in self.observers {
            observer.dataModelChanged()
        }
    }
    
    private var saveURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths.first!
        return documentsDirectory.appendingPathComponent("Zoomnotes.data")
    }
    
    func saveDataModel() {
        let savingDataModel = dataModel
        let url = saveURL
        serializationQueue.async {
            do {
                let encoder = PropertyListEncoder()
                let data = try encoder.encode(savingDataModel)
                try data.write(to: url)
            } catch {
                os_log("Could not save data model: %s", type: .error, error.localizedDescription)
            }
        }
    }
    
    private func loadDataModel() {
        let url = saveURL
        serializationQueue.async {
            // Load the data model, or the initial test data.
            let dataModel: DrawingModel
            
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    let decoder = PropertyListDecoder()
                    let data = try Data(contentsOf: url)
                    dataModel = try decoder.decode(DrawingModel.self, from: data)
                    DispatchQueue.main.async {
                        self.setLoadedDataModel(dataModel)
                    }
                } catch {
                    os_log("Could not load data model: %s", type: .error, error.localizedDescription)
                }
            }
        }
    }
    
    private func setLoadedDataModel(_ dataModel: DrawingModel) {
        self.dataModel = dataModel
        thumbnails = Array(repeating: UIImage(), count: dataModel.drawings.count)
        generateAllThumbnails()
    }
    
    func newDrawing() {
        let newDrawing = PKDrawing()
        dataModel.drawings.append(newDrawing)
        thumbnails.append(UIImage())
        updateDrawing(newDrawing, at: dataModel.drawings.count - 1)
    }
}


