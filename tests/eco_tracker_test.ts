import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Organization registration test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('eco-tracker', 'register-organization', [
        types.ascii("Test Org")
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Verify organization data
    let checkBlock = chain.mineBlock([
      Tx.contractCall('eco-tracker', 'get-organization-data', [
        types.principal(wallet1.address)
      ], wallet1.address)
    ]);
    
    const orgData = checkBlock.receipts[0].result.expectOk().expectTuple();
    assertEquals(orgData['name'], "Test Org");
    assertEquals(orgData['eco-points'], types.uint(0));
  },
});

Clarinet.test({
  name: "Monthly metrics recording test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    // First register organization
    let block = chain.mineBlock([
      Tx.contractCall('eco-tracker', 'register-organization', [
        types.ascii("Test Org")
      ], wallet1.address),
      
      // Record metrics
      Tx.contractCall('eco-tracker', 'record-monthly-metrics', [
        types.uint(2023),
        types.uint(6),
        types.uint(1000), // energy
        types.uint(500)   // waste
      ], wallet1.address)
    ]);
    
    block.receipts.forEach(receipt => {
      receipt.result.expectOk().expectBool(true);
    });
    
    // Verify metrics
    let metricsBlock = chain.mineBlock([
      Tx.contractCall('eco-tracker', 'get-monthly-metrics', [
        types.principal(wallet1.address),
        types.uint(2023),
        types.uint(6)
      ], wallet1.address)
    ]);
    
    const metrics = metricsBlock.receipts[0].result.expectOk().expectTuple();
    assertEquals(metrics['energy-usage'], types.uint(1000));
    assertEquals(metrics['waste-produced'], types.uint(500));
  },
});

Clarinet.test({
  name: "Eco points awarding test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('eco-tracker', 'register-organization', [
        types.ascii("Test Org")
      ], wallet1.address),
      
      // Award points as contract owner
      Tx.contractCall('eco-tracker', 'award-eco-points', [
        types.principal(wallet1.address),
        types.uint(100)
      ], deployer.address),
      
      // Try awarding points as non-owner (should fail)
      Tx.contractCall('eco-tracker', 'award-eco-points', [
        types.principal(wallet1.address),
        types.uint(50)
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
    block.receipts[1].result.expectOk().expectBool(true);
    block.receipts[2].result.expectErr(types.uint(100)); // err-owner-only
    
    // Verify points
    let pointsBlock = chain.mineBlock([
      Tx.contractCall('eco-tracker', 'get-organization-data', [
        types.principal(wallet1.address)
      ], wallet1.address)
    ]);
    
    const orgData = pointsBlock.receipts[0].result.expectOk().expectTuple();
    assertEquals(orgData['eco-points'], types.uint(100));
  },
});