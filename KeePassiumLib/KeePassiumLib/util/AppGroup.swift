//  KeePassium Password Manager
//  Copyright © 2018–2024 KeePassium Labs <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import Foundation

public class AppGroup {
    public static var id: String = {
        (Bundle.main.infoDictionary?["App Group Identifier"] as? String)!
    }()

    public static let appURLScheme: String = {
        (Bundle.main.infoDictionary?["App URL Scheme"] as? String)!
    }()

    public static let upgradeToPremiumURL = URL(string: appURLScheme + "://upgradeToPremium")! 

    public static let donateURL = URL(string: appURLScheme + "://donate")! 

    public static var isMainApp: Bool {
        return applicationShared != nil
    }

    public static var isAppExtension: Bool {
        return !isMainApp
    }

    public static weak var applicationShared: UIApplication?
}
