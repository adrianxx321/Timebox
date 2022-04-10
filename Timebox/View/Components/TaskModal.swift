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
    // MARK: Core Data Context
    @Environment(\.managedObjectContext) var context
    // MARK: ViewModels
    @EnvironmentObject var taskModel: TaskViewModel
    // MARK: Dismissal action for modal pop up
    @Environment(\.dismiss) var dismiss
    // MARK: UI States
    @State private var isModalActive = false
    @State private var showColorPicker = false
    @State private var isEdited: [String: Bool] = [
        "taskTitle" : false,
        "subtasks" : false,
        "taskLabel" : false,
        "color" : false,
        "isImportant" : false,
        "duration" : false,
        "taskStartTime" : false,
        "taskEndTime" : false,
    ]
    @State private var showDiscardConfirm = false
    
    // MARK: Task properties to be saved to Core Data...
    @State var id: UUID = UUID.init()
    @State var taskTitle: String = ""
    @State var subtasks: [Subtask] = []
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
    // Predefined color list
    static private let colors = [
        ColorChoice(name: "Red", value: UIColor.red),
        ColorChoice(name: "Blue", value: UIColor.blue),
        ColorChoice(name: "Purple", value: UIColor.purple),
        ColorChoice(name: "Orange", value: UIColor.orange),
        ColorChoice(name: "Green", value: UIColor.green),
    ]
    
    // MARK: UI States
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
                                    if !self.isEdited.contains(where: { $0.value }) {
                                        self.taskTitle = task.taskTitle ?? ""
                                    }
                                }
                            }
                            .onChange(of: taskTitle, perform: { newValue in
                                self.isEdited["taskTitle"] = self.taskTitle != taskModel.editTask?.taskTitle
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
                                    self.subtasks.remove(atOffsets: index)
                                }
                            }
                            
                            HStack(spacing: 16) {
                                Button {
                                    withAnimation {
                                        self.subtasks.append(taskModel.addSubtask(context: self.context))
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
                                if !self.isEdited.contains(where: { $0.value }) {
                                    self.subtasks = task.subtasks
                                }
                            }
                        }
                        .onChange(of: self.subtasks, perform: { newValue in
                            self.isEdited["subtasks"] = self.subtasks != taskModel.editTask?.subtasks
                        })
                    }

                    // Tag name...
                    Section {
                        MyTextField("Tag (optional)", $taskLabel)
                            .onAppear {
                                if let task = taskModel.editTask {
                                    if !self.isEdited.contains(where: { $0.value }) {
                                        self.taskLabel = task.taskLabel ?? ""
                                    }
                                }
                            }
                            .onChange(of: taskLabel, perform: { newValue in
                                self.isEdited["taskLabel"] = self.taskLabel != taskModel.editTask?.taskLabel
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
                                        self.selectedCustomColor = ColorChoice(name: "Custom...", value: existingTask.color ?? .accent)
                                        self.selectedColor = selectedCustomColor
                                        return color = selectedColor.value
                                    }
                                    selectedColor = TaskModal.colors[index]
                                    color = selectedColor.value
                                }
                            }
                        }
                        .onChange(of: selectedColor, perform: { newColor in
                            self.color = newColor.value
                            self.isEdited["color"] = color != taskModel.editTask?.color
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
                                if !self.isEdited.contains(where: { $0.value }) {
                                    self.isImportant = task.isImportant
                                }
                            }
                        }
                        .onChange(of: isImportant, perform: { newValue in
                            self.isEdited["isImportant"] = isImportant != taskModel.editTask?.isImportant
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
                                if !self.isEdited.contains(where: { $0.value }) {
                                    self.selectedDuration = !taskModel.isScheduledTask(task) ? .untimed
                                    : taskModel.isAllDayTask(task) ? .allDay
                                    : .timeboxed
                                }
                            }
                        }
                        .onChange(of: selectedDuration, perform: { newValue in
                            switch newValue {
                                case .untimed:
                                self.taskStartTime = nil
                                self.taskEndTime = nil
                                
                                case .allDay:
                                    // Start & end time will always be 0000 & 2359
                                    guard let existingTask = taskModel.editTask else {
                                        self.taskStartTime = Calendar.current.startOfDay(for: Date())
                                        self.taskEndTime = taskEndTime!.getOneMinToMidnight()
                                        
                                        return
                                    }
                                self.taskStartTime = taskModel.isAllDayTask(existingTask) ? existingTask.taskStartTime : Calendar.current.startOfDay(for: Date())
                                self.taskEndTime = taskStartTime!.getOneMinToMidnight()
                                
                                case .timeboxed:
                                    guard let existingTask = taskModel.editTask else {
                                        taskStartTime = Date().getNearestHour()
                                        taskEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: taskStartTime!)

                                        return
                                    }
                                    taskStartTime = taskModel.isTimeboxedTask(existingTask) ? existingTask.taskStartTime : Date().getNearestHour()
                                    taskEndTime = taskModel.isTimeboxedTask(existingTask) ? existingTask.taskEndTime : Calendar.current.date(byAdding: .hour, value: 1, to: taskStartTime!)
                            }
                            // MARK: (EDIT MODE) Initial values unchanged
                            self.isEdited["taskStartTime"]! = self.taskStartTime != taskModel.editTask?.taskStartTime
                            self.isEdited["taskEndTime"]! = self.taskEndTime != taskModel.editTask?.taskEndTime
                            self.isEdited["duration"]! = self.isEdited["taskStartTime"]! && self.isEdited["taskEndTime"]!
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
                                        self.taskStartTime = Calendar.current.startOfDay(for: newValueUnwrapped)
                                        self.taskEndTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: newValueUnwrapped)
                                        case .timeboxed:
                                            guard let existingTask = taskModel.editTask else {
                                                self.taskEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: newValueUnwrapped)

                                                return
                                            }
                                        // If existing task is also timeboxed, then endtime should be retained
                                        // If existing task is all-day/untimed, then use current time + 1 hour for endtime
                                        if taskModel.isTimeboxedTask(existingTask) {
                                            let isReversed = newValueUnwrapped < existingTask.taskStartTime!
                                            let interval = DateInterval(start: isReversed ? newValueUnwrapped : existingTask.taskStartTime!,
                                                                        end: isReversed ? existingTask.taskStartTime! : newValueUnwrapped)
                                            let dayDiff = isReversed ? interval.duration * -1 : interval.duration
                                            
                                            self.taskEndTime = existingTask.taskEndTime!.addingTimeInterval(dayDiff)
                                        } else {
                                            self.taskEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: newValueUnwrapped)
                                        }
                                    }
                                    self.isEdited["taskStartTime"] = self.taskStartTime != taskModel.editTask?.taskStartTime
                                    self.isEdited["taskEndTime"] = self.taskEndTime != taskModel.editTask?.taskEndTime
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
                                if !self.isEdited.contains(where: { $0.value }) {
                                    self.taskStartTime = task.taskStartTime
                                    self.taskEndTime = task.taskEndTime
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
                    .disabled((self.taskTitle == ""
                               || self.subtasks.contains(where: {$0.subtaskTitle == ""}))
                              || !isEdited.contains(where: { $0.value }))
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
