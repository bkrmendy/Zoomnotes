//
//  FileBrowserViewModel+stub.swift
//  Zoomnotes
//
//  Created by Berci on 2020. 09. 25..
//  Copyright © 2020. Berci. All rights reserved.
//

import Foundation

extension FolderBrowserViewModel {
    static var stub: FolderBrowserViewModel {
        return FolderBrowserViewModel(directoryId: ID(UUID()),
                                      name: "Documents",
                                      nodes: [],
                                      access: DirectoryAccessMock(documents: [:],
                                                                  directories: [:]))
    }

    static func stub(nodes: [FolderBrowserNode]) -> FolderBrowserViewModel {

        return FolderBrowserViewModel(directoryId: ID(UUID()),
                                      name: "Documents",
                                      nodes: nodes,
                                      access: DirectoryAccessMock(documents: [:],
                                                                  directories: [:]))
    }
}
