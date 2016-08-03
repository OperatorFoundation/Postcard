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
    
    func getGoogleContacts()
    {
        getGoogleContacts(nil)
    }
    
    func getGoogleContacts(nextPageToken: String?)
    {
        let query = GTLRPeopleQuery_PeopleConnectionsList.queryWithResourceName("people/me")
        
        //You've got to be kidding me
        //Your documentation says otherwise buttheads
        query.requestMaskIncludeField = "person.emailAddresses,person.names,person.photos"
        
        //Sort Order for results
        query.sortOrder = "FIRST_NAME_ASCENDING"
        
        //Sync Token
        query.syncToken = GlobalVars.currentUser?.peopleSyncToken
        
        //Next Page Token
        query.pageToken = nextPageToken
        
        GmailProps.servicePeople.executeQuery(query, completionHandler: processPeopleResponse)
    }
    
    func processPeopleResponse(ticket: GTLRServiceTicket, maybeResponse: AnyObject?, maybeError: NSError?)
    {
        //Do we have friends??
        var count = 0
        if let response:GTLRPeople_ListConnectionsResponse = maybeResponse as? GTLRPeople_ListConnectionsResponse
        {
            count += 1
            let nextPageToken: String? = response.nextPageToken
            
            //User Attribute
            let syncToken = response.nextSyncToken
            GlobalVars.currentUser?.peopleSyncToken = syncToken
            do
            {
                try GlobalVars.currentUser?.managedObjectContext?.save()
            }
            catch
            {
                print("Unable to save user.peopleSyncToken")
            }
            
            if let connections = response.connections
            {
                for thisConnection in connections
                {
                    if let emailAddresses = thisConnection.emailAddresses
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
                
                if nextPageToken != nil
                {
                    getGoogleContacts(nextPageToken)
                }
            }
        }
        else if let error = maybeError
        {
            print(error)
        }
    }
    
    func saveConnection(connection:GTLRPeople_Person, asPenPal penPal: PenPal, withEmailAddress email: String)
    {
        penPal.owner = GlobalVars.currentUser
        penPal.email = email
        
        //Name
        if let names = connection.names where names.isEmpty == false
        {
            penPal.name = names[0].displayName
        }
        
        //PenPal Image
        if let coverPhotos = connection.photos where coverPhotos.isEmpty == false
        {
            let coverPhoto = coverPhotos[0]
            if let photoURLString = coverPhoto.url, let photoURL = NSURL(string: photoURLString)
            {
                imageDataFromURL(photoURL) { (maybeData, maybeResponse, maybeError) in
                    guard let data = maybeData where maybeError == nil else {return}
                    dispatch_async(dispatch_get_main_queue(), {
                        penPal.photo = NSImage(data: data)
                    })
                }
            }
        }
        
        //Save PenPal
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
    
    //MARK: Get Image Data from URL
    func imageDataFromURL(url: NSURL, completionHandler:((data: NSData?, response: NSURLResponse?, error: NSError?) -> Void))
    {
        NSURLSession.sharedSession().dataTaskWithURL(url){(data, response, error) in
            completionHandler(data: data, response: response, error: error)
        }.resume()
    }
    
    
}
