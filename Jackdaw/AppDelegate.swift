//
//  AppDelegate.swift
//  Jackdaw
//
//  Created by Jonson Goff-White on 31/01/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//

import Cocoa

let JACKDAW_DOMAIN = "jackdaw"

var CURRENT_GIT_HANDLER: GitHandler?

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var eventMonitor: EventMonitor?

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    let popover = NSPopover()
    
    var viewControllerStack: [NSViewController] = []

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("jackdaw-icon"))
            button.action = #selector(togglePopover(_:))
        }
        popover.contentViewController = FolderSelectViewController.freshController()
        
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(self.handleGetURL(event:reply:)), forEventClass: UInt32(kInternetEventClass), andEventID: UInt32(kAEGetURL) )
        
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popover.isShown {
                strongSelf.closePopover(sender: event)
            }
        }
        
        // Change styles
        
    }
    
    func replaceContentViewController(with viewController: NSViewController) {
        popover.contentViewController = viewController
    }
    
    @objc func handleGetURL(event: NSAppleEventDescriptor, reply:NSAppleEventDescriptor) {
        if let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue {
            print("got urlString \(urlString)")
            let comps = urlString.components(separatedBy: "://")
            let domain = comps[0]
            var message: String
            if comps.count > 1 {
                message = comps[1]
            } else {
                message = ""
            }
            
            if domain == JACKDAW_DOMAIN {
                let handler = URLSchemeHandler(message: message)
                let alert = NSAlert()
                
                var git: GitHandler?, project: AbletonProject?
                
                
                if let viewController = popover.contentViewController {
                    if let viewController = viewController as? GitCommandsViewController {
                        git = viewController.git
                        project = viewController.abletonProject
                        print("is a GitCommandsViewController")
                        
                    } else {
                        // need to setup git and project here
                        print("is not a GitCommandsViewController")
                        print(viewController)
                    }
                    self.viewControllerStack.append(viewController)
                }
                
                let prViewController = PullRequestViewController.freshController(repo: "repo", base: handler.args[0], branch: handler.args[1], project: project!, git: git!)
                
                popover.contentViewController = prViewController

            }
            
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
    
    func returnFromSchemeView() {
        if self.viewControllerStack.count > 0 {
            popover.contentViewController = self.viewControllerStack.last
        } else {
            // Show folder select or something else
            // This happens when the URL scheme view was made when nothing
            // was behind it
        }
    }
    
    func showPopover(sender: Any?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
        eventMonitor?.start()
    }
    
    func closePopover(sender: Any?) {
        popover.performClose(sender)
        eventMonitor?.stop()
    }

    

}

