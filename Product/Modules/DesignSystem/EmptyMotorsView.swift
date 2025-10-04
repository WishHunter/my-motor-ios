import SwiftUI

struct EmptyMotorsView: View {
  var body: some View {
    VStack(spacing: 24) {
      Image(systemName: "motorcycle")
        .font(.system(size: 80))
        .foregroundColor(.secondary)

      VStack(spacing: 12) {
        Text("Нет мотоциклов")
          .font(.title2)
          .fontWeight(.semibold)

        Text("Добавьте свой первый мотоцикл в разделе \"Добавить мотоцикл\"")
          .font(.subheadline)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 40)
      }
    }
    .padding(60)
  }
}
