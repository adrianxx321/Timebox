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
        VStack(spacing: 16) {
            HeaderView()
                .padding()
            
            // Scrollview showing list of backlog tasks...
            ScrollView(.vertical, showsIndicators: false) {
                DynamicTaskList(hideCompleted: hideCompletedTasks)
            }
        }
        .background(Color.backgroundPrimary)
        .navigationBarHidden(true)
    }
    
    private func HeaderView() -> some View {
        HStack() {
            // Back button leading to previous screen...
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image("chevron-left")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36)
            }
            
            Spacer()
            
            // Screen title...
            Text("Backlog")
                .font(.headingH2())
                .fontWeight(.heavy)
            
            Spacer()
            
            // Hide/Show completed tasks...
            Button {
                withAnimation {
                    hideCompletedTasks.toggle()
                }
            } label: {
                Image(hideCompletedTasks ? "eye-close" : "eye")
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
