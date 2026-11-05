//
//  TabBar.swift
//  SketchCapture
//
//  Created by Daniel Leivers on 01/09/2023.
//

import SwiftUI

struct TabBar: View {
    let numberOfBarItems: Int

    var body: some View {
        VStack {
            Spacer()
            HStack(alignment: .bottom, spacing: 10) {
                ForEach((1...numberOfBarItems), id: \.self) { _ in
                    VStack(spacing: 4) {
                        Image(systemName: "person.circle")
                            .resizable()
                            .frame(maxWidth: 36, maxHeight: 36)
                            .scaledToFit()
                        Text("Profile").font(.callout).padding(.top, 6)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            Spacer()
            Spacer()
        }
        .background(.cyan)
    }
}

struct TabBar_Previews: PreviewProvider {
    static var previews: some View {
        let actualRect = CGRect(x: 0, y: 400, width: 400, height: 150)
        TabBar(numberOfBarItems: 4)
            .frame(width: actualRect.width,
                   height: actualRect.height)
            .position(x: actualRect.midX, y: actualRect.midY)
    }
}
