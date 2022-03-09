//
//  PlannedTasks.swift
//  Timebox
//
//  Created by Lianghan Siew on 03/03/2022.
//

import SwiftUI

struct BacklogTasks: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @StateObject var taskModel = TaskViewModel()
    @State private var hideCompletedTasks = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                HeaderView()
                    .padding()
                
                // MARK: Scrollview showing list of backlog tasks
                ScrollView(.vertical, showsIndicators: false) {
                    DynamicTaskList(taskDate: nil, hideCompleted: false)
                }
                
                Spacer()
                
                // MARK: Create task button
                CTAButton(btnLabel: "Create a Task", btnAction: {}, btnFullSize: true)
            }
            .background(Color.backgroundPrimary)
            .navigationBarHidden(true)
        }
        .navigationBarHidden(true)
    }
    
    private func HeaderView() -> some View {
        HStack() {
            
            // MARK: Back button leading to previous screen
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image("chevron-left")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36)
            }
            
            Spacer()
            
            // MARK: Header title
            Text("Backlog")
                .font(.headingH2())
                .fontWeight(.heavy)
            
            Spacer()
            
            // MARK: Hide/Show completed tasks
            Button {
                
            } label: {
                Image("more-horizontal-f")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32)
            }
        }
        .foregroundColor(.textPrimary)
    }
}

struct BacklogTasks_Previews: PreviewProvider {
    static var previews: some View {
        BacklogTasks()
    }
}
