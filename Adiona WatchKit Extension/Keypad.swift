//
//  Keypad.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 6/29/22.
//

import SwiftUI

struct NumericButton: View {
    var action: (String) -> Void
    let digit: String
    
    var body: some View {
        Button(action: {
            action(digit)
        }) {
            Text(digit)
                .font(.system(size: 14).bold())
                .foregroundColor(.white)
                .background(Color.red)
        }
        .background(Color("KeyColor"))
        .frame(width: 55, height: 44, alignment: .center)
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .circular))
    }
}

let columns = [
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible())
]

struct KeypadView: View {
    var onDismiss: (() -> Void)?
    @State var enteredDigits: String
    @State private var showingAlert = false
    let data = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "D"].map { "\($0)" }

    var body: some View {
        let action: (String) -> Void = { digit in
            if enteredDigits.count < 5 {
                enteredDigits.append(digit)
            }
            
            if enteredDigits.count == 5 {
                Uploader.shared.lookupBucket(bucketName: enteredDigits) { exists in
                    showingAlert = exists
                    
                    if !exists {
                        Uploader.shared.createBucket(bucketName: enteredDigits) { success in
                            
                        }
                    }
                }
            }
        }

        GeometryReader { geometry in
            VStack {
            }
            .alert("ID \(enteredDigits) is in use.  Are you sure you entered it correctly?", isPresented: $showingAlert) {
                Button("YES", role: .destructive) { }
                Button("Reenter", role: .cancel) {
                    showingAlert = false
                    enteredDigits = ""
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height - geometry.safeAreaInsets.top, alignment: .center)
            .safeAreaInset(edge: .top) {
                VStack {
                    HStack {
                        TextField("Enter Code", text: $enteredDigits)
                            .frame(minWidth: 100, idealWidth: .infinity, maxWidth: .infinity, minHeight: 16, idealHeight: 16, maxHeight: 16, alignment: .center)
                            .background(Color.clear)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 16).bold())
                    }

                    LazyVGrid(columns: columns, spacing: 1) {
                        ForEach(data, id: \.self) { item in
                            if item == "" {
                                NumericButton(action: action, digit: item).opacity(0)
                            } else if item == "D" {
                                Button(action: {
                                    enteredDigits = String(enteredDigits.dropLast(1))
                                }) {
                                    Image(systemName: "delete.left.fill")
                                        .frame(width: 24, height: 12, alignment: .center)
                                        .font(.system(size: 18).bold())
                                        .foregroundColor(.red)
                                        .padding()
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.black, lineWidth: 2)
                                        )
                                        .opacity(enteredDigits.count == 0 ? 0 : 1)
                                }
                                .background(Color.black)
                            } else {
                                NumericButton(action: action, digit: item)
                            }
                        }
                    }

                    

//                    HStack {
//                        NumericButton(action: action, digit: "1")
//                        NumericButton(action: action, digit: "2")
//                        NumericButton(action: action, digit: "3")
//                    }
//                    HStack {
//                        NumericButton(action: action, digit: "4")
//                        NumericButton(action: action, digit: "5")
//                        NumericButton(action: action, digit: "6")
//                    }
//                    HStack {
//                        NumericButton(action: action, digit: "7")
//                        NumericButton(action: action, digit: "8")
//                        NumericButton(action: action, digit: "9")
//                    }
//
//                    HStack {
//                        NumericButton(action: action, digit: "").opacity(0)
//                        NumericButton(action: action, digit: "0")
//                        Button(action: {
//                            enteredDigits = String(enteredDigits.dropLast(1))
//                        }) {
//                            Image(systemName: "delete.left.fill")
//                                .frame(width: 24, height: 12, alignment: .center)
//                                .font(.system(size: 18).bold())
//                                .foregroundColor(.red)
//                                .padding()
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: 6)
//                                        .stroke(Color.black, lineWidth: 2)
//                                )
//                                .opacity(enteredDigits.count == 0 ? 0 : 1)
//                        }
//                        .background(Color.black)
//                    }
                }
            }
        }
    }
}

struct KeypadView_Previews: PreviewProvider {
    static var previews: some View {
        KeypadView(enteredDigits: "")
    }
}
