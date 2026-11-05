//
//  NavigationBar.swift
//  SketchCapture
//
//  Created by Daniel Leivers on 16/08/2023.
//

import SwiftUI

struct NavigationBar: View {
    var title: String = "Title"
    var showLeftButton: Bool = true
    var showRightButton: Bool = true

    var body: some View {
        HStack {
            VStack {
                Spacer()
                Spacer()
                HStack(alignment: .bottom) {
                    Button("< Back") {
                        print("Back")
                    }
                    .padding(.leading)
                    .opacity(showLeftButton ? 1 : 0)
                    Text(title)
                        .frame(maxWidth: .infinity)
                    Button("Done") {
                        print("Done")
                    }
                    .padding(.trailing)
                    .opacity(showRightButton ? 1 : 0)
                }
                Spacer()
            }
        }
        .background(.cyan)
    }
}

struct NavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        let actualRect = CGRect(x: 0, y: 0, width: 300, height: 150)
        NavigationBar()
            .frame(width: actualRect.width,
                   height: actualRect.height)
    //        .position(x: actualRect.minX,
    //                  y: actualRect.minY)
    //        .frame(width: actualRect.size.width, height: actualRect.size.height)
    //        .background(.yellow.opacity(0.2))
//            .border(.blue, width: 2)
    //        .position(x: actualRect.origin.x, y: actualRect.origin.y)
            .position(x: actualRect.midX, y: actualRect.midY)
    }
}
