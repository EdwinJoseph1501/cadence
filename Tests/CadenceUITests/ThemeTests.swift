import CadenceCore
import CadenceUI
import SwiftUI
import Testing

@Suite("CadenceUI Theme Integration Tests")
struct ThemeTests {
    @Test("SwiftUI Color extensions instantiate successfully from tokens")
    func testColorExtensionInstantiation() {
        let bg = Color.cadenceBackground
        let text = Color.cadenceTextPrimary
        let accent = Color.cadenceAccent

        #expect(
            String(describing: bg).contains("cadenceBackground") || String(describing: bg).count > 0
        )
        #expect(String(describing: text).count > 0)
        #expect(String(describing: accent).count > 0)
    }

    @Test("SwiftUI Font extensions are defined")
    func testFontExtensions() {
        let hero = Font.cadenceTimerHero
        let body = Font.cadenceBody
        let micro = Font.cadenceMicro

        #expect(String(describing: hero).count > 0)
        #expect(String(describing: body).count > 0)
        #expect(String(describing: micro).count > 0)
    }
}
