//
//  PenPalController.swift
//  Postcard
//
//  Created by Adelita Schule on 5/13/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import GoogleAPIClientForREST

class PenPalController: NSObject
{
    static let sharedInstance = PenPalController()
    let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
    var managedObjectContext: NSManagedObjectContext?
    private override init()
    {
        managedObjectContext = appDelegate.managedObjectContext
    }
    
    //TODO: This is not currently used
    func getPenPalEmails(completionHandler:() -> Void)
    {
        if let managedObjectContext = managedObjectContext
        {
            let request = NSFetchRequest(entityName: "PenPal")
            var results: [AnyObject]? = nil
            do
            {
                results = try managedObjectContext.executeFetchRequest(request)
            }
            catch
            {
                fatalError("Failed to fetch penpals: \(error)\n")
            }
        }
        
        completionHandler()
    }
    
    func getGoogleContacts()
    {
        let query = GTLRPeopleQuery_PeopleConnectionsList.queryWithResourceName("people/me")
        
        var nextPageToken: String?
        repeat
        {
            GmailProps.servicePeople.executeQuery(query, completionHandler: { (ticket, maybeResponse, maybeError) in
                //Do we have friends??
                var count = 0
                if let response:GTLRPeople_ListConnectionsResponse = maybeResponse as? GTLRPeople_ListConnectionsResponse
                {
                    count += 1
                    print("Response " + count.description)
                    print(response.description + "\n")
                    nextPageToken = response.nextPageToken
                    
                    //TODO: Save to core data
                    
                    //User Attribute
                    let syncToken = response.nextSyncToken
            

                    if let connections = response.connections
                    {
                        for thisConnection in connections
                        {
                            //print("\(thisConnection)\n")
                            
                            //TODO: This isn't working, no email addresses are here :(
                            if let emailAddresses = thisConnection.emailAddresses //where emailAddresses.isEmpty == false
                            {
                                for thisEAddress in emailAddresses
                                {
                                    if let emailAddress = thisEAddress.value
                                    {
                                        //If this PenPal is already in Core Data, update that Pal
                                        //TODO: We are only saving the first email address in the list
                                        if let thisPenPal = self.fetchPenPal(emailAddress)
                                        {
                                            self.saveConnection(thisConnection, asPenPal: thisPenPal, withEmailAddress: emailAddress)
                                            
                                        }
                                        else
                                        {
                                            //Otherwise, create a new PenPal
                                            if let managedObjectContext = self.managedObjectContext, let entity = NSEntityDescription.entityForName("PenPal", inManagedObjectContext: managedObjectContext)
                                            {
                                                let newPal = PenPal(entity: entity, insertIntoManagedObjectContext: managedObjectContext)
                                                self.saveConnection(thisConnection, asPenPal: newPal, withEmailAddress: emailAddress)
                                            }
                                            
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                }
                else if let error = maybeError
                {
                    print(error)
                }
            })
            
        } while nextPageToken != nil
    }
    
    func saveConnection(connection:GTLRPeople_Person, asPenPal penPal: PenPal, withEmailAddress email: String)
    {
        penPal.owner = Constants.currentUser
        penPal.email = email
        print("Penpal email address: \(email)\n")
        
        if let names = connection.names where names.isEmpty == false
        {
            penPal.name = names[0].displayName
            print("PenPal Display Name: \(penPal.name)\n")
        }
        
        if let coverPhotos = connection.coverPhotos where coverPhotos.isEmpty == false
        {
            let coverPhoto = coverPhotos[0]
            if coverPhoto.defaultProperty == false
            {
                let photoUrl = coverPhoto.url
                print("This PenPal photo url: \(photoUrl)\n")
                //TODO: Download photo and save as thisPenPal.photo
            }
        }
        
        do
        {
            try penPal.managedObjectContext?.save()
        }
        catch
        {
            let saveError = error as NSError
            print("\(saveError)")
        }
    }
    
    //Check core data for a pen pal with the provided email address
    func fetchPenPal(emailAddress: String) -> PenPal?
    {
        let fetchRequest = NSFetchRequest(entityName: "PenPal")
        //Check for a penpal with this email address AND this current user as owner
        fetchRequest.predicate = NSPredicate(format: "email == %@", emailAddress)
        do
        {
            let result = try self.managedObjectContext?.executeFetchRequest(fetchRequest)
            if result?.count > 0, let thisPenpal = result?[0] as? PenPal
            {
                return thisPenpal
            }
        }
        catch
        {
            //Could not fetch this Penpal from core data
            let fetchError = error as NSError
            print(fetchError)
            
            return nil
        }
        
        return nil
    }
    
    //DEV ONLY: create contacts
    func makeMeSomeFriends()
    {
        //Create New PenPal record
        
        if let managedObjectContext = self.managedObjectContext, let entity = NSEntityDescription.entityForName("PenPal", inManagedObjectContext: managedObjectContext)
        {

            
            //            let newPal4 = PenPal(entity: entity, insertIntoManagedObjectContext: self.managedObjectContext)
            //            newPal4.email = "looklita@gmail.com"
            //            newPal4.name = "Lita Consuelo"
            //            newPal4.owner = Constants.currentUser
            //
            //            //Save this PenPal to core data
            //            do
            //            {
            //                try newPal4.managedObjectContext?.save()
            //                //print("NewCard From:" + (newCard.from?.email)! + "\n")
            //            }
            //            catch
            //            {
            //                let saveError = error as NSError
            //                print("\(saveError)")
            //            }
            
            let newPal4 = PenPal(entity: entity, insertIntoManagedObjectContext: self.managedObjectContext)
            newPal4.email = "adelita.schule@gmail.com"
            newPal4.name = "Adelita Schule"
            newPal4.owner = Constants.currentUser
            
            //Save this PenPal to core data
            do
            {
                try newPal4.managedObjectContext?.save()
            }
            catch
            {
                let saveError = error as NSError
                print("\(saveError)")
            }
            
        }
    }

    
    
}
