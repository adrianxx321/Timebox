//
//  TaskModal.swift
//  Timebox
//
//  Created by Lianghan Siew on 18/03/2022.
//

import SwiftUI

private struct ColorChoice: Hashable {
    var name: String
    var value: Color
}

struct ColorPickerModal: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedColor: Color

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // React on binding
        // Show if not already...
        if isPresented && uiViewController.presentedViewController == nil {
            let controller = UIColorPickerViewController()
            controller.delegate = context.coordinator
            controller.selectedColor = UIColor(self.selectedColor)
            controller.presentationController?.delegate = context.coordinator

            uiViewController.present(controller, animated: true, completion: nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UIColorPickerViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
        let parent: ColorPickerModal
        
        init(parent: ColorPickerModal) {
            self.parent = parent
        }
        
        func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {

            viewController.selectedColor = color
            parent.selectedColor = Color(viewController.selectedColor)
        }
        
        /// Dismiss on tapping close button
        func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
            parent.isPresented = false
        }

        /// Dismiss on swipe
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            parent.isPresented = false
        }
    }
}

struct TaskModal: View {
    @Environment(\.dismiss) var dismiss
    @State private var isModalActive = false
    @State private var showColorPicker = false
    
    // Task values...
    // 12 in total
    @State var taskTitle: String = ""
    @State var subtasks: [Subtask] = []
    @State var taskLabel: String = ""
    @State var color: Color = Color.purple
    @State var isImportant: Bool = false
    @State var taskDate: Date?
    @State var taskEndTime: Date?
    @State var taskStartTime: Date?
    
//    @State var id: UUID = UUID.init()
//    @State var isCompleted: Bool = false
//    @State var isImported: Bool
//    @State var offset: Float
    
    // MARK: Core Data Context
    @Environment(\.managedObjectContext) var context
    
    @EnvironmentObject var taskModel: TaskViewModel
    
    static private let colors = [
        ColorChoice(name: "Red", value: Color.red),
        ColorChoice(name: "Blue", value: Color.blue),
        ColorChoice(name: "Purple", value: Color.purple),
        ColorChoice(name: "Orange", value: Color.orange),
        ColorChoice(name: "Green", value: Color.green),
    ]
    
    @State private var selectedColor: ColorChoice = ColorChoice(name: "Purple", value: Color.purple)
    @State private var selectedCustomColor: ColorChoice = ColorChoice(name: "Custom...", value: Color.purple)
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("Task Title", text: $taskTitle)
                    
                    // TODO: Subtasks
                    TextField("Add subtask", text: $taskTitle)
                }

                // Tag name...
                Section {
                    TextField("Tag (optional)", text: $taskLabel)
                }

                // Color...
                Section {
                    // Nested List...
                    NavigationLink(isActive: $isModalActive, destination: {
                        List {
                            // Predefined colors...
                            ForEach(TaskModal.colors, id: \.self) { color in
                                Button(action: {
                                    selectedColor = color
                                }, label: {
                                    // TODO: Refactor 2
                                    HStack {
                                        HStack(spacing: 16) {
                                            Image(systemName: "circle.fill")
                                                .foregroundColor(color.value)
                                            Text(color.name)
                                                .font(.paragraphP1())
                                                .fontWeight(.medium)
                                        }
                                        .foregroundColor(.textPrimary)

                                        Spacer()

                                        selectedColor.value == color.value ?
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.accent)
                                        : nil
                                    }
                                })
                                .padding(.vertical, 4)
                                .listRowSeparator(.hidden)
                            }

                            // Custom color picker...
                            Button(action: { showColorPicker.toggle() }, label: {
                                // TODO: Refactor 2
                                HStack {
                                    HStack(spacing: 16) {
                                        Image(systemName: "circle.fill")
                                            .foregroundColor(selectedCustomColor.value)
                                        Text(selectedCustomColor.name)
                                            .font(.paragraphP1())
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.textPrimary)

                                    Spacer()

                                    selectedColor.name == selectedCustomColor.name ?
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.accent)
                                    : nil
                                }
                            })
                        }
                        .navigationTitle("Task Color")
                        .background(ColorPickerModal(isPresented: $showColorPicker, selectedColor: $selectedCustomColor.value)
                            .onChange(of: selectedCustomColor, perform: { newValue in
                                selectedColor = newValue
                            }))

                    }, label: {
                        // TODO: Refactor 1
                        HStack(spacing: 16) {
                            Image(systemName: "circle.fill")
                                .foregroundColor(selectedColor.value)
                            Text(selectedColor.name)
                                .font(.paragraphP1())
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                        }
                    })
                    .padding(.vertical, 4)
                } header: { HeaderLabel(title: "Color") }

                // Is important...
                Section {
                    Toggle(isOn: $isImportant, label: {
                        // TODO: Refactor 1
                        HStack(spacing: 16) {
                            Image("alert")
                            Text("Important")
                                .font(.paragraphP1())
                                .fontWeight(.bold)
                        }.foregroundColor(.textPrimary)
                    })
                    .tint(.accent)
                    .padding(.vertical, 4)
                } header: { HeaderLabel(title: "Task Priority") }

                // Disabling Date for Edit Mode...
//                if taskModel.editTask == nil {
//
//                    Section {
//                        DatePicker("", selection: $taskDate)
//                            .datePickerStyle(.graphical)
//                            .labelsHidden()
//                    } header: {
//                        Text("Task Date")
//                    }
//                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Create a Task")
            .navigationBarTitleDisplayMode(.inline)
            // MARK: Disbaling Dismiss on Swipe
            .interactiveDismissDisabled()
            // MARK: Action Buttons
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save"){
                        if let task = taskModel.editTask {
                            task.taskTitle = taskTitle
                            task.taskLabel = taskLabel
                        }
                        else {
                            let task = Task(context: context)
                            task.taskTitle = taskTitle
                            task.taskLabel = taskLabel
                            task.taskDate = taskDate
                        }

                        // Saving
                        try? context.save()
                        // Dismissing View
                        dismiss()
                    }
                    .disabled(taskTitle == "" || taskLabel == "")
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel"){
                        dismiss()
                    }
                }
            }
            // Loading Task data if from Edit
            .onAppear {
                if let task = taskModel.editTask{
                    taskTitle = task.taskTitle ?? ""
                    taskLabel = task.taskLabel ?? ""
                }
            }
        }
    }
    
    private func HeaderLabel(title: String) -> some View {
        Text(title)
            .font(.paragraphP1())
            .fontWeight(.semibold)
            .foregroundColor(.textTertiary)
            .textCase(.uppercase)
    }
}

struct TaskModal_Previews: PreviewProvider {
    static var previews: some View {
        TaskModal()
    }
}
