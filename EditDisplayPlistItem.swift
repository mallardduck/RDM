//
//  EditDisplayPlistItem.swift
//  RDM-2
//
//  Created by гык-sse2 on 21/08/2018.
//  Copyright © 2018 гык-sse2. All rights reserved.
//

import Cocoa

@objc class EditDisplayPlistItem : NSMenuItem {
	@objc var vendorID : UInt32
	@objc var productID : UInt32
	@objc var displayName : String
	
	@objc init(title : String, action : Selector, vendorID : UInt32, productID : UInt32, displayName : String) {
		self.vendorID = vendorID
		self.productID = productID
		self.displayName = displayName
		super.init(title: title, action: action, keyEquivalent: "")
	}
	
	required init(coder decoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
