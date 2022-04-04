//
//  TaskModal.swift
//  Timebox
//
//  Created by Lianghan Siew on 18/03/2022.
//

import SwiftUI

private struct ColorChoice: Hashable {
    var name: String
    var value: UIColor
}

private enum TaskDuration: String, CaseIterable, Identifiable {
    case untimed, allDay, timeboxed
    
    var id: Self { self }
    var description : String {
        switch self {
            case .untimed: return "Untimed"
            case .allDay: return "All-day"
            case .timeboxed: return "Timeboxed"
        }
    }
}

struct TaskModal: View {
    // MARK: Dismissal action for modal pop up
    @Environment(\.dismiss) var dismiss
    @State private var isModalActive = false
    @State private var showColorPicker = false
    // A dictionary to keep track of changes in all fields
    @State private var isEdited: [String: Bool] = [
        "taskTitle" : false,
        "subtasks": false,
        "taskLabel" : false,
        "color" : false,
        "isImportant" : false,
        "duration" : false,
        "taskStartTime" : false,
        "taskEndTime" : false,
    ]
    @State private var showDiscardConfirm = false
    
    // Task properties that will be directly saved to Core Data...
    @State var id: UUID = UUID.init()
    @State var taskTitle: String = ""
    @State var subtasks: [Subtask] = []
    @State var subtaskTitles: [String] = []
    @State var taskLabel: String = ""
    @State var color: UIColor = .purple
    @State var isImportant: Bool = false
    @State var taskStartTime: Date?
    @State var taskEndTime: Date?

    // MARK: Binding values to be used for DatePicker
    // DatePicker can't handle nil...
    // So we'll assume a default value of current time in the event of nil
    private var startTimeBinding: Binding<Date> {
        Binding {
            taskStartTime ?? Date()
        } set: {
            taskStartTime = $0
        }
    }
    private var endTimeBinding: Binding<Date> {
        Binding {
            taskEndTime ?? Date()
        } set: {
            taskEndTime = $0
        }
    }
    private var isEditMode: Bool {
        return taskModel.editTask != nil
    }
    private var disableEditForImported: Bool {
        get {
            guard let task = taskModel.editTask else {
                return false
            }
            
            return task.ekeventID != nil
        }
    }
    
    // MARK: Core Data Context
    @Environment(\.managedObjectContext) var context
    @EnvironmentObject var taskModel: TaskViewModel
    
    // MARK: Predefined color list
    static private let colors = [
        ColorChoice(name: "Red", value: UIColor.red),
        ColorChoice(name: "Blue", value: UIColor.blue),
        ColorChoice(name: "Purple", value: UIColor.purple),
        ColorChoice(name: "Orange", value: UIColor.orange),
        ColorChoice(name: "Green", value: UIColor.green),
    ]
    
    @State private var selectedColor: ColorChoice = ColorChoice(name: "Purple", value: UIColor.purple)
    @State private var selectedCustomColor: ColorChoice = ColorChoice(name: "Custom...", value: UIColor.purple)
    @State private var selectedDuration: TaskDuration = .untimed
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                self.disableEditForImported ?
                Text("Note:  You are editing an imported task from your Calendar.")
                    .font(.paragraphP1())
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                : nil
                
