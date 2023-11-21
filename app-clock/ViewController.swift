//
//  ViewController.swift
//  app-clock
//
//  Created by x21004xx on 2023/08/18.
//

import UIKit
import EventKit

class ViewController: UIViewController {
    // カレンダーへのアクセス許可状態
    var isAuthorized: Bool = false
    
    // 今日と明日の予定を格納する配列
    var events: [EKEvent] = []
    
    // 時計の針を格納するビュー
    var hourHand: UIView!
    var minuteHand: UIView!
    var secondHand: UIView!
    
    var timer = Timer()
    
    // 予定タイトルを表示するテーブルビュー
    var tableView: UITableView!
    
    // 予定タイトルを格納する配列
    var eventTitles: [String] = []
    
    var eventPaths: [UIBezierPath] = []
    
    let eventColors: [UIColor] = [
        UIColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 1.0),
        UIColor(red: 1.0, green: 0.2, blue: 0.7, alpha: 1.0),
        UIColor(red: 0.8, green: 1.0, blue: 0.1, alpha: 1.0),
        UIColor(red: 0.6, green: 0.6, blue: 1.0, alpha: 1.0),
        UIColor(red: 1.0, green: 0.6, blue: 0.6, alpha: 1.0),
        UIColor(red: 0.6, green: 1, blue: 0.6, alpha: 1.0)
    ]
    
    override func viewDidLoad() {
            super.viewDidLoad()
            checkCalendarAuthorizationStatus()
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateClock), userInfo: nil, repeats: true)
        
        // データ更新ボタンを作成
                let updateDataButton = UIButton(type: .system)
        // イラストの画像名を指定
        let buttonImage = UIImage(named: "load_icon.png")
                updateDataButton.setImage(buttonImage, for: .normal)
                updateDataButton.addTarget(self, action: #selector(updateData), for: .touchUpInside)
                updateDataButton.frame = CGRect(x:320, y: 40, width: 30, height: 30)
                view.addSubview(updateDataButton)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            view.addGestureRecognizer(tapGesture)
        }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: view)
        
        for (index, path) in eventPaths.enumerated() {
            if path.contains(point) {
                if index < events.count {
                    let event = events[index]
                    showEventDetails(event: event)
                }
                break
            }
        }
    }
    
    func showEventDetails(event: EKEvent) {
        let alertController = UIAlertController(title: event.title, message: "", preferredStyle: .actionSheet)
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let startTime = formatter.string(from: event.startDate)
        let endTime = formatter.string(from: event.endDate)
        
        alertController.message = "時間: \(startTime) - \(endTime)"
        
        let dismissAction = UIAlertAction(title: "閉じる", style: .cancel, handler: nil)
        alertController.addAction(dismissAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func updateData() {
        // カレンダーからデータを再読み込み
        loadEvents()
        
        // データを再読み込みした後に必要なUIの更新などを行う
        // たとえば、テーブルビューをリロードする場合:
        tableView.reloadData()
    }

    @objc func checkCalendarAuthorizationStatus() {
            let status = EKEventStore.authorizationStatus(for: .event)
            switch status {
            case .authorized:
                loadEvents()
            case .notDetermined:
                requestAccessToCalendar()
            default:
                showAccessDeniedAlert()
            }
        }
    
    @objc func updateClock() {
            updateClockHands()
            updateEventTitleList()
            
            // 現在の日付を取得してフォーマット
            let currentDate = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy年MM月dd日 (E)"
            let formattedDate = dateFormatter.string(from: currentDate)
            
            // 日付けと曜日を表示するラベルを作成
            let dateLabel = UILabel(frame: CGRect(x: 0, y: 100, width: view.bounds.width, height: 30))
            dateLabel.text = formattedDate
            dateLabel.textColor = UIColor.black
            dateLabel.textAlignment = .center
            view.addSubview(dateLabel)
        }
    
    func requestAccessToCalendar() {
            let eventStore = EKEventStore()
            eventStore.requestAccess(to: .event) { (granted, error) in
                if granted {
                    self.loadEvents()
                } else {
                    self.showAccessDeniedAlert()
                }
            }
        }
    
    func loadEvents() {
            let eventStore = EKEventStore()
            let currentDate = Date()
            let twelveHoursLater = Calendar.current.date(byAdding: .hour, value: 12, to: currentDate)!
            let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
            
            let startDate = currentDate
            let endDate = twelveHoursLater
            
            let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
            let nextDayPredicate = eventStore.predicateForEvents(withStart: nextDay, end: twelveHoursLater, calendars: nil)
            
            events = eventStore.events(matching: predicate) + eventStore.events(matching: nextDayPredicate)
            
            // 予定のタイトルと時間を配列に追加
            eventTitles = events.compactMap { event in
                guard let title = event.title else {
                    return nil
                }
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                let startTime = formatter.string(from: event.startDate)
                let endTime = formatter.string(from: event.endDate)
                return "\(title) (\(startTime) - \(endTime))"
            }
            
            DispatchQueue.main.async {
                self.updateClockHands()
                self.updateEventTitleList() // 予定タイトルのリストを更新
            }
        }
    
    func getRandomColor() -> UIColor {
        let hue = CGFloat.random(in: 0.0...1.0)
        let saturation: CGFloat = 0.8
        let brightness: CGFloat = 0.8
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
    }
    
    func updateClockHands() {
        hourHand = UIView(frame: CGRect(x: 0, y: 0, width: 7, height: 50))
        hourHand.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        hourHand.center = view.center
        hourHand.layer.anchorPoint = CGPoint(x: 0.5, y: 1)
        view.addSubview(hourHand)
        
        minuteHand = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 70))
        minuteHand.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        minuteHand.center = view.center
        minuteHand.layer.anchorPoint = CGPoint(x: 0.5, y: 1)
        view.addSubview(minuteHand)
        
        secondHand = UIView(frame: CGRect(x: 0, y: 0, width: 3, height: 80))
        secondHand.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        secondHand.center = view.center
        secondHand.layer.anchorPoint = CGPoint(x: 0.5, y: 1)
        view.addSubview(secondHand)
        
        // 時間を取得
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: Date())
        let hour = components.hour!
        let minute = components.minute!
        let second = components.second!
        
        // 針の角度を計算
        let hourAngle = CGFloat.pi * 2 * CGFloat(hour) / 12.0
        let minuteAngle = CGFloat.pi * 2 * CGFloat(minute) / 60.0
        let secondAngle = CGFloat.pi * 2 * CGFloat(second) / 60.0
        
        // 針の回転
        hourHand.transform = CGAffineTransform(rotationAngle: hourAngle)
        minuteHand.transform = CGAffineTransform(rotationAngle: minuteAngle)
        
        // 秒針の回転
        let rotationAngle = CGFloat.pi * 2 * CGFloat(second) / 60.0
        secondHand.transform = CGAffineTransform(rotationAngle: rotationAngle)
        
        // カレンダーの予定を円グラフとして描画
        drawEventSchedule()
        //時計のメモリを描画
        drawClockTicks()
        //時計の数字を描画
        drawClockNumbers()
    }
    
    func drawEventSchedule() {
        let radius: CGFloat = 100.0
        let centerX = view.center.x
        let centerY = view.center.y
        let customGrayColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)

        let grayCirclePath = UIBezierPath(arcCenter: CGPoint(x: centerX, y: centerY), radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        let grayCircleLayer = CAShapeLayer()
        grayCircleLayer.path = grayCirclePath.cgPath
        grayCircleLayer.fillColor = customGrayColor.cgColor
        view.layer.insertSublayer(grayCircleLayer, below: hourHand.layer)

        let eventColors: [UIColor] = [
            UIColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 1.0),
            UIColor(red: 1.0, green: 0.2, blue: 0.7, alpha: 1.0),
            UIColor(red: 0.8, green: 1.0, blue: 0.1, alpha: 1.0),
            UIColor(red: 0.6, green: 0.6, blue: 1.0, alpha: 1.0),
            UIColor(red: 1.0, green: 0.6, blue: 0.6, alpha: 1.0),
            UIColor(red: 0.6, green: 1, blue: 0.6, alpha: 1.0)
        ]

        let calendar = Calendar.current
        let currentDate = Date()
        let twelveHoursLater = Calendar.current.date(byAdding: .hour, value: 12, to: currentDate)!

        var startAngle: CGFloat = -CGFloat.pi / 2.0

        for (index, event) in events.enumerated() {
            if let eventStartDate = event.startDate,
               let eventEndDate = event.endDate,
               currentDate <= eventEndDate,
               twelveHoursLater >= eventStartDate {
                let eventDuration = eventEndDate.timeIntervalSince(eventStartDate)
                let eventPercentage = CGFloat(eventDuration) / (12.0 * 60.0 * 60.0)

                let startHourComponents = calendar.dateComponents([.hour, .minute], from: eventStartDate)
                let h = Double(startHourComponents.hour!) + Double(startHourComponents.minute!) / 60.0

                let startHourAngle = -CGFloat.pi / 2.0 + CGFloat.pi * 2 * CGFloat(h) / 12.0
                let endHourAngle = startHourAngle + 2 * CGFloat.pi * eventPercentage

                let path = UIBezierPath()
                path.move(to: CGPoint(x: centerX, y: centerY))
                path.addArc(withCenter: CGPoint(x: centerX, y: centerY), radius: radius, startAngle: startHourAngle, endAngle: endHourAngle, clockwise: true)
                path.close()

                eventPaths.append(path) // パスを保存

                let shapeLayer = CAShapeLayer()
                shapeLayer.path = path.cgPath
                shapeLayer.fillColor = eventColors[index % eventColors.count].cgColor
                view.layer.insertSublayer(shapeLayer, below: hourHand.layer)

                let label = UILabel(frame: CGRect(x: centerX - radius, y: centerY + radius + 10, width: 2 * radius, height: 20))
                label.text = event.title
                label.textColor = UIColor.white
                label.textAlignment = .center
                view.addSubview(label)

                startAngle = endHourAngle
            }
        }
    }

    
    
    func drawClockTicks() {
        let radius: CGFloat = 120.0
        let centerX = view.center.x
        let centerY = view.center.y
        
        for i in 0..<12 {
            let angle = CGFloat.pi * 2 * CGFloat(i) / 12.0
            let tickStartX = centerX + radius * cos(angle)
            let tickStartY = centerY + radius * sin(angle)
            let tickEndX = centerX + (radius - 10) * cos(angle)
            let tickEndY = centerY + (radius - 10) * sin(angle)
            
            let tickPath = UIBezierPath()
            tickPath.move(to: CGPoint(x: tickStartX, y: tickStartY))
            tickPath.addLine(to: CGPoint(x: tickEndX, y: tickEndY))
            
            let tickLayer = CAShapeLayer()
            tickLayer.path = tickPath.cgPath
            tickLayer.strokeColor = UIColor.black.cgColor
            tickLayer.lineWidth = 3.0
            view.layer.addSublayer(tickLayer)
        }
    }
    
    func drawClockNumbers() {
        let radius: CGFloat = 140.0
        let centerX = view.center.x
        let centerY = view.center.y
        
        for i in 1...12 {
            let angle = CGFloat.pi * 2 * CGFloat(i-3) / 12.0
            let numberLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
            numberLabel.center = CGPoint(x: centerX + radius * cos(angle), y: centerY + radius * sin(angle))
            numberLabel.text = "\(i)"
            numberLabel.textColor = UIColor.black
            
            // フォントを変更する
            if let customFont = UIFont(name: "Optima-ExtraBlack", size: 18) {
                numberLabel.font = customFont
            } else {
                // フォントが見つからない場合の処理
                print("Optima-ExtraBlack フォントが見つかりません")
            }
            
            numberLabel.textAlignment = .center
            view.addSubview(numberLabel)
        }
    }
    
    func showAccessDeniedAlert() {
        let alert = UIAlertController(title: "アクセス許可が必要", message: "カレンダーアクセスが許可されていません。設定からアクセスを許可してください。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "設定を開く", style: .default, handler: { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }))
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        present(alert, animated: true)
    }
    
    func updateEventTitleList() {
        // テーブルビューの初期化
        if tableView == nil {
            tableView = UITableView(frame: CGRect(x: 0, y: view.bounds.height - 150, width: view.bounds.width, height: 150))
            tableView.delegate = self
            tableView.dataSource = self
            view.addSubview(tableView)
        } else {
            tableView.reloadData()
        }
    }
}

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
}

extension UIColor {
    static var random: UIColor {
        return UIColor(red: .random(in: 0...1),
                       green: .random(in: 0...1),
                       blue: .random(in: 0...1),
                       alpha: 1.0)
    }
}

// テーブルビューのデータソースとデリゲートを拡張
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventTitles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell") ?? UITableViewCell(style: .default, reuseIdentifier: "EventCell")
        cell.textLabel?.text = eventTitles[indexPath.row]
        
        let squareView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        squareView.backgroundColor = eventColors[indexPath.row % eventColors.count]
        cell.accessoryView = squareView
        
        return cell
    }
}

