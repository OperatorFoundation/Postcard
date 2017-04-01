//
//  WelcomeViewController.swift
//  Postcard
//
//  Created by Adelita Schule on 5/20/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import GTMAppAuth
import AppAuth
//import GoogleAPIClient

class WelcomeViewController: NSViewController
{
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var descriptionView: NSView!
    @IBOutlet weak var googleLoginButton: NSButton!
    
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    
    var userGoogleName: String?
    var authorization: GTMAppAuthFetcherAuthorization?

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //The description label should be at the same angle as the Big "Postcard"
        descriptionView.rotate(byDegrees: 11.0)
        
        //Load Google Authorization State
        loadState()
    }
    
    override func viewDidAppear()
    {
        if isAuthorized()
        {
            //Present Home View
            mainWindowController.showWindow(self)
            
            view.window?.close()
        }
        else
        {
            googleLoginButton.isEnabled = true
        }
    }
    
    func fetchUserFromCoreData(_ userEmail: String) -> User?
    {
        //Check if a user entity already exists
        //Get this User Entity
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        let managedObjectContext = appDelegate.managedObjectContext
        fetchRequest.predicate = NSPredicate(format: "emailAddress == %@", userEmail)
        do
        {
            let result = try managedObjectContext.fetch(fetchRequest)
            if result.count > 0
            {
                let thisUser = result[0]
                return thisUser
            }
            else
            {
                return nil
            }
        }
        catch
        {
            //Could not fetch this Penpal from core data
            let fetchError = error as NSError
            print("Could not fetch user from core data:\(fetchError)")
            return nil
        }
    }
    
    func createUser(_ userEmail: String) -> User?
    {
        return createUser(userEmail, firstName: nil)
    }
    
    func createUser(_ userEmail: String, firstName: String?) -> User?
    {
        let managedObjectContext = appDelegate.managedObjectContext
        
        if let userEntity = NSEntityDescription.entity(forEntityName: "User", in: managedObjectContext)
        {
            let newUser = User(entity: userEntity, insertInto: managedObjectContext)
            newUser.emailAddress = userEmail
            
            //Save this user to core Data
            do
            {
                try newUser.managedObjectContext?.save()
                GlobalVars.currentUser = newUser
                return newUser
            }
            catch
            {
                let saveError = error as NSError
                print("Unable to save new user to core data. \n\(saveError)\n")
                return nil
            }
        }
        else
        {
            return nil
        }
    }
    
    func fetchGoodies()
    {
        MailController.sharedInstance.updateMail()
        PenPalController.sharedInstance.getGoogleContacts()
    }
    
    
    lazy var mainWindowController: MainWindowController =
    {
        let storyboard: NSStoryboard = NSStoryboard(name: "Main", bundle: nil)
        let newWindowController = storyboard.instantiateController(withIdentifier: "MainWindowController") as! MainWindowController
        return newWindowController
    }()
    
    //MARK: Actions
    
    @IBAction func googleSignInTap(_ sender: AnyObject)
    {
        buildAuthenticationRequest()
    }
    
    //MARK: Google App Auth Methods
    func isAuthorized() -> Bool
    {
        //Ensure Gmail API service is authorized and perform API calls (fetch postcards)
        if let authorizer = self.authorization
        {
            let canAuth = authorizer.canAuthorize()
            if canAuth
            {
                if (GlobalVars.currentUser?.emailAddress) != nil
                {
                    fetchGoodies()
                }
                else
                {
                    let service = GTMSessionFetcherService()
                    service.authorizer = authorizer
                    let userInfoEndpoint = "https://www.googleapis.com/oauth2/v3/userinfo"
                    let fetcher = service.fetcher(withURLString: userInfoEndpoint)
                    fetcher.beginFetch(completionHandler:
                    {
                        (maybeData, maybeError) in
                        
                        if let error = maybeError
                        {
                            print("User Info Call Error: \(error.localizedDescription)")
                        }
                        else if let data = maybeData
                        {
                            if let json = try? JSONSerialization.jsonObject(with: data, options: [])
                            {
                                print("json: \(json)")
                            }
                        }
                    })
                    if let currentEmailAddress: String = authorizer.userEmail
                    {
                        //Check if a user entity already exists
                        if let existingUser = fetchUserFromCoreData(currentEmailAddress)
                        {
                            GlobalVars.currentUser = existingUser
                            self.fetchGoodies()
                        }
                        else
                        {
                            //Create a new user
                            if createUser(currentEmailAddress) != nil
                            {
                                self.fetchGoodies()
                            }
                            
                            //                        if let authWindowController = googleAuthWindowController, let name = authWindowController.signIn.userProfile["name"] as? String
                            //                        {
                            //                            if createUser(currentEmailAddress, firstName: name) != nil
                            //                            {
                            //                                self.fetchGoodies()
                            //                            }
                            //                        }
                            //                        else
                            //                        {
                            //                            if createUser(currentEmailAddress) != nil
                            //                            {
                            //                                self.fetchGoodies()
                            //                            }
                            //                        }
                        }
                    }
                }
            }

            return true
        }
        else
        {
            return false
        }
    }
    
    func buildAuthenticationRequest()
    {
        if let redirectURL = URL(string: GmailProps.kRedirectURI)
        {
            //Convenience method to configure GTMAppAuth with the OAuth endpoints for Google.
            let configuration = GTMAppAuthFetcherAuthorization.configurationForGoogle()
            
            // builds authentication request
            let request = OIDAuthorizationRequest(configuration: configuration, clientId: GmailProps.kClientID, clientSecret: nil, scopes: GmailProps.scopes, redirectURL: redirectURL, responseType: OIDResponseTypeCode, additionalParameters: nil)
            
            // performs authentication request
            appDelegate.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, callback:
            {
                (maybeAuthState, maybeError) in
                
                if let authState = maybeAuthState
                {
                    let authorization = GTMAppAuthFetcherAuthorization(authState: authState)
                    self.setAuthorization(auth: authorization)
                                        
                    if self.isAuthorized()
                    {
                        //Present Home View
                        self.mainWindowController.showWindow(self)
                        
                        self.view.window?.close()
                    }
                }
                else if let error = maybeError
                {
                    print("Authorization Error: \(error.localizedDescription)")
                }
                else
                {
                    print("Unknown Authorization Error")
                }
            })
        }
    }

    func saveState()
    {
        if self.authorization != nil
        {
            let canAuth = self.authorization!.canAuthorize()
            if canAuth
            {
                GTMAppAuthFetcherAuthorization.save(self.authorization!, toKeychainForName: GmailProps.kKeychainItemName)
            }
            else
            {
                GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: GmailProps.kKeychainItemName)
            }
        }
    }
    
    func loadState()
    {
        if let authorization = GTMAppAuthFetcherAuthorization.init(fromKeychainForName: GmailProps.kKeychainItemName)
        {
            setAuthorization(auth: authorization)
        }
    }
    
    func setAuthorization(auth: GTMAppAuthFetcherAuthorization)
    {
        self.authorization = auth
        GmailProps.service.authorizer = auth
        GmailProps.servicePeople.authorizer = auth
        saveState()
    }
    
    //MARK: Helper Methods
    
    //Helper for showing an alert.
    func showAlert(_ message: String)
    {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: localizedOKButtonTitle)
        alert.runModal()
    }
   
//
}
