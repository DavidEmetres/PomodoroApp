//
//  ViewController.swift
//  PomodoroApp
//
//  Created by David Martinez on 11/13/24.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UICollectionViewDataSource
{
    @IBOutlet var _startPauseButton:UIButton!
    @IBOutlet var _timeSelector:UIButton!
    @IBOutlet var _pomodoroContainer:UICollectionView!
    
    var _timer:Timer?
    var _timeInterval:TimeInterval?
    var _endTimeEpoch:Date?
    var _audioPlayer:AVAudioPlayer?
    var _pomodoroCount:Int? = 0
    var _selectedTimeInterval:TimeInterval?
    
    let _focusInterval:TimeInterval? = 25 * 60
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        createAudioplayer()
        requestNotificationPremission()
        
        timeIntervalChanged(sender:_timeSelector.menu!.children[0])
        
        setButtonText(newTitle:"Start")
        
        _pomodoroContainer.dataSource = self
    }
    
    @IBAction func startPauseButtonPressed(sender:UIButton)
    {
        if _timer != nil && _timer!.isValid
        {
            pauseTimer()
        }
        else
        {
            startTimer()
        }
    }
    
    @IBAction func timeIntervalChanged(sender:UIMenuElement)
    {
        _timeInterval = convertTimeTextToMinutes(text:sender.title)
        _selectedTimeInterval = _timeInterval
        _timeSelector.setTitle(sender.title, for:.normal)
        
        if _timeInterval == _focusInterval
        {
            _timeSelector.setTitleColor(UIColor.red, for:.normal)
            _startPauseButton.tintColor = UIColor.red
        }
        else
        {
            _timeSelector.setTitleColor(UIColor.systemBlue, for:.normal)
            _startPauseButton.tintColor = UIColor.systemBlue
        }
        
        setButtonText(newTitle:"Start")
    }
    
    func setButtonText(newTitle:String)
    {
        let currentFont = _startPauseButton.titleLabel?.font

        let attributes: [NSAttributedString.Key: Any] = [
            .font: currentFont!
        ]
        let attributedTitle = NSAttributedString(string:newTitle, attributes:attributes)
        _startPauseButton.setAttributedTitle(attributedTitle, for:.normal)
    }
    
    func convertTimeTextToMinutes(text:String) -> TimeInterval
    {
        let timeComponents = text.split(separator:":")
        if let minutes = Int(timeComponents[0]), let seconds = Int(timeComponents[1])
        {
            let totalSeconds = (minutes * 60) + seconds
            return TimeInterval(totalSeconds)
        }
        
        return 0
    }
    
    func createAudioplayer()
    {
        if let soundURL = Bundle.main.url(forResource:"ringtone-vfx", withExtension:"mp3")
        {
            do
            {
                _audioPlayer = try AVAudioPlayer(contentsOf:soundURL)
            }
            catch
            {
                print("Error: Unable to play sound - \(error.localizedDescription)")
            }
        }
    }
    
    func requestNotificationPremission()
    {
        UNUserNotificationCenter.current().requestAuthorization(options:[.alert, .sound]) { granted, error in
            if granted
            {
                print("Notification permissions granted!")
            }
            else
            {
                print("Notification permissions denied!")
            }
        }
    }
    
    func startTimer()
    {
        _timer = Timer.scheduledTimer(timeInterval:0.1, target:self, selector:#selector(timerUpdated), userInfo:nil, repeats:true)
        
        _endTimeEpoch = Date(timeIntervalSinceNow:_timeInterval!)
        
        scheduleNotification()
        
        setButtonText(newTitle:"Pause")
    }
    
    func pauseTimer()
    {
        _timer?.invalidate()
        
        _timeInterval = _endTimeEpoch?.timeIntervalSince(Date.now)
        
        unscheduleNotifications()
        
        setButtonText(newTitle:"Continue")
    }
    
    @objc func timerUpdated()
    {
        let remainingTime = _endTimeEpoch?.timeIntervalSince(Date.now)
        if remainingTime! > 0
        {
            _timeSelector.setTitle(formatTime(timeInterval:remainingTime!), for:.normal)
        }
        else
        {
            _timeSelector.setTitle(formatTime(timeInterval:0), for:.normal)
            
            _timer?.invalidate()
            _timer = nil
            
            alert()
        }
    }
    
    func formatTime(timeInterval:TimeInterval) -> String
    {
        let minutes = Int(ceil(timeInterval)) / 60
        let seconds = Int(ceil(timeInterval)) % 60
        return String(format:"%02d:%02d", minutes, seconds)
    }
    
    func alert()
    {
        let alert = UIAlertController(title:"Pomodoro timer", message:"Time's up!", preferredStyle:.alert)
        alert.addAction(UIAlertAction(title:"OK", style:.default, handler:removeAlert))
        present(alert, animated:true, completion:nil)
        
        _audioPlayer?.play()
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    func removeAlert(sender:UIAlertAction)
    {
        if _selectedTimeInterval == _focusInterval
        {
            _pomodoroCount! += 1
            _pomodoroContainer.reloadData()
            
            timeIntervalChanged(sender:_timeSelector.menu!.children[2])
        }
        else
        {
            timeIntervalChanged(sender:_timeSelector.menu!.children[0])
        }
    }
    
    func scheduleNotification()
    {
        let content = UNMutableNotificationContent()
        content.title = "Pomodoro timer"
        content.body = "Time's up!"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval:_timeInterval!, repeats:false)
        let request = UNNotificationRequest(identifier:"pomodoro", content:content, trigger:trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error
            {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func unscheduleNotifications()
    {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _pomodoroCount!
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let pomodoro = _pomodoroContainer.dequeueReusableCell(withReuseIdentifier:"Pomodoro", for:indexPath)
        return pomodoro
    }
}

