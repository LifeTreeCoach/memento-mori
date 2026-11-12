import Testing
@testable import LifeCore

/// Texts must match android/app/src/main/res/values*/strings.xml.
struct WidgetTextTests {
    // 1990-11-17 → 2026-11-02: week 1,877, 2,284 weeks left, 45.1 % lived (fixture "typical adult").
    let calc = LifeCalculator(
        birthDate: CivilDate(year: 1990, month: 11, day: 17)!,
        today: CivilDate(year: 2026, month: 11, day: 2)!
    )
    let en = WidgetText(language: .en)
    let de = WidgetText(language: .de)
    let fr = WidgetText(language: .fr)
    let es = WidgetText(language: .es)

    @Test func english() {
        #expect(en.weekLabel.uppercased() == "WEEK")
        #expect(en.widgetDescription == "Your life in weeks: the current week and the time you have left")
        #expect(en.weekNumber(calc) == "Week 1,877")
        #expect(en.ofTotal(4160) == "of 4,160")
        #expect(en.percent(calc) == "45%")
        #expect(en.percentLived(calc) == "45% lived")
        #expect(en.remaining(calc, mode: .weeks) == "2,284 weeks left")
        #expect(en.remaining(calc, mode: .years) == "45 years left")
    }

    @Test func german() {
        #expect(de.weekLabel.uppercased() == "WOCHE")
        #expect(de.widgetDescription == "Dein Leben in Wochen: die aktuelle Woche und die verbleibende Zeit")
        #expect(de.weekNumber(calc) == "Woche 1.877")
        #expect(de.ofTotal(4160) == "von 4.160")
        #expect(de.percent(calc) == "45\u{00A0}%")
        #expect(de.percentLived(calc) == "45\u{00A0}% gelebt")
        #expect(de.remaining(calc, mode: .weeks) == "noch 2.284 Wochen")
        #expect(de.remaining(calc, mode: .months) == "noch 529 Monate")
    }

    @Test func french() {
        #expect(fr.weekLabel.uppercased() == "SEMAINE")
        #expect(fr.widgetDescription == "Ta vie en semaines\u{00A0}: la semaine en cours et le temps qu’il te reste")
        #expect(fr.weekNumber(calc) == "Semaine 1\u{202F}877")
        #expect(fr.ofTotal(4160) == "sur 4\u{202F}160")
        #expect(fr.percent(calc) == "45\u{00A0}%")
        #expect(fr.percentLived(calc) == "45\u{00A0}% vécu")
        #expect(fr.remaining(calc, mode: .weeks) == "encore 2\u{202F}284 semaines")
        #expect(fr.remaining(calc, mode: .months) == "encore 529 mois")
        #expect(fr.remaining(calc, mode: .years) == "encore 45 ans")
        #expect(fr.shortWeekNumber(1877) == "S1877")
    }

    @Test func spanish() {
        #expect(es.weekLabel.uppercased() == "SEMANA")
        #expect(es.widgetDescription == "Tu vida en semanas: la semana actual y el tiempo que te queda")
        // Foundation follows CLDR minimumGroupingDigits = 2 for Spanish: 4-digit numbers stay ungrouped.
        #expect(es.weekNumber(calc) == "Semana 1877")
        #expect(es.number(29_120) == "29.120")
        #expect(es.ofTotal(4160) == "de 4160")
        #expect(es.percent(calc) == "45\u{00A0}%")
        #expect(es.percentLived(calc) == "45\u{00A0}% vivido")
        #expect(es.remaining(calc, mode: .weeks) == "quedan 2284 semanas")
        #expect(es.remaining(calc, mode: .days) == "quedan 16.086 días")
        #expect(es.shortWeekNumber(1877) == "S1877")
    }

    @Test func weekPrefix() {
        #expect(en.shortWeekNumber(1912) == "W1912")
        #expect(de.shortWeekNumber(1912) == "W1912")
        #expect(fr.weekPrefix == "S")
        #expect(es.weekPrefix == "S")
    }

    @Test func singular() throws {
        let lastWeek = LifeCalculator(
            birthDate: try #require(CivilDate(year: 2000, month: 1, day: 1)),
            lifeExpectancyYears: 1,
            today: try #require(CivilDate(year: 2000, month: 12, day: 23))
        )
        #expect(lastWeek.weeksRemaining == 1)
        #expect(en.remaining(lastWeek, mode: .weeks) == "1 week left")
        #expect(de.remaining(lastWeek, mode: .weeks) == "noch 1 Woche")
        #expect(fr.remaining(lastWeek, mode: .weeks) == "encore 1 semaine")
        #expect(es.remaining(lastWeek, mode: .weeks) == "queda 1 semana")
    }

    /// French uses the singular for 0 too (CLDR "one" = 0 and 1, like Android's plurals).
    @Test func frenchZeroIsSingular() throws {
        let done = LifeCalculator(
            birthDate: try #require(CivilDate(year: 2000, month: 1, day: 1)),
            lifeExpectancyYears: 1,
            today: try #require(CivilDate(year: 2001, month: 6, day: 1))
        )
        #expect(done.remaining(.years) == 0)
        #expect(fr.remaining(done, mode: .years) == "encore 0 an")
        #expect(en.remaining(done, mode: .years) == "0 years left")
        #expect(es.remaining(done, mode: .years) == "quedan 0 años")
    }

    @Test func percentShowsTheFloor() throws {
        let nearlyDone = LifeCalculator(
            birthDate: try #require(CivilDate(year: 2000, month: 1, day: 1)),
            lifeExpectancyYears: 1,
            today: try #require(CivilDate(year: 2000, month: 12, day: 23))
        )
        #expect(nearlyDone.percentLived > 98 && nearlyDone.percentLived < 99)
        #expect(en.percent(nearlyDone) == "98%")
    }
}
