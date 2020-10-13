//
//  DocumentStoreDescription.swift
//  Zoomnotes
//
//  Created by Berci on 2020. 09. 24..
//  Copyright © 2020. Berci. All rights reserved.
//

import Foundation
import UIKit

struct DocumentStoreDescription {
    let id: DocumentID
    let lastModified: Date
    let name: String
    let thumbnail: UIImage
    let root: NoteLevelDescription
}
