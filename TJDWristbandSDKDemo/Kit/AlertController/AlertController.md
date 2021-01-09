#  AlertController用法介绍

@IBAction func showAlert(sender: UIButton) {
  
  let alert = EMAlertController(icon: UIImage(named: "icon"), title: "EMAlertView Title", message: "This is a simple message for the EMAlertView")
  
  let action1 = EMAlertAction(title: "CANCEL", style: .cancel)
  let action2 = EMAlertAction(title: "CONFIRM", style: .normal) {
    // Perform action
    guard let text = alert.firstTextField?.text,
    let password = alert.textFields[1].text else {return}
    print(text)
    print(password)
  }
  
  alert.addAction(action1)
  alert.addAction(action2)
  
  present(alert, animated: true, completion: nil)
}

