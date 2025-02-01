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
    assertEquals(orgData['total-achievements'], types.uint(0));
  },
});

Clarinet.test({
  name: "Sustainability goals test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('eco-tracker', 'register-organization', [
        types.ascii("Test Org")
      ], wallet1.address),
      
      Tx.contractCall('eco-tracker', 'set-sustainability-goals', [
        types.uint(1000), // energy target
        types.uint(500),  // waste target
        types.uint(100)   // points threshold
      ], wallet1.address)
    ]);
    
    block.receipts.forEach(receipt => {
      receipt.result.expectOk();
    });
    
    // Verify goals
    let goalsBlock = chain.mineBlock([
      Tx.contractCall('eco-tracker', 'get-sustainability-goals', [
        types.principal(wallet1.address)
      ], wallet1.address)
    ]);
    
    const goals = goalsBlock.receipts[0].result.expectOk().expectTuple();
    assertEquals(goals['energy-target'], types.uint(1000));
    assertEquals(goals['waste-target'], types.uint(500));
    assertEquals(goals['active'], true);
  },
});

Clarinet.test({
  name: "Achievement tracking test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('eco-tracker', 'register-organization', [
        types.ascii("Test Org")
      ], wallet1.address),
      
      Tx.contractCall('eco-tracker', 'set-sustainability-goals', [
        types.uint(1000),
        types.uint(500),
        types.uint(100)
      ], wallet1.address),
      
      // Record metrics meeting goals
      Tx.contractCall('eco-tracker', 'record-monthly-metrics', [
        types.uint(2023),
        types.uint(6),
        types.uint(900), // below energy target
        types.uint(400)  // below waste target
      ], wallet1.address)
    ]);
    
    block.receipts.forEach(receipt => {
      receipt.result.expectOk();
    });
    
    // Check achievements
    let achievementBlock = chain.mineBlock([
      Tx.contractCall('eco-tracker', 'get-achievements', [
        types.principal(wallet1.address)
      ], wallet1.address)
    ]);
    
    const achievements = achievementBlock.receipts[0].result.expectOk().expectTuple();
    assertEquals((achievements['milestones'] as any).length, 1);
    assertEquals((achievements['points-earned'] as any)[0], types.uint(50));
  },
});
