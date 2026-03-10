//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  APNSViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2020/10/8.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import WatchProtocolSDK

class APNSViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "device_push_settings".localized()
    }

    @objc private func valueChanged(_ sender: Any) {
        let mSwitch = sender as? UISwitch
        let tag = mSwitch?.tag ?? 0
        if tag == 0 {
            if isXGZT {
                XGZTBlueToothManager.shared.device?.isWechat = mSwitch?.isOn ?? false
            } else {
                bleSelf.notifyModel.isWechat = mSwitch?.isOn ?? false
            }
        } else if tag == 1 {
            if isXGZT {
                XGZTBlueToothManager.shared.device?.isQQ = mSwitch?.isOn ?? false
            } else {
                bleSelf.notifyModel.isQQ = mSwitch?.isOn ?? false
            }
        } else if tag == 2 {
            if isXGZT {
                XGZTBlueToothManager.shared.device?.isLinkedIn = mSwitch?.isOn ?? false
            } else {
                bleSelf.notifyModel.isLinkedin = mSwitch?.isOn ?? false
            }
        } else if tag == 3 {
            if isXGZT {
                XGZTBlueToothManager.shared.device?.isFacebook = mSwitch?.isOn ?? false
            } else {
                bleSelf.notifyModel.isFacebook = mSwitch?.isOn ?? false
            }
        } else if tag == 4 {
            if isXGZT {
                XGZTBlueToothManager.shared.device?.isTwitter = mSwitch?.isOn ?? false
            } else {
                bleSelf.notifyModel.isTwitter = mSwitch?.isOn ?? false
            }
        } else if tag == 10 {
            if isXGZT {
                XGZTBlueToothManager.shared.device?.isWhatsapp = mSwitch?.isOn ?? false
            } else {
                bleSelf.notifyModel.isWhatapp = mSwitch?.isOn ?? false
            }
        } else if tag == 11 {
            if isXGZT {
                XGZTBlueToothManager.shared.device?.isLine = mSwitch?.isOn ?? false
            } else {
                bleSelf.notifyModel.isLine = mSwitch?.isOn ?? false
            }
        } else if tag == 12 {
            if isXGZT {
                XGZTBlueToothManager.shared.device?.isKakaotalk = mSwitch?.isOn ?? false
            } else {
                bleSelf.notifyModel.isKakaoTalk = mSwitch?.isOn ?? false
            }
        } else if tag == 13 {
            if isXGZT {
                XGZTBlueToothManager.shared.device?.isFacebookMessenger = mSwitch?.isOn ?? false
            } else {
                bleSelf.notifyModel.isFacebookMessage = mSwitch?.isOn ?? false
            }
        } else if tag == 14 {
            if isXGZT {
                XGZTBlueToothManager.shared.device?.isInstagram = mSwitch?.isOn ?? false
            } else {
                bleSelf.notifyModel.isInstagram = mSwitch?.isOn ?? false
            }
        }
        if isXGZT {
            guard let device = XGZTBlueToothManager.shared.device else {
                return
            }
            var p0: UInt8 = 0
            var p1: UInt8 = 0
            var p2: UInt8 = 0
            var p3: UInt8 = 0
            p0 |= device.isNullMessage ? 1 << 0 : 0
            p0 |= device.isIncomingCall ? 1 << 1 : 0
            p0 |= device.isMissedCall ? 1 << 2 : 0
            p0 |= device.isMessages ? 1 << 3 : 0
            p0 |= device.isEmail ? 1 << 4 : 0
            p0 |= device.isSchedule ? 1 << 5 : 0
            p0 |= device.isFacetime ? 1 << 6 : 0
            p0 |= device.isQQ ? 1 << 7 : 0

            // 处理 response[8]
            p1 |= device.isSkype ? 1 << 0 : 0
            p1 |= device.isWechat ? 1 << 1 : 0
            p1 |= device.isWhatsapp ? 1 << 2 : 0
            p1 |= device.isGmail ? 1 << 3 : 0
            p1 |= device.isHangout ? 1 << 4 : 0
            p1 |= device.isInbox ? 1 << 5 : 0
            p1 |= device.isLine ? 1 << 6 : 0
            p1 |= device.isTwitter ? 1 << 7 : 0
            
            // 处理 response[9]
            p2 |= device.isFacebook ? 1 << 0 : 0
            p2 |= device.isFacebookMessenger ? 1 << 1 : 0
            p2 |= device.isInstagram ? 1 << 2 : 0
            p2 |= device.isWeibo ? 1 << 3 : 0
            p2 |= device.isKakaotalk ? 1 << 4 : 0
            p2 |= device.isFacebookpagemanager ? 1 << 5 : 0
            p2 |= device.isViber ? 1 << 6 : 0
            p2 |= device.isVkclient ? 1 << 7 : 0
            
            // 处理 response[9]
            p3 |= device.isTelegram ? 1 << 0 : 0
            p3 |= device.isSnapchat ? 1 << 2 : 0
            p3 |= device.isDingTalk ? 1 << 3 : 0
            p3 |= device.isAlipay ? 1 << 4 : 0
            p3 |= device.isTiktok ? 1 << 5 : 0
            p3 |= device.isLinkedIn ? 1 << 6 : 0
            
            XGZTCommand.setSwitchTableExtension(p0: p0, p1: p1, p2: p2, p3: p3)
        } else {
            bleSelf.setAncsSwitchForWristband(bleSelf.notifyModel)
        }
    }
}

