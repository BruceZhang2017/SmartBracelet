import UIKit
import Contacts

class ContactManager {
    // 单例实例，方便全局调用
    static let shared = ContactManager()
    private init() {}
    
    // 检查当前通讯录权限状态
    private func checkPermissionStatus() -> CNAuthorizationStatus {
        return CNContactStore.authorizationStatus(for: .contacts)
    }
    
    // 请求通讯录授权并获取联系人
    func requestContactsAccess(completion: @escaping ([CNContact]?, Error?) -> Void) {
        let status = checkPermissionStatus()
        
        switch status {
        case .authorized:
            // 已授权，直接获取联系人
            //fetchContacts(completion: completion)
            print("已授权")
        case .notDetermined:
            // 未请求过授权，发起请求
            let store = CNContactStore()
            store.requestAccess(for: .contacts) { [weak self] granted, error in
                DispatchQueue.main.async {
                    if granted {
                        //self?.fetchContacts(completion: completion)
                    } else {
                        completion(nil, error ?? NSError(domain: "ContactAccess", code: -1, userInfo: [NSLocalizedDescriptionKey: "用户拒绝授权"]))
                    }
                }
            }
            
        case .denied, .restricted:
            // 已拒绝或受限制，提示用户去设置开启
            completion(nil, NSError(domain: "ContactAccess", code: -2, userInfo: [NSLocalizedDescriptionKey: "权限已被拒绝，请在设置中开启"]))
            
        @unknown default:
            completion(nil, NSError(domain: "ContactAccess", code: -3, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
        }
    }
    
    // 实际获取联系人数据
    private func fetchContacts(completion: @escaping ([CNContact]?, Error?) -> Void) {
        let store = CNContactStore()
        // 需要获取的联系人字段（按需添加，越多性能消耗越大）
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,   // 名
            CNContactFamilyNameKey as CNKeyDescriptor,  // 姓
            CNContactPhoneNumbersKey as CNKeyDescriptor, // 电话号码
            CNContactEmailAddressesKey as CNKeyDescriptor, // 邮箱
            CNContactThumbnailImageDataKey as CNKeyDescriptor // 头像缩略图
        ]
        
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
        var contacts: [CNContact] = []
        
        do {
            // 遍历所有联系人
            try store.enumerateContacts(with: fetchRequest) { contact, stop in
                contacts.append(contact)
                // 如果需要限制数量，可在这里判断并停止遍历
                // if contacts.count >= 100 { stop.pointee = true }
            }
            completion(contacts, nil)
        } catch {
            completion(nil, error)
        }
    }
    
    // 显示权限引导弹窗（当用户拒绝授权时调用）
    func showPermissionAlert(in vc: UIViewController) {
        let alert = UIAlertController(
            title: "需要通讯录权限",
            message: "请在设置中开启通讯录权限，否则无法获取联系人",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "去设置", style: .default) { _ in
            // 跳转到当前App的设置页面
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        })
        vc.present(alert, animated: true)
    }
}
