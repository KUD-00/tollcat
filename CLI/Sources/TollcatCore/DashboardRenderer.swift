import MeterBridge

enum DashboardRenderer {
    static func render(
        _ document: DashboardDocument,
        localeTag: String,
        color: ColorPolicy
    ) -> String {
        if document.empty {
            return JNICopy.text("还没有接入任何服务。", localeTag)
        }
        var lines: [String] = []
        let month = document.monthTitle
        if !month.isEmpty {
            lines.append(color.wrap(month, ANSIColor.dim))
        }
        lines.append(
            row(
                JNICopy.text("本月至今", localeTag),
                color.wrap(document.formattedVariable, ANSIColor.bold),
                nameWidth: 12
            )
        )
        if !document.formattedProjected.isEmpty {
            lines.append(
                row(
                    JNICopy.text("预计月底", localeTag),
                    document.formattedProjected,
                    nameWidth: 12
                )
            )
        }
        if let caption = document.comparisonCaption {
            let tone = document.comparisonTone ?? "flat"
            let code = tone == "up" ? ANSIColor.red : (tone == "down" ? ANSIColor.green : ANSIColor.dim)
            let percent = document.comparisonPercentText.map { color.wrap($0, code) + " · " } ?? ""
            lines.append(percent + caption)
        }
        if let note = document.currencyNote {
            lines.append(color.wrap(note, ANSIColor.dim))
        }
        if let subscription = document.subscriptionCaption {
            lines.append(subscription)
        }
        if !document.composition.isEmpty {
            lines.append("")
            let nameWidth = document.composition.map { TextWidth.displayWidth($0.displayName) }.max() ?? 8
            let amountWidth = document.composition.map { TextWidth.displayWidth($0.amount) }.max() ?? 6
            for row in document.composition {
                let name = TextWidth.pad(row.displayName, nameWidth)
                let amount = TextWidth.pad(row.amount, amountWidth, alignRight: true)
                let percent = TextWidth.pad("\(row.percent)%", 4, alignRight: true)
                lines.append("\(name)  \(amount)  \(color.wrap(percent, ANSIColor.dim))")
            }
        }
        if let stale = document.staleCaption {
            lines.append("")
            lines.append(color.wrap(stale, ANSIColor.yellow))
        }
        return lines.joined(separator: "\n")
    }

    private static func row(_ label: String, _ value: String, nameWidth: Int) -> String {
        TextWidth.pad(label, nameWidth) + "  " + value
    }
}