extension APNSViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath) as! DeviceSettingsTableViewCell
        cell.selectionStyle = .none
        cell.textLabel?.text = titles[indexPath.section][indexPath.row]
        var mSwitch: UISwitch
        if let s = cell.accessoryView as? UISwitch {
            mSwitch = s
        } else {
            mSwitch = UISwitch()
            mSwitch.isOn = true 
            cell.accessoryView = mSwitch
        }
        mSwitch.tag = indexPath.section * 10 + indexPath.row
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                if isXGZT {
                    mSwitch.isOn = XGZTBlueToothManager.shared.device?.isWechat ?? false 
                } else {
                    mSwitch.isOn = bleSelf.notifyModel.isWechat
                }
                
            } else if indexPath.row == 1 {
                if isXGZT {
                    mSwitch.isOn = XGZTBlueToothManager.shared.device?.isQQ ?? false
                } else {
                    mSwitch.isOn = bleSelf.notifyModel.isQQ
                }
            } else if indexPath.row == 2 {
                if isXGZT {
                    mSwitch.isOn = XGZTBlueToothManager.shared.device?.isLinkedIn ?? false
                } else {
                    mSwitch.isOn = bleSelf.notifyModel.isLinkedin
                }
            } else if indexPath.row == 3 {
                if isXGZT {
                    mSwitch.isOn = XGZTBlueToothManager.shared.device?.isFacebook ?? false
                } else {
                    mSwitch.isOn = bleSelf.notifyModel.isFacebook
                }
            } else {
                if isXGZT {
                    mSwitch.isOn = XGZTBlueToothManager.shared.device?.isTwitter ?? false
                } else {
                    mSwitch.isOn = bleSelf.notifyModel.isTwitter
                }
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                if isXGZT {
                    mSwitch.isOn = XGZTBlueToothManager.shared.device?.isWhatsapp ?? false
                } else {
                    mSwitch.isOn = bleSelf.notifyModel.isWhatapp
                }
            } else if indexPath.row == 1 {
                if isXGZT {
                    mSwitch.isOn = XGZTBlueToothManager.shared.device?.isLine ?? false
                } else {
                    mSwitch.isOn = bleSelf.notifyModel.isLine
                }
            } else if indexPath.row == 2 {
                if isXGZT {
                    mSwitch.isOn = XGZTBlueToothManager.shared.device?.isKakaotalk ?? false
                } else {
                    mSwitch.isOn = bleSelf.notifyModel.isKakaoTalk
                }
            } else if indexPath.row == 3 {
                if isXGZT {
                    mSwitch.isOn = XGZTBlueToothManager.shared.device?.isFacebookMessenger ?? false
                } else {
                    mSwitch.isOn = bleSelf.notifyModel.isFacebookMessage
                }
            } else if indexPath.row == 4 {
                if isXGZT {
                    mSwitch.isOn = XGZTBlueToothManager.shared.device?.isInstagram ?? false
                } else {
                    mSwitch.isOn = bleSelf.notifyModel.isInstagram
                }
            }
        }
        mSwitch.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15
    }
}

extension APNSViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
}

extension APNSViewController {
    var titles: [[String]] {
        return [["device_push_settings_wechat".localized(), "QQ", "LIKEDIN", "FACEBOOK", "TIWTTER"], ["WHATSAPP", "Line", "KakaoTalk", "Facebook Message", "Instagram"]]
    }
}
