//
//  AppDelegate.swift
//  Jackdaw
//
//  Created by Jonson Goff-White on 31/01/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    let popover = NSPopover()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("jackdaw-icon"))
            button.action = #selector(togglePopover(_:))
        }
        popover.contentViewController = FolderSelectViewController.freshController()
        
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(self.handleGetURL(event:reply:)), forEventClass: UInt32(kInternetEventClass), andEventID: UInt32(kAEGetURL) )
    }
    
    @objc func handleGetURL(event: NSAppleEventDescriptor, reply:NSAppleEventDescriptor) {
        if let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue {
            print("got urlString \(urlString)")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }
    
    func showPopover(sender: Any?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    func closePopover(sender: Any?) {
        popover.performClose(sender)
    }

    

}
