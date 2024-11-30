//
//  pdf_paste_toolApp.swift
//  pdf_paste_tool
//
//  Created by catwithtudou on 2024/11/23.
//

import SwiftUI

@main
struct pdf_paste_toolApp: App {
    @StateObject private var clipboardManager = ClipboardManager()

    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 550, minHeight: 280)
                .environmentObject(clipboardManager)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("关于 CopyTxMate") {
                    NSApp.orderFrontStandardAboutPanel(nil)
                }
            }

            CommandGroup(replacing: .newItem) { }
        }
    }

    init() {
        let processInfo = ProcessInfo.processInfo
        processInfo.enableSuddenTermination()
        processInfo.automaticTerminationSupportEnabled = true
    }
}
