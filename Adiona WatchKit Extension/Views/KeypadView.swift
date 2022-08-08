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
                .background(Color.clear)
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
    @Binding var dismissFlag: Bool
    @State private var enteredDigits = ""
    @State private var showingSuccessAlert = false
    @State private var showingExistsAlert = false
    @State private var showingProgress = false
    
    @EnvironmentObject private var extensionDelegate: ExtensionDelegate

    let data = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "D"].map { "\($0)" }

    var body: some View {
        let action: (String) -> Void = { digit in
            if enteredDigits.count < 5 {
                enteredDigits.append(digit)
            }
            
            if enteredDigits.count == 5 {
                showingExistsAlert = true
            }
        }

        GeometryReader { geometry in
            VStack {
            }
            .alert("Are you sure you entered it correctly?", isPresented: $showingExistsAlert) {
                ZStack {
                    Color("BackgroundBlue")
                    Button("YES", role: .destructive) {
                        S3.dataBucket.bucketName = enteredDigits
                        HealthDataManager.shared.adionaData.metaData.user_id = enteredDigits
                        self.showingExistsAlert.toggle()
                        self.showingSuccessAlert.toggle()
                        self.dismissFlag.toggle()
                        extensionDelegate.getProfileData()
                    }
                    Button("Re-enter", role: .cancel) {
                        showingExistsAlert = false
                        enteredDigits = ""
                    }
                }.ignoresSafeArea()
            }
            .alert("Connection Succcessful", isPresented: $showingSuccessAlert) {
                ZStack {
                    Color("BackgroundBlue")
                    Text("Connection Successful!").foregroundColor(Color.white)
                    Button("Done", role: .cancel) {
                        extensionDelegate.getProfileData()
                        showingSuccessAlert.toggle()
                        self.dismissFlag.toggle()
                    }.background(Color.white)
                }
                .ignoresSafeArea()
                .background(Color("BackgroundBlue"))
            }
            .background(Color("BackgroundBlue"))
            .frame(width: geometry.size.width,
                   height: geometry.size.height - geometry.safeAreaInsets.top,
                   alignment: .center)
            .safeAreaInset(edge: .top) {
                ZStack(alignment: .center) {
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
                    }

                    if showingProgress {
                        Rectangle()
                            .fill(Color.black).opacity(showingProgress ? 0.6 : 0)
                        
                        VStack(alignment: .center) {
                            Spacer()
                            ProgressView()
                            Text("Connecting to phone...")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundColor(Color.primary)
                    }
                }
            }
        }
    }
}
