//
//  pdf_paste_toolApp.swift
//  pdf_paste_tool
//
//  Created by catwithtudou on 2024/11/23.
//

import SwiftUI

@main
struct pdf_paste_toolApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 550, minHeight: 280)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
