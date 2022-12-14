
import ClockKit
import SwiftUI

struct ComplicationViews: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct ComplicationStandard: View {
    @State var session: HealthDataManager

    var body: some View {
        ZStack {
            ProgressView(
                "Adiona",
                value: 1.0,
                total: 1.0)
                .progressViewStyle(
                    CircularProgressViewStyle(tint: Color.accentColor))
        }
    }
}

class ComplicationViewCircular: CLKComplicationTemplateGraphicCircular {
    var body: some View {
        ZStack {
            ProgressView(
                "Adiona",
                value: 1.0,
                total: 1.0)
                .progressViewStyle(
                    CircularProgressViewStyle(tint: Color.accentColor))
        }
    }
}

struct ComplicationViewCornerCircular: View {
    @State var session: HealthDataManager
    @Environment(\.complicationRenderingMode) var renderingMode

    var body: some View {
        ZStack {
            switch renderingMode {
            case .fullColor:
                Circle()
                    .fill(Color.blue)
            case .tinted:
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [.clear, .white]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 15))
            @unknown default:
                Circle()
                    .fill(Color.white)
            }
            Text("Adiona")
                .foregroundColor(Color.black)
                .complicationForeground()
            Circle()
                .stroke(Color.accentColor, lineWidth: 1)
                .complicationForeground()
        }
    }
}

struct CircularProgressArc: Shape {
    @State var progress: Double = 0.5

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let limit = 0.99
        let halfarc: Double = max(0.01, min(progress, limit)) * 180.0
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: .degrees(90 - halfarc),
            endAngle: .degrees(90 + halfarc),
            clockwise: true)
        return path
    }
}

struct ComplicationViewExtraLargeCircular: View {
    @State var session: HealthDataManager

    var body: some View {
        ZStack(alignment: .center) {
            Circle()
                .foregroundColor(Color.accentColor)
            ProgressView(
                value: 1.0)
                .progressViewStyle(ProgressArc(Color.white))
                .complicationForeground()
            VStack(alignment: .center, spacing: 3.0) {
                Text("Adiona")
                    .font(.footnote)
                    .minimumScaleFactor(0.4)
                    .lineLimit(2)
            }
            .multilineTextAlignment(.center)
            .foregroundColor(.black)
            .complicationForeground()
        }
        .padding([.leading, .trailing], 5)
    }
}

struct ProgressArc<S>: ProgressViewStyle where S: ShapeStyle {
    var strokeContent: S
    var strokeStyle: StrokeStyle

    init(
        _ strokeContent: S,
        strokeStyle style: StrokeStyle = StrokeStyle(lineWidth: 10.0, lineCap: .round))
    {
        self.strokeContent = strokeContent
        self.strokeStyle = style
    }

    func makeBody(configuration: Configuration) -> some View {
        CircularProgressArc(progress: configuration.fractionCompleted ?? 0.0)
            .stroke(strokeContent, style: strokeStyle)
            .shadow(radius: 5.0)
    }
}

struct ComplicationViews_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            CLKComplicationTemplateGraphicCornerCircularView(
                ComplicationViewCornerCircular(
                    session: dummyData)
            ).previewContext(faceColor: .yellow)
            CLKComplicationTemplateGraphicCornerCircularView(
                ComplicationViewCornerCircular(
                    session: dummyData)
            ).previewContext()
        }
        CLKComplicationTemplateGraphicExtraLargeCircularView(
            ComplicationViewExtraLargeCircular(
                session: dummyData)
        ).previewContext()
        CLKComplicationTemplateGraphicExtraLargeCircularView(
            ComplicationViewExtraLargeCircular(
                session: dummyData)
        ).previewContext(faceColor: .blue)
    }
}
