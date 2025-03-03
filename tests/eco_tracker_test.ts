Clarinet.test({
  name: "Security and validation tests",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Test unauthorized achievement award
    let block = chain.mineBlock([
      Tx.contractCall('eco-tracker', 'award-achievement', [
        types.principal(wallet1.address),
        types.ascii("Unauthorized Achievement"),
        types.uint(100)
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectErr().expectUint(100); // err-owner-only
    
    // Test points validation
    block = chain.mineBlock([
      Tx.contractCall('eco-tracker', 'award-achievement', [
        types.principal(wallet1.address),
        types.ascii("Too Many Points"),
        types.uint(1001)
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectErr().expectUint(106); // err-invalid-points
    
    // Test invalid date validation
    block = chain.mineBlock([
      Tx.contractCall('eco-tracker', 'record-monthly-metrics', [
        types.uint(2023),
        types.uint(13),
        types.uint(1000),
        types.uint(500)
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectErr().expectUint(104); // err-invalid-date
  },
});
