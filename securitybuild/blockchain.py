from pycoin.block import Block
from pycoin.serialize import b2h_rev, h2b

class Blockchain:
    def __init__(self):
        self.chain = []
        self.pending_transactions = []

    def create_genesis_block(self):
        genesis_block = Block(version=1, previous_block=b'\x00' * 32, timestamp=0, difficulty=0, nonce=0)
        self.chain.append(genesis_block)

    def add_block(self, block):
        prev_block = self.chain[-1]
        if prev_block.hash() != block.previous_block_hash:
            raise Exception('Invalid block')
        self.chain.append(block)

    def validate_block(self, block):
        prev_block = self.chain[-1]
        if prev_block.hash() != block.previous_block_hash:
            raise Exception('Invalid block')

    def add_transaction(self, transaction):
        self.pending_transactions.append(transaction)

    def mine_block(self):
        prev_block = self.chain[-1]
        block = Block(version=1, previous_block=prev_block.hash(), transactions=self.pending_transactions)
        block.solve()
        self.chain.append(block)
        self.pending_transactions = []
