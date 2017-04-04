//
//  BlockOperation.swift
//  GCDOperations
//
//  Created by Florian Friedrich on 02.04.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

public final class BlockOperation: Operation {
    public typealias Block = (_ finish: @escaping ([Error]) -> ()) -> ()

    public let block: Block

    public init(block: @escaping Block) {
        self.block = block
    }
    
    public override func execute() {
        block(finish)
    }
}
