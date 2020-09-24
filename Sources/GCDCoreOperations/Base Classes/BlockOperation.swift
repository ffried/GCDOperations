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
