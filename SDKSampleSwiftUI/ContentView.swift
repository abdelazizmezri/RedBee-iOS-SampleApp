//
//  ContentView.swift
//  SDKSampleSwiftUI
//
//  Created by Udaya Sri Senarathne on 2022-01-11.
//

import SwiftUI
import iOSClientExposure

let lightGreyColor = Color(red: 239.0/255.0, green: 243.0/255.0, blue: 244.0/255.0, opacity: 1.0)

struct ContentView: View {
    
    // Add production / prestage url
    @State var environmentUrl: String = ""
    
    // Add customer name : CU
    @State var customerName: String = ""
    
    // Add business unit name : BU
    @State var businessUnit: String = ""
    
    // Add username / email
    @State var email: String = ""
    
    // Add password
    @State var password: String = ""
    
    @State var authenticationDidSucceed: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                
                NavigationLink(destination: AssetView(), isActive: $authenticationDidSucceed) { EmptyView() }
                
                Text("Player with SwitUI")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .padding(.bottom, 20)
                
                TextField("Enviornment", text: $environmentUrl)
                    .padding()
                    .background(lightGreyColor)
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                TextField("Customer", text: $customerName)
                    .padding()
                    .background(lightGreyColor)
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                TextField("Business Unit", text: $businessUnit)
                    .padding()
                    .background(lightGreyColor)
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                
                TextField("Email", text: $email)
                    .padding()
                    .background(lightGreyColor)
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                
                TextField("Password", text: $password)
                    .padding()
                    .background(lightGreyColor)
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                
                
                Button(action: authenticateUser){
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 220, height: 60)
                        .background(Color.green)
                        .cornerRadius(15.0)
                    
                }
            }
        }

    }
    
    
    /// Authenticate the user
    fileprivate func authenticateUser() {
        let environment = Environment(baseUrl: environmentUrl, customer: customerName, businessUnit: businessUnit)
        
        Authenticate(environment: environment)
            .login(username: email, password: password)
            .request()
            .validate()
            .response{
                if let error = $0.error {
                   print("Error " , error )
                }
                
                if let credentials = $0.value {
                    StorageProvider.store(environment: environment)
                    StorageProvider.store(sessionToken: credentials.sessionToken)
                    
                    self.authenticationDidSucceed = true
                    
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