                List {
                    // Task title & Subtasks...
                    Section {
                        // Task title
                        MyTextField("Task Title", $taskTitle)
                            .onAppear {
                                if let task = taskModel.editTask {
                                    if !isEdited.contains(where: { $0.value }) {
                                        taskTitle = task.taskTitle ?? ""
                                    }
                                }
                            }
                            .onChange(of: taskTitle, perform: { newValue in
                                isEdited["taskTitle"] = taskTitle != taskModel.editTask?.taskTitle
                            })
                            .disabled(self.disableEditForImported)
                        
                        // Subtasks
                        Section {
                            ForEach($subtasks, id: \.self) { $subtask in
                                HStack(spacing: 16) {
                                    Image("branch")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.textTertiary)
                                        .frame(width: 24)
                                        .rotationEffect(.degrees(90))
                                    
                                    MyTextField("Subtask Title", $subtask.subtaskTitle.toUnwrapped(defaultValue: ""))
                                }
                            }
                            .onDelete { index in
                                withAnimation {
                                    subtasks.remove(atOffsets: index)
                                }
                            }
                            
                            HStack(spacing: 16) {
                                Button {
                                    withAnimation {
                                        subtasks.append(taskModel.addSubtask(context: self.context))
                                    }
                                } label: {
                                    Image("add")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 24)
                                        .rotationEffect(.degrees(90))
                                }
                                
                                Text("Add Subtask")
                                    .font(.paragraphP1())
                                    .fontWeight(.bold)
                            }.foregroundColor(.textTertiary)
                        }
                        .listRowSeparator(.hidden)
                        .onAppear {
                            if let task = taskModel.editTask {
                                if !isEdited.contains(where: { $0.value }) {
                                    subtasks = task.subtasks
                                }
                            }
                        }
                        .onChange(of: subtasks, perform: { newValue in
                            isEdited["subtasks"] = subtasks != taskModel.editTask?.subtasks
                        })
                    }

                    // Tag name...
                    Section {
                        MyTextField("Tag (optional)", $taskLabel)
                            .onAppear {
                                if let task = taskModel.editTask {
                                    if !isEdited.contains(where: { $0.value }) {
                                        taskLabel = task.taskLabel ?? ""
                                    }
                                }
                            }
                            .onChange(of: taskLabel, perform: { newValue in
                                isEdited["taskLabel"] = taskLabel != taskModel.editTask?.taskLabel
                            })
                    } header: { SectionHeaderLabel(title: "Label") }
                        .disabled(disableEditForImported)

                    // Color...
                    Section {
                        // Nested List...
                        // We can't use the PickerView component for this section
                        // Because it'd be too complicated to encapsulate the additional custom color picker
                        NavigationLink(isActive: $isModalActive, destination: {
                            List {
                                // Predefined colors...
                                ForEach(TaskModal.colors, id: \.self) { color in
                                    Button { selectedColor = color } label: {
                                        DetailedPickerLabel(value: color.name,
                                                            innerIcon: Image(systemName: "circle.fill"),
                                                            innerIconColor: Color(color.value),
                                                            item: selectedColor,
                                                            itemComparator: color)
                                    }
                                }

                                // Custom color picker...
                                Button { showColorPicker.toggle() } label: {
                                    DetailedPickerLabel(value: selectedCustomColor.name,
                                                        innerIcon: Image(systemName: "circle.fill"),
                                                        innerIconColor: Color(selectedCustomColor.value),
                                                        item: selectedColor,
                                                        itemComparator: selectedCustomColor)
                                }
                            }
                            .navigationTitle("Task Color")
                            .background {
                                UIColorPickerModal(isPresented: $showColorPicker, selectedColor: ($selectedCustomColor.value))
                                .onChange(of: selectedCustomColor, perform: { newValue in
                                    selectedColor = newValue
                                })
                            }
                        }, label: {
                            PickerLabel(title: selectedColor.name, icon: Image(systemName: "circle.fill"), iconColor: Color(selectedColor.value))
                        })
                        .onAppear {
                            if let existingTask = taskModel.editTask {
                                if !isEdited.contains(where: { $0.value }) {
                                    // Check if existing task's color is one of the predefined...
                                    guard let index = TaskModal.colors.firstIndex(where: { $0.value == existingTask.color }) else {
                                        selectedCustomColor = ColorChoice(name: "Custom...", value: existingTask.color ?? .accent)
                                        selectedColor = selectedCustomColor
                                        return color = selectedColor.value
                                    }
                                    selectedColor = TaskModal.colors[index]
                                    color = selectedColor.value
                                }
                            }
                        }
                        .onChange(of: selectedColor, perform: { newColor in
                            color = newColor.value
                            isEdited["color"] = color != taskModel.editTask?.color
                        })
                    } header: { SectionHeaderLabel(title: "Color") }
                        .disabled(disableEditForImported)

                    // Is important...
                    Section {
                        Toggle(isOn: $isImportant, label: {
                            PickerLabel(title: "Important", icon: Image("alert"), iconColor: .textPrimary)
                        })
                        .tint(.accent)
                        .onAppear {
                            if let task = taskModel.editTask {
                                if !isEdited.contains(where: { $0.value }) {
                                    isImportant = task.isImportant
                                }
                            }
                        }
                        .onChange(of: isImportant, perform: { newValue in
                            isEdited["isImportant"] = isImportant != taskModel.editTask?.isImportant
                        })
                    } header: { SectionHeaderLabel(title: "Task Priority") }

                    // Date & Time
                    Section {
                        // First, let user select whether the task is time-constrained
                        ListItemPickerView<TaskDuration>(selectedItem: $selectedDuration,
                                                 items: TaskDuration.allCases,
                                                 screenTitle: "Task Duration",
                                                 hideDefaultNavigationBar: false,
                                                 mainIcon: Image("clock"),
                                                 mainIconColor: .textPrimary,
                                                 mainLabel: "Duration",
                                                 innerIcon: nil,
                                                 innerIconColor: nil,
                                                 innerLabel: \TaskDuration.description,
                                                 hideSelectedValue: false,
                                                 hideRowSeparator: false)
                        .onAppear {
                            // Pre-selects duration from saved task BASED ON START & END TIME
                            if let task = taskModel.editTask {
                                // Make sure pre-selection only done once
                                if !isEdited.contains(where: { $0.value }) {
                                    selectedDuration = !taskModel.isScheduledTask(task) ? .untimed
                                    : taskModel.isAllDayTask(task) ? .allDay
                                    : .timeboxed
                                }
                            }
                        }
                        .onChange(of: selectedDuration, perform: { newValue in
                            switch newValue {
                                case .untimed:
                                    taskStartTime = nil
                                    taskEndTime = nil
                                
                                case .allDay:
                                    // Start & end time will always be 0000 & 2359
                                    guard let existingTask = taskModel.editTask else {
                                        taskStartTime = Calendar.current.startOfDay(for: Date())
                                        taskEndTime = taskModel.getOneMinToMidnight(taskStartTime!)
                                        
                                        return
                                    }
                                    taskStartTime = taskModel.isAllDayTask(existingTask) ? existingTask.taskStartTime : Calendar.current.startOfDay(for: Date())
                                    taskEndTime = taskModel.getOneMinToMidnight(taskStartTime!)
                                
                                case .timeboxed:
                                    guard let existingTask = taskModel.editTask else {
                                        taskStartTime = taskModel.getNearestHour(Date())
                                        taskEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: taskStartTime!)

                                        return
                                    }
                                    taskStartTime = taskModel.isTimeboxedTask(existingTask) ? existingTask.taskStartTime : taskModel.getNearestHour(Date())
                                    taskEndTime = taskModel.isTimeboxedTask(existingTask) ? existingTask.taskEndTime : Calendar.current.date(byAdding: .hour, value: 1, to: taskStartTime!)
                            }
                            // MARK: (EDIT MODE) Initial values unchanged
                            isEdited["taskStartTime"]! = taskStartTime != taskModel.editTask?.taskStartTime
                            isEdited["taskEndTime"]! = taskEndTime != taskModel.editTask?.taskEndTime
                            isEdited["duration"]! = isEdited["taskStartTime"]! && isEdited["taskEndTime"]!
                        })
                        
                        // Then, present date & time picker only if it's time-constrained...
                        selectedDuration != .untimed ?
                        Group {
                            DatePicker("Date", selection: startTimeBinding,
                                       in: Calendar.current.startOfDay(for: Date())...,
                                       displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .accentColor(.accent)
                                .onChange(of: taskStartTime, perform: { newValue in
                                    // New end time should be of the same day of new start time
                                    // Changes for taskEndTime can be tracked together
                                    // ... since end time will be changed once start time changes
                                    let newValueUnwrapped = newValue ?? Date()
                                    
                                    switch selectedDuration {
                                        case .untimed:
                                            break
                                        case .allDay:
                                            taskStartTime = Calendar.current.startOfDay(for: newValueUnwrapped)
                                            taskEndTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: newValueUnwrapped)
                                        case .timeboxed:
                                            guard let existingTask = taskModel.editTask else {
                                                taskEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: newValueUnwrapped)

                                                return
                                            }
                                        // If existing task is also timeboxed, then endtime should be retained
                                        // If existing task is all-day/untimed, then use current time + 1 hour for endtime
                                        if taskModel.isTimeboxedTask(existingTask) {
                                            let isReversed = newValueUnwrapped < existingTask.taskStartTime!
                                            let interval = DateInterval(start: isReversed ? newValueUnwrapped : existingTask.taskStartTime!,
                                                                        end: isReversed ? existingTask.taskStartTime! : newValueUnwrapped)
                                            let dayDiff = isReversed ? interval.duration * -1 : interval.duration
                                            
                                            taskEndTime = existingTask.taskEndTime!.addingTimeInterval(dayDiff)
                                        } else {
                                            taskEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: newValueUnwrapped)
                                        }
                                    }
                                    isEdited["taskStartTime"] = taskStartTime != taskModel.editTask?.taskStartTime
                                    isEdited["taskEndTime"] = taskEndTime != taskModel.editTask?.taskEndTime
                                })

                            selectedDuration == .timeboxed ?
                            Group {
                                // Start time can range from 00:00 to 23:59
                                MyTimePicker(title: "Start Time", selectedTime: startTimeBinding, range: nil)

                                let endTimePickerLimit = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: startTimeBinding.wrappedValue)!
                                // End time must be after the start time, and cannot exceed 23:59
                                MyTimePicker(title: "End Time",
                                             selectedTime: endTimeBinding,
                                             range: startTimeBinding.wrappedValue...endTimePickerLimit)
                                    .listRowSeparator(.hidden)
                            }.font(.paragraphP1()) : nil
                        }
                        .onAppear {
                            if let task = taskModel.editTask {
                                if !isEdited.contains(where: { $0.value }) {
                                    taskStartTime = task.taskStartTime
                                    taskEndTime = task.taskEndTime
                                }
                            }
                        }
                        : nil
                    } header: { SectionHeaderLabel(title: "Date & Time") }
                        .disabled(disableEditForImported)
                }
                .listStyle(.insetGrouped)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle(self.isEditMode ? "Edit Task" : "Create a Task")
            .navigationBarTitleDisplayMode(.inline)
            // MARK: Conditionally dismiss on swipe
            .interactiveDismissDisabled(isEdited.contains(where: { $0.value }))
            // MARK: Action Buttons
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Create new task...
                        if let task = taskModel.editTask {
                            // Edit existing task...
                            taskModel.updateTask(context: self.context,
                                                 task: task,
                                                 self.taskTitle,
                                                 self.subtasks,
                                                 self.taskLabel,
                                                 self.color,
                                                 self.isImportant,
                                                 self.taskStartTime,
                                                 self.taskEndTime)
                        } else {
                            taskModel.addTask(context: self.context,
                                              id: self.id,
                                              self.taskTitle,
                                              self.subtasks,
                                              self.taskLabel,
                                              self.color,
                                              self.isImportant,
                                              self.taskStartTime,
                                              self.taskEndTime)}
                        
                        // Dismiss view after completion
                        dismiss()
                    }
                    .disabled(taskTitle == ""
                              || !isEdited.contains(where: { $0.value })
                              || subtasks.contains(where: {$0.subtaskTitle == ""}))
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isEdited.contains(where: { $0.value }) ? showDiscardConfirm.toggle() : dismiss()
                    }
                    .confirmationDialog(taskModel.editTask == nil ? "Are you sure you want to discard this new task?"
                                        : "Are you sure you want to discard the changes?",
                                        isPresented: $showDiscardConfirm,
                                        titleVisibility: .visible) {
                        Button("Discard Changes", role: .destructive, action: { dismiss() })
                    }
                }
            }
        }
    }

    private func SectionHeaderLabel(title: String) -> some View {
        Text(title)
            .font(.paragraphP1())
            .fontWeight(.semibold)
            .foregroundColor(.textTertiary)
            .textCase(.uppercase)
    }
    
    private func MyTextField(_ placeholder: String, _ textInput: Binding<String>) -> some View {
        TextField(placeholder, text: textInput)
            .font(.paragraphP1().weight(.semibold))
            .foregroundColor(disableEditForImported ? .textSecondary : .textPrimary)
    }
    
    private func PickerLabel(title: String, icon: Image, iconColor: Color) -> some View {
        Label {
            Text(title)
                .font(.paragraphP1())
                .fontWeight(.semibold)
        } icon: {
            icon.foregroundColor(iconColor)
        }
    }
    
    private func DetailedPickerLabel<Item: Hashable>(value: String, innerIcon: Image?, innerIconColor: Color, item: Item, itemComparator: Item) -> some View {
        HStack {
            Label {
                Text(value)
                    .font(.paragraphP1())
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
            } icon: {
                // Inner picker icon (optional)...
                innerIcon != nil ?
                innerIcon!
                    .foregroundColor(innerIconColor)
                : nil
            }
            
            Spacer()

            // Checkmark to indicate selected item...
            item == itemComparator ?
            Image("checkmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.accent)
            : nil
        }
    }
    
    private func MyTimePicker(title: String, selectedTime: Binding<Date>, range: ClosedRange<Date>?) -> some View {
        guard let validRange = range else {
            return DatePicker(title, selection: selectedTime, displayedComponents: .hourAndMinute)
                .font(.paragraphP1().weight(.semibold))
        }
        
        return DatePicker(title, selection: selectedTime, in: validRange, displayedComponents: .hourAndMinute)
            .font(.paragraphP1().weight(.semibold))
    }
}
