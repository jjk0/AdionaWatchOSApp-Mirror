//
//  CodeChangeConfirmation.swift.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 7/14/22.
//

import SwiftUI

struct CodeChangeConfirmation: View {
    @Binding var dismissFlag: Bool
    @Binding var showKeyboardFlag: Bool

    var body: some View {
        ZStack {
            Color("BackgroundBlue")
            VStack(alignment: .center, spacing: 8.0) {
                Spacer()
                Text("Current Code: \(UserDefaults.standard.string(forKey: "bucket_name") ?? "-----")")
                Text("Are you sure you want to re-enter the code?").frame(alignment: .center)
                Spacer()
                Button(action: {
                    dismissFlag.toggle()
                    showKeyboardFlag = true
                }) {
                    Text("Yes")
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                }
                .frame(height: 30, alignment: .center)
                .background(Color.white)
                .cornerRadius(15)
                Spacer()
            }.padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
        }.ignoresSafeArea()
    }
}
