//: A UIKit based Playground for presenting user interface
  
import SwiftUI
import PlaygroundSupport

struct NumericButton: View {
    var action: (String) -> Void
    let digit: String
    
    var body: some View {
        Button(action: {
            action(digit)
        }) {
            Text(digit)
                .frame(width: 24, height: 12, alignment: .center)
                .font(.system(size: 18).bold())
                .foregroundColor(.white)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.black, lineWidth: 2)
                )
        }
        .background(Color.black)
    }
}

struct KeypadView: View {
    @State var enteredDigits: String
    @State private var showingAlert = false

    var body: some View {
        let action: (String) -> Void = { digit in
            if enteredDigits.count < 5 {
                enteredDigits.append(digit)
            }
            
            if enteredDigits.count == 5 {
                showingAlert = true
            }
        }

        TextField("", text: $enteredDigits)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Color.clear)
            .multilineTextAlignment(.center)
            .font(.system(size: 18).bold())
        VStack {
            HStack {
                NumericButton(action: action, digit: "1")
                NumericButton(action: action, digit: "2")
                NumericButton(action: action, digit: "3")
            }
            HStack {
                NumericButton(action: action, digit: "3")
                NumericButton(action: action, digit: "4")
                NumericButton(action: action, digit: "5")
            }
            HStack {
                NumericButton(action: action, digit: "6")
                NumericButton(action: action, digit: "7")
                NumericButton(action: action, digit: "8")
            }

            HStack {
                Spacer()
                NumericButton(action: action, digit: "0")
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
            }
        }
        .lineSpacing(1.0)
        .alert("ID \(enteredDigits) is in use.  Are you sure you entered it correctly?", isPresented: $showingAlert) {
            Button("YES", role: .destructive) { }
            Button("Reenter", role: .cancel) {
                showingAlert = false
                enteredDigits = ""
            }
        }
    }
}


PlaygroundPage.current.setLiveView(KeypadView(enteredDigits: ""))
