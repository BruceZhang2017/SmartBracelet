//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  CalendarView.swift
//  TJDWristbandSDKDemo
//
//  Created by ANKER on 2020/9/30.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class CommonCalendarView: UIView {

    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var menuView: CVCalendarMenuView!
    @IBOutlet weak var calendarView: CVCalendarView!
    private var currentCalendar: Calendar?
    private var monthView: AudioButtonView!
    private var yearView: AudioButtonView!
    weak var delegate: CommonCalendarViewProtocol?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        currentCalendar = Calendar(identifier: .gregorian)
        currentCalendar?.locale = Locale(identifier: "en_US")
        menuView.calendar = currentCalendar
        addSubView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        menuView.commitMenuViewUpdate()
        calendarView.commitCalendarViewUpdate()
    }
    
    private func addSubView() {
        monthView = AudioButtonView(frame: .zero).then {
            $0.label.text = "11"
            $0.unitLabel.text = "月"
        }
        topView.addSubview(monthView)
        monthView.snp.makeConstraints {
            $0.height.equalTo(40)
            $0.left.equalTo(20)
            $0.centerY.equalToSuperview()
        }
        yearView = AudioButtonView(frame: .zero).then {
            $0.label.text = "2020"
            $0.unitLabel.text = "年"
        }
        topView.addSubview(yearView)
        yearView.snp.makeConstraints {
            $0.height.equalTo(40)
            $0.right.equalTo(-20)
            $0.centerY.equalToSuperview()
        }
    }

}

// MARK: - CVCalendarViewDelegate & CVCalendarMenuViewDelegate

extension CommonCalendarView: CVCalendarViewDelegate, CVCalendarMenuViewDelegate {
    
    // MARK: Required methods
    
    func presentationMode() -> CalendarMode { return .monthView } // 显示月模式
    
    func firstWeekday() -> Weekday { return .sunday } // 星期天
    
    // MARK: Optional methods
    
    func calendar() -> Calendar? { return currentCalendar } // 当前时间
    func calendarValue() -> Calendar {
        if currentCalendar != nil {
            return currentCalendar!
        }
        currentCalendar = Calendar(identifier: .gregorian)
        currentCalendar?.locale = Locale(identifier: "en_US")
        return currentCalendar!
    }
    
    func dayOfWeekTextColor(by weekday: Weekday) -> UIColor { // 当前周字颜色
        return UIColor.colorWithRGB(rgbValue: 0x8EA9E0)
    }
    
    func shouldShowWeekdaysOut() -> Bool { return true }
    
    // Defaults to true
    func shouldAnimateResizing() -> Bool { return true }
    
    private func shouldSelectDayView(dayView: DayView) -> Bool {
        return true
    }
    
    func shouldAutoSelectDayOnMonthChange() -> Bool { return false }
    
    func didSelectDayView(_ dayView: CVCalendarDayView, animationDidFinish: Bool) {
        // 选中某天
        let date = DateHelper().ymdToDate(y: dayView.date.year, m: dayView.date.month, d: dayView.date.day)
        delegate?.callbackForHide(date)
    }
    
    func shouldSelectRange() -> Bool { return false }
    
    func didSelectRange(from startDayView: DayView, to endDayView: DayView) {
        print("RANGE SELECTED: \(startDayView.date.commonDescription) to \(endDayView.date.commonDescription)")
    }
    
    func presentedDateUpdated(_ date: CVDate) {

    }
    
    func topMarker(shouldDisplayOnDayView dayView: CVCalendarDayView) -> Bool { return true }
    
    func shouldHideTopMarkerOnPresentedView() -> Bool {
        return true
    }
    
    func weekdaySymbolType() -> WeekdaySymbolType { return .short }
    
    func selectionViewPath() -> ((CGRect) -> (UIBezierPath)) {
        return { UIBezierPath(rect: CGRect(x: 0, y: 0, width: $0.width, height: $0.height)) }
    }
    
    func shouldShowCustomSingleSelection() -> Bool { return true }
    
    func preliminaryView(viewOnDayView dayView: DayView) -> UIView {
        let circleView = CVAuxiliaryView(dayView: dayView, rect: dayView.frame, shape: CVShape.circle)
        circleView.fillColor = UIColor.clear
        return circleView
    }
    
    func preliminaryView(shouldDisplayOnDayView dayView: DayView) -> Bool {
        if dayView.date == nil {
            return false
        }
        return false
    }
    
    func supplementaryView(viewOnDayView dayView: DayView) -> UIView {
        
        dayView.setNeedsLayout()
        dayView.layoutIfNeeded()
        let newView = UIView(frame: dayView.frame)
        
        return newView
    }
    
    func supplementaryView(shouldDisplayOnDayView dayView: DayView) -> Bool {
        guard let currentCalendar = currentCalendar else { return false }
        
        let components = Manager.componentsForDate(Foundation.Date(), calendar: currentCalendar)
        
        /* For consistency, always show supplementaryView on the 3rd, 13th and 23rd of the current month/year.  This is to check that these expected calendar days are "circled". There was a bug that was circling the wrong dates. A fix was put in for #408 #411.
         
         Other month and years show random days being circled as was done previously in the Demo code.
         */
        let shouldDisplay = true
        
        return shouldDisplay
    }
    
    func dayOfWeekTextColor() -> UIColor { return UIColor.colorWithRGB(rgbValue: 0x8EA9E0) }
    
    func dayOfWeekBackGroundColor() -> UIColor { return .clear }
    
    func disableScrollingBeforeDate() -> Date { return Date() }
    
    func maxSelectableRange() -> Int { return 14 }
    
    //func earliestSelectableDate() -> Date { return Date() }
    
    func latestSelectableDate() -> Date {
        var dayComponents = DateComponents()
        dayComponents.day = 70
        let calendar = Calendar(identifier: .gregorian)
        if let lastDate = calendar.date(byAdding: dayComponents, to: Date()) {
            return lastDate
        }
        
        return Date()
    }
}


// MARK: - CVCalendarViewAppearanceDelegate

extension CommonCalendarView: CVCalendarViewAppearanceDelegate {
    
    func dayLabelWeekdayDisabledColor() -> UIColor { return .lightGray }
    
    func dayLabelPresentWeekdayInitallyBold() -> Bool { return false }
    
    func spaceBetweenDayViews() -> CGFloat { return 0 }
    
    func dayLabelFont(by weekDay: Weekday, status: CVStatus, present: CVPresent) -> UIFont { return UIFont.systemFont(ofSize: 14) }
    
    func dayLabelColor(by weekDay: Weekday, status: CVStatus, present: CVPresent) -> UIColor? {
//        switch (weekDay, status, present) {
//        case (_, .selected, _), (_, .highlighted, _): return ColorsConfig.selectedText
//        case (.sunday, .in, _): return ColorsConfig.sundayText
//        case (.sunday, _, _): return ColorsConfig.sundayTextDisabled
//        case (_, .in, _): return ColorsConfig.text
//        default: return ColorsConfig.textDisabled
//        }
        return nil
    }
    
    func dayLabelBackgroundColor(by weekDay: Weekday, status: CVStatus, present: CVPresent) -> UIColor? {
//        switch (weekDay, status, present) {
//        case (.sunday, .selected, _), (.sunday, .highlighted, _): return ColorsConfig.sundaySelectionBackground
//        case (_, .selected, _), (_, .highlighted, _): return ColorsConfig.selectionBackground
//        default: return nil
//        }
        return nil
    }
}

protocol CommonCalendarViewProtocol: NSObjectProtocol {
    func callbackForHide(_ date: Date)
}
