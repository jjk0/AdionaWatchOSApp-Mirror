//
//  ContentView.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 7/14/22.
//

import SwiftUI

struct ContentView: View {
    @State var showingKeypard = false
    @State var showCodeChangeConfirmation = false
    
    var body: some View {
        ZStack {
            Color("BackgroundBlue")
            VStack {
                Button(action: {
                    showCodeChangeConfirmation.toggle()
                }) {
                    Text("re-enter code")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(.blue)
                }
                .frame(height: 30, alignment: .center)
                .background(Color.white)
                .cornerRadius(6)
                .padding()

                HStack(alignment: .center, spacing: 10.0) {
                    VStack(alignment: .center, spacing: 12.0) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6).fill(Color.green).frame(width: 32, height: 32)
                            Image(systemName: "figure.walk")
                                .resizable()
                                .foregroundColor(.white)
                                .frame(width: 21, height: 21, alignment: .center)
                        }
                        ZStack {
                            RoundedRectangle(cornerRadius: 6).fill(Color.red).frame(width: 32, height: 32)
                            Image(systemName: "heart.fill")
                                .resizable()
                                .foregroundColor(.white)
                                .aspectRatio(1, contentMode: .fill)
                                .frame(width: 21, height: 21, alignment: .center)
                        }
                    }

                    VStack(alignment: .center, spacing: 6.0) {
                        VStack {
                            Text(HealthDataManager.shared.stepsToday)
                                .font(.system(size: 18))
                            Text("steps today")
                        }.frame(alignment: .center)
                        VStack {
                            Text(HealthDataManager.shared.heartrate).font(.system(size: 18))
                            Text("heartrate")
                        }.frame(alignment: .center)
                    }.frame(alignment: .center)

                }
                Button(action: {
                    if let phone = HealthDataManager.shared.profileData?.profile_info.caregiver_phone,
                        let telURL = URL(string:"tel:\(phone)") {
                        WKExtension.shared().openSystemURL(telURL)
                    }
                }) {
                    HStack {
                        Image(systemName: "phone.fill")
                            .resizable()
                            .foregroundColor(.blue)
                            .aspectRatio(1, contentMode: .fit)
                            .frame(width: 28, height: 28, alignment: .center)
                        Text("Call " + HealthDataManager.shared.carerName)
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.blue)
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .padding()
            }
        }.fullScreenCover(isPresented: $showingKeypard) {
            KeypadView(dismissFlag: $showingKeypard)
        }.fullScreenCover(isPresented: $showCodeChangeConfirmation) {
            CodeChangeConfirmation(dismissFlag: $showCodeChangeConfirmation, showKeyboardFlag: $showingKeypard)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
