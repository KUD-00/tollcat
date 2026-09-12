import MeterCore
import MeterDesign

extension MeterDesign.CatMood {
    init(_ mood: MeterCore.CatMood) {
        self = Self(rawValue: mood.rawValue) ?? .normal
    }
}
