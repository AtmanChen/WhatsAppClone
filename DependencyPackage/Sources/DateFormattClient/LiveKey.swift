import Foundation
import Dependencies

private let dateFormatter: DateFormatter = {
	let dateFormatter = DateFormatter()
	return dateFormatter
}()
private let dateFormattString = "MM/dd/yy"
private let timeFormattString = "h:mm a"
private let dateTimeFormattString = "h:mm a MM/dd/yy"
private let inWeekRelativeFormattString = "EEEE"
private let inYearRelativeFormattString = "E, MMM d"
private let yearMonthDayFormattString = "MMM dd, yyyy"

extension DateFormattClient: DependencyKey {
	public static var liveValue = DateFormattClient(
		dayOrTimeRepresentation: { date in
			@Dependency(\.date.now) var now
			let calendar = Calendar.current
			if calendar.isDateInToday(date) {
				dateFormatter.dateFormat = timeFormattString
				return dateFormatter.string(from: date)
			} else if calendar.isDateInYesterday(date) {
				return "Yesterday"
			} else {
				dateFormatter.dateFormat = dateFormattString
				return dateFormatter.string(from: date)
			}
		},
		timeRepresentation: { date in
			let calendar = Calendar.current
			if calendar.isDateInToday(date) {
				dateFormatter.dateFormat = timeFormattString
				return dateFormatter.string(from: date)
			} else {
				dateFormatter.dateFormat = dateTimeFormattString
				return dateFormatter.string(from: date)
			}
		},
		stringWithFormat: { formatt in
			dateFormatter.dateFormat = formatt
			@Dependency(\.date.now) var now
			return dateFormatter.string(from: now)
		},
		messageHeaderRelativeRepresentation: { date in
			@Dependency(\.date.now) var now
			let calendar = Calendar.current
			func isCurrentWeek(left: Date, right: Date) -> Bool {
				calendar.isDate(left, equalTo: right, toGranularity: .weekday)
			}
			func isCurrentYear(left: Date, right: Date) -> Bool {
				calendar.isDate(left, equalTo: right, toGranularity: .year)
			}
			
			if calendar.isDateInToday(date) {
				return "Today"
			} else if calendar.isDateInYesterday(date) {
				return "Yesterday"
			} else if isCurrentWeek(left: date, right: now) {
				dateFormatter.dateFormat = inWeekRelativeFormattString
				return dateFormatter.string(from: date)
			} else if isCurrentYear(left: date, right: now) {
				dateFormatter.dateFormat = inYearRelativeFormattString
				return dateFormatter.string(from: date)
			} else {
				dateFormatter.dateFormat = yearMonthDayFormattString
				return dateFormatter.string(from: date)
			}
		}
	)
}
