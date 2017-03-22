//
//  AppDelegate.swift
//  Postcard
//
//  Created by Adelita Schule on 4/15/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import CoreData
import GTMOAuth2

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
    @IBOutlet weak var postcardWindow: NSWindow!
    
    //Notification Keys
    let keyHandoffNotificationName = "PostcardKeyHandoffNotification"
    
    //MARK: Application Lifecycle
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        //Listen for sleep
        NSWorkspace.shared().notificationCenter.addObserver(self, selector: #selector(willSleep), name: NSNotification.Name.NSWorkspaceWillSleep, object: nil)
    }
    
    func willSleep()
    {
        print("😴")
        
        GlobalVars.messageCache = nil
        KeyController.sharedInstance.deleteInstance()
    }
    
    //UserActivity Delegate
    func application(_ application: NSApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]) -> Void) -> Bool
    {
        if let userInfo = userActivity.userInfo
        {
            print("Received a payload via handoff: \(userInfo)")
            
            //Post handoff notification to listeners
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: keyHandoffNotificationName) , object: userInfo)
        }
        
        return true
    }
    
    //MARK: Helper Methods
    
    //Helper for showing an alert.
    func showAlert(_ message: String)
    {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: URL =
    {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "org.operatorfoundation.Postcard" in the user's Application Support directory.
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportURL = urls[urls.count - 1]
        return appSupportURL.appendingPathComponent("org.operatorfoundation.Postcard")
    }()

    lazy var managedObjectModel: NSManagedObjectModel =
    {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "Postcard", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator =
    {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.) This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        let fileManager = FileManager.default
        var failError: NSError? = nil
        var shouldFail = false
        var failureReason = "There was an error creating or loading the application's saved data."

        // Make sure the application files directory is there
        do {
            let properties = try (self.applicationDocumentsDirectory as NSURL).resourceValues(forKeys: [URLResourceKey.isDirectoryKey])
            if !(properties[URLResourceKey.isDirectoryKey]! as AnyObject).boolValue {
                failureReason = "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."
                shouldFail = true
            }
        }
        catch  {
            let nserror = error as NSError
            if nserror.code == NSFileReadNoSuchFileError
            {
                do {
                    try fileManager.createDirectory(atPath: self.applicationDocumentsDirectory.path, withIntermediateDirectories: true, attributes: nil)
                }
                catch {
                    failError = nserror
                }
            }
            else
            {
                failError = nserror
            }
        }
        
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = nil
        if failError == nil
        {
            coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            let url = self.applicationDocumentsDirectory.appendingPathComponent("CocoaAppCD.storedata")
            do {
                try coordinator!.addPersistentStore(ofType: NSXMLStoreType, configurationName: nil, at: url, options: nil)
            }
            catch {
                /*
                 Typical reasons for an error here include:
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                failError = error as NSError
                print("Failed to add persistent store: \(error.localizedDescription)")
            }
        }
        
        if shouldFail || (failError != nil)
        {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            if failError != nil {
                dict[NSUnderlyingErrorKey] = failError
            }
            let error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSApplication.shared().presentError(error)
            
            //TODO: More user friendly way of handling non-migrated coreData changes
            abort()
        }
        else
        {
            return coordinator!
        }
    }()

    lazy var managedObjectContext: NSManagedObjectContext =
    {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        managedObjectContext.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)
        
        return managedObjectContext
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(_ sender: AnyObject!)
    {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        if !managedObjectContext.commitEditing()
        {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if managedObjectContext.hasChanges
        {
            do {
                try managedObjectContext.save()
            }
            catch {
                let nserror = error as NSError
                NSApplication.shared().presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(_ window: NSWindow) -> UndoManager?
    {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return managedObjectContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplicationTerminateReply
    {
        // Save changes in the application's managed object context before the application terminates.
        if !managedObjectContext.commitEditing()
        {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }
        
        if !managedObjectContext.hasChanges
        {
            return .terminateNow
        }
        
        do
        {
            try managedObjectContext.save()
        }
        catch
        {
            let nserror = error as NSError
            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result)
            {
                return .terminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == NSAlertFirstButtonReturn
            {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }

}

