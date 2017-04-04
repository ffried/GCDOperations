//
//  BlockOperation.swift
//  GCDOperations
//
//  Created by Florian Friedrich on 02.04.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

public final class BlockOperation: Operation {
    public let block: () -> ()
    public init(block: @escaping () -> ()) {
        self.block = block
    }
    
    public override func execute() {
        block()
        finish()
    }
}
