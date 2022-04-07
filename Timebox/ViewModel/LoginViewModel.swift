//
//  LoginViewModel.swift
//  Timebox
//
//  Created by Lianghan Siew on 27/02/2022.
//

import SwiftUI
import AuthenticationServices
import CloudKit

class LoginViewModel: ObservableObject {
    @AppStorage("isLoggedIn") var isLoggedIn = false
    
    func authenticate(authUser: ASAuthorizationAppleIDCredential) {
        let userID = authUser.user
        
        let publicDB = CKContainer.default().publicCloudDatabase
        
        publicDB.fetch(withRecordID: CKRecord.ID(recordName: userID)) { (record, error) in
            guard record != nil else {
                // Is new user...
                let newUserRecord = CKRecord(recordType: "UserData", recordID: CKRecord.ID(recordName: userID))
                
                // Get user's credential (ONLY VALID FOR 1ST LOGIN)
                guard let email = authUser.email,
                      let username = authUser.fullName?.formatted() else {
                          return
                      }
                
                // Saving new record to cloud database...
                newUserRecord.setObject(email as __CKRecordObjCValue, forKey: "email")
                newUserRecord.setObject(username as __CKRecordObjCValue, forKey: "username")
                publicDB.save(newUserRecord) { (record, error) in
                    guard record != nil else {
                        print(error!.localizedDescription)
                        return
                    }
                    print("new user record saved")
                }
                return
            }
            
            // Is returning user...
            print("returning user found")
        }
        
        // User successfully logged in using Apple ID...
        print("Logged in successfully.")
                    
        // Redirect user to home screen...
        withAnimation {
            self.isLoggedIn = true
        }
    }
}
