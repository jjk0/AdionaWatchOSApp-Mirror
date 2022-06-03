
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
                "\(session.timeSince())",
                value: 1.0 - session.fractionComplete(),
                total: 1.0)
                .progressViewStyle(
                    CircularProgressViewStyle(tint: Color.accentColor))
        }
    }
}

struct ComplicationViewCircular: View {
    @State var session: HealthDataManager

    var body: some View {
        ZStack {
            ProgressView(
                "\(session.timeSince())",
                value: session.fractionComplete(),
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
            Text("\(session.timeSince())")
                .foregroundColor(Color.black)
                .complicationForeground()
            Circle()
                .stroke(Color.accentColor, lineWidth: 1)
                .complicationForeground()
        }
    }
}

struct ComplicationViewRectangular: View {
    @State var session: HealthDataManager

    var body: some View {
        HStack(spacing: 10) {
            ComplicationViewCircular(session: session)
            VStack(alignment: .leading) {
                Text(session.stateDescription)
                    .font(.title)
                    .minimumScaleFactor(0.4)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 4.0) {
                    Spacer()
                    Text(session.timeSince())
                }
                .font(.footnote)
                .complicationForeground()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10.0)
                .stroke(lineWidth: 1.5)
                .foregroundColor(Color.accentColor)
                .complicationForeground())
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
                value: session.fractionComplete())
                .progressViewStyle(ProgressArc(Color.white))
                .complicationForeground()
            VStack(alignment: .center, spacing: 3.0) {
                Text(session.timeSince())
                    .font(.footnote)
                    .minimumScaleFactor(0.4)
                    .lineLimit(2)
                Text(session.stateDescription)
                    .font(.headline)
                    .minimumScaleFactor(0.4)
                    .lineLimit(2)
                Text(session.timeSince())
                    .font(.footnote)
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
            CLKComplicationTemplateGraphicCircularView(
                ComplicationViewCircular(
                    session:dummyData
                )
            ).previewContext()
            CLKComplicationTemplateGraphicCornerCircularView(
                ComplicationViewCornerCircular(
                    session: dummyData)
            ).previewContext(faceColor: .yellow)
            CLKComplicationTemplateGraphicCornerCircularView(
                ComplicationViewCornerCircular(
                    session: dummyData)
            ).previewContext()
        }
        CLKComplicationTemplateGraphicRectangularFullView(
            ComplicationViewRectangular(
                session: dummyData)
        ).previewContext()
        CLKComplicationTemplateGraphicRectangularFullView(
            ComplicationViewRectangular(
                session: dummyData)
        ).previewContext(faceColor: .orange)
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
