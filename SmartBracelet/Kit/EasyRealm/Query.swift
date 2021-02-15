//
//  ER_Query.swift
//  Pods
//
//  Created by Allan Vialatte on 05/03/2017.
//
//

import Foundation
import RealmSwift

public extension EasyRealmStatic where T:Object {
    func fromRealm<K>(with primaryKey:K) throws -> T {
        let realm = try Realm()
        if let object = realm.object(ofType: self.baseType, forPrimaryKey: primaryKey) {
            return object
        } else {
            throw EasyRealmError.ObjectWithPrimaryKeyNotFound
        }
    }
  
    func all() throws -> Results<T> {
        let realm = try Realm()
        return realm.objects(self.baseType)
    }
    
    func array(_ pre: String) throws -> Results<T> {
        let realm = try Realm()
        return realm.objects(self.baseType).filter(pre)
    }
}
