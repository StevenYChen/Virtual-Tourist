//
//  GDCBlackBox.swift
//  Virtual Tourist
//
//  Created by Steven Chen on 5/25/16.
//  Copyright © 2016 Steven Chen. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(updates: () -> Void) {
    dispatch_async(dispatch_get_main_queue()) {
        updates()
    }
}