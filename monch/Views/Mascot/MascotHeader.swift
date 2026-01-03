//
//  MascotHeader.swift
//  monch
//
//  Created by Opencode Agent on 03/01/2026.
//

import SwiftUI

struct MascotHeader: View {
    // This will eventually bind to the MascotStateManager
    @State private var mood: String = "neutral"
    
    var body: some View {
        HStack {
            // Placeholder for the Mascot Asset
            ZStack {
                Circle()
                    .fill(Color.mint.opacity(0.3)) // Sage Green placeholder
                    .frame(width: 60, height: 60)
                
                Text("😐") // Neutral face
                    .font(.largeTitle)
            }
            
            VStack(alignment: .leading) {
                Text("Monch is calm")
                    .font(.system(.headline, design: .rounded))
                Text("Ready to log?")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.primary.opacity(0.05))
    }
}

#Preview {
    MascotHeader()
}
