//
//  ContentView.swift
//  Timebox
//
//  Created by Lianghan Siew on 23/02/2022.
//

import SwiftUI
import CoreData

// Dummy Core Data context for preview purposes
struct CoreDataStack {
    static var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    static var persistentContainer: NSPersistentContainer {
        let container = NSPersistentContainer(name: "Timebox")
        container.loadPersistentStores { (description, error) in
            if let error = error {
                print(error)
            }
        }
        
        return container
    }
}

/// Global variable to indicate if iPhone is X or later...
public var isNotched: Bool {
    let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
    let window = windowScene?.windows.first

    return (window?.safeAreaInsets.bottom)! > 0
}

/// Global variable to indicate if it's a small device (e.g. iPhone SE/8)...
public var isSmallDevice: Bool {
    return UIScreen.main.bounds.height < 750
}

struct ContentView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @Environment(\.managedObjectContext) var context
    @ObservedObject var eventModel = EventViewModel()
    
    init() {
        // Globally define UIKit appearances that suits my app's theme
        UITableView.appearance().showsVerticalScrollIndicator = false
        UITableView.appearance().backgroundColor = .backgroundPrimary
        UINavigationBar.appearance().tintColor = .accent
        UITableView.appearance().contentInset.top = -16
    }
    
    var body: some View {
        if isLoggedIn {
            Root()
        } else {
            Onboarding()
                .transition(.move(edge: .trailing))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
