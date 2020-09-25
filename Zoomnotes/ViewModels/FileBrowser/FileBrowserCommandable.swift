//
//  FileBrowserCommandable.swift
//  Zoomnotes
//
//  Created by Berci on 2020. 09. 20..
//  Copyright © 2020. Berci. All rights reserved.
//

import Foundation
import UIKit

enum FileBrowserCommand {
    case createFile(preview: UIImage)
    case createDirectory
    case delete(FolderBrowserViewModel.Node)
    case move(FolderBrowserViewModel.Node, to: DirectoryVM)
    case rename(FolderBrowserViewModel.Node, to: String)
}

protocol FileBrowserCommandable {
    func process(command: FileBrowserCommand)
}
