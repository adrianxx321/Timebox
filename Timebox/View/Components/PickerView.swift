//
//  CustomPicker.swift
//  Timebox
//
//  Created by Lianghan Siew on 20/03/2022.
//

import SwiftUI

struct PickerView<Item>: View where Item: Hashable {
    @State private var isActive = false
    @Binding var selectedItem: Item
    let items: [Item]
    let screenTitle: String
    let mainIcon: Image
    let mainIconColor: Color?
    let mainLabel: String
    let innerIcon: Image?
    let innerIconColor: Color?
    let innerLabel: KeyPath<Item, String>
    let hideSelectedValue: Bool

    var body: some View {
        NavigationLink(isActive: $isActive) {
            List {
                ForEach(items, id: \.self) { item in
                    Button {
                        selectedItem = item
                        isActive.toggle()
                    } label: {
                        HStack {
                            Label {
                                // Main keypath...
                                // << Value here
                                Text(item[keyPath: innerLabel])
                                    .font(.paragraphP1())
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)
                            } icon: {
                                // Inner picker icon (optional)...
                                innerIcon != nil ?
                                innerIcon!
                                    .foregroundColor(innerIconColor != nil ? innerIconColor : .textPrimary)
                                : nil
                            }
                            
                            Spacer()

                            // Checkmark to indicate selected item...
                            selectedItem == item ?
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.accent)
                            : nil
                        }
                    }
                }
            }
            .navigationTitle(screenTitle)
        } label: {
            Label {
                HStack {
                    // MARK: Main label
                    // Can be static string, or value from main keypath passed
                    Text(hideSelectedValue ? selectedItem[keyPath: innerLabel] : mainLabel)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    !hideSelectedValue ?
                    Text(selectedItem[keyPath: innerLabel])
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)
                    : nil
                    
                }
                .font(.paragraphP1())

            } icon: {
                // MARK: Main icon [required]
                mainIcon
                    .foregroundColor(mainIconColor != nil ? mainIconColor : .textPrimary)
            }
        }
    }
}
