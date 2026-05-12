/**
 * Comprehensive budget test-data seed for habiba1278@gmail.com
 * Run: node backend/scripts/seed-budget-test-data.js
 *
 * Seeds everything needed to test ALL budget features:
 *   - Conversion rate
 *   - Active PeriodBudget with emergency fund
 *   - BudgetAllocations per inventory category
 *   - MemberAllowances (auto-deposits to MemberWallet)
 *   - MemberWallets for all children
 *   - Shared expenses (linked to period budget + allocation)
 *   - Personal expenses (linked to allowance, deducted from wallet)
 *   - Expense requests: 1 pending, 1 approved, 1 rejected
 *   - Two past inactive period budgets with expenses
 *   - Future events with contributions
 */

const mongoose = require('mongoose');
const dotenv   = require('dotenv');
const path     = require('path');

dotenv.config({ path: path.join(__dirname, '../.env') });

const FamilyAccount    = require('../models/FamilyAccountModel');
const MemberType       = require('../models/MemberTypeModel');
const Member           = require('../models/MemberModel');
const PeriodBudget     = require('../models/periodBudgetModel');
const BudgetAllocation = require('../models/budgetAllocationModel');
const MemberAllowance  = require('../models/memberAllowanceModel');
const MemberWallet     = require('../models/memberWalletModel');
const Expense          = require('../models/ExpenseModel');
const FutureEvent      = require('../models/futureEventModel');
const InventoryCategory = require('../models/inventoryCategoryModel');
const ConversionRate   = require('../models/conversionRateModel');
const BalanceWalletDetail = require('../models/balanceWalletDetailModel');

const FAMILY_EMAIL = 'habiba1278@gmail.com';

const daysAgo     = (n) => { const d = new Date(); d.setDate(d.getDate() - n); return d; };
const daysFromNow = (n) => { const d = new Date(); d.setDate(d.getDate() + n); return d; };
const monthsAgo   = (m, day = 1) => {
  const d = new Date();
  d.setMonth(d.getMonth() - m);
  d.setDate(day);
  return d;
};

const log = (msg) => console.log(msg);

async function clean(family) {
  log('\n[Clean] Removing old budget test data for this family...');
  await PeriodBudget.deleteMany({ family_id: family._id });
  await BudgetAllocation.deleteMany({ family_id: family._id });
  await MemberAllowance.deleteMany({ family_id: family._id });
  await MemberWallet.deleteMany({ family_id: family._id });
  await Expense.deleteMany({ family_id: family._id });
  await ConversionRate.deleteMany({ family_id: family._id });
  await BalanceWalletDetail.deleteMany({ family_id: family._id });
  log('  Done.');
}

async function seedData() {
  const dbStr = process.env.DB.replace('<db_password>', process.env.DB_PASSWORD);
  await mongoose.connect(dbStr);
  log('Connected to DB');

  // ── Family ────────────────────────────────────────────────────────────────
  const family = await FamilyAccount.findOne({ mail: FAMILY_EMAIL });
  if (!family) { console.error(`Family not found for ${FAMILY_EMAIL}`); process.exit(1); }
  log(`\nFamily: "${family.Title}"  id=${family._id}`);

  // ── Members ───────────────────────────────────────────────────────────────
  const parentType = await MemberType.findOne({ type: 'Parent', family_id: family._id });
  const childType  = await MemberType.findOne({ type: 'Child',  family_id: family._id });

  const habiba = await Member.findOne({ mail: FAMILY_EMAIL, family_id: family._id });
  const ahmed  = await Member.findOne({ mail: 'ahmed.family@gmail.com', family_id: family._id });
  const ziad   = await Member.findOne({ mail: 'ziad.family@gmail.com',  family_id: family._id });
  const noor   = await Member.findOne({ mail: 'noor.family@gmail.com',  family_id: family._id });

  if (!habiba || !ahmed || !ziad || !noor) {
    console.error('Members not found. Run seed-ai-test-data.js first.');
    process.exit(1);
  }
  log(`Members: ${habiba.username}, ${ahmed.username}, ${ziad.username}, ${noor.username}`);

  await clean(family);

  // ── Inventory Categories (reuse existing or create) ────────────────────────
  log('\n=== Inventory Categories ===');
  const ensureCat = async (title) => {
    let cat = await InventoryCategory.findOne({ title });
    if (!cat) cat = await InventoryCategory.create({ title });
    log(`  • ${title}`);
    return cat;
  };
  const catGroceries     = await ensureCat('Groceries');
  const catUtilities     = await ensureCat('Utilities');
  const catEducation     = await ensureCat('Education');
  const catEntertainment = await ensureCat('Entertainment');
  const catTransport     = await ensureCat('Transport');
  const catHealthcare    = await ensureCat('Healthcare');

  // ── Conversion Rate ───────────────────────────────────────────────────────
  log('\n=== Conversion Rate ===');
  const convRate = await ConversionRate.create({
    family_id: family._id,
    money_to_points_rate: 10,
    points_to_money_rate: 0.05,
    is_active: true,
    created_by: habiba._id,
  });
  log(`  10 EGP = 100 pts  |  100 pts = 5 EGP`);

  // ══════════════════════════════════════════════════════════════════════════
  // PAST BUDGETS (inactive — for history / analytics)
  // ══════════════════════════════════════════════════════════════════════════
  log('\n=== Past Period Budgets ===');

  const marchBudget = await PeriodBudget.create({
    family_id: family._id,
    title: 'March 2026 Budget',
    period_type: 'monthly',
    start_date: new Date(2026, 2, 1),
    end_date:   new Date(2026, 2, 31),
    total_amount: 5000,
    spent_amount: 4620,
    emergency_fund_percentage: 10,
    emergency_fund_spent: 0,
    is_active: false,
    created_by: habiba._id,
  });
  log(`  + March 2026 Budget (spent 4620 / 5000)`);

  const aprilBudget = await PeriodBudget.create({
    family_id: family._id,
    title: 'April 2026 Budget',
    period_type: 'monthly',
    start_date: new Date(2026, 3, 1),
    end_date:   new Date(2026, 3, 30),
    total_amount: 5000,
    spent_amount: 5380,
    emergency_fund_percentage: 10,
    emergency_fund_spent: 200,
    is_active: false,
    created_by: habiba._id,
  });
  log(`  + April 2026 Budget (OVERSPENT 5380 / 5000, emergency used 200)`);

  // Past expenses for March
  const marchExpenses = [
    { title: 'Supermarket Week 1',      amount:  820, category: 'Groceries',     budget_id: marchBudget._id, budget_category_id: catGroceries._id,     expense_date: new Date(2026, 2,  4) },
    { title: 'Supermarket Week 2',      amount:  780, category: 'Groceries',     budget_id: marchBudget._id, budget_category_id: catGroceries._id,     expense_date: new Date(2026, 2, 12) },
    { title: 'Supermarket Week 3',      amount:  600, category: 'Groceries',     budget_id: marchBudget._id, budget_category_id: catGroceries._id,     expense_date: new Date(2026, 2, 21) },
    { title: 'Electricity Bill',        amount:  480, category: 'Utilities',     budget_id: marchBudget._id, budget_category_id: catUtilities._id,     expense_date: new Date(2026, 2, 10) },
    { title: 'Internet + Water',        amount:  370, category: 'Utilities',     budget_id: marchBudget._id, budget_category_id: catUtilities._id,     expense_date: new Date(2026, 2, 14) },
    { title: 'School Books',            amount:  250, category: 'Education',     budget_id: marchBudget._id, budget_category_id: catEducation._id,     expense_date: new Date(2026, 2,  8) },
    { title: 'Cinema Night',            amount:  220, category: 'Entertainment', budget_id: marchBudget._id, budget_category_id: catEntertainment._id, expense_date: new Date(2026, 2, 22) },
    { title: 'Transport March',         amount:  300, category: 'Transport',     budget_id: marchBudget._id, budget_category_id: catTransport._id,     expense_date: new Date(2026, 2, 28) },
    { title: 'Restaurant Dinner',       amount:  400, category: 'Entertainment', budget_id: marchBudget._id, budget_category_id: catEntertainment._id, expense_date: new Date(2026, 2, 15) },
    { title: 'Doctor Visit',            amount:  400, category: 'Healthcare',    budget_id: marchBudget._id, budget_category_id: catHealthcare._id,    expense_date: new Date(2026, 2, 19) },
  ];
  for (const ex of marchExpenses) {
    await Expense.create({ ...ex, family_id: family._id, member_id: habiba._id, member_mail: FAMILY_EMAIL, expense_source: 'budget', expense_scope: 'shared', is_finalized: true, finalized_at: ex.expense_date });
  }
  log(`  + ${marchExpenses.length} March expenses`);

  // Past expenses for April
  const aprilExpenses = [
    { title: 'Supermarket Week 1',      amount:  900, category: 'Groceries',     budget_id: aprilBudget._id, budget_category_id: catGroceries._id,     expense_date: new Date(2026, 3,  3) },
    { title: 'Supermarket Week 2',      amount:  850, category: 'Groceries',     budget_id: aprilBudget._id, budget_category_id: catGroceries._id,     expense_date: new Date(2026, 3, 11) },
    { title: 'Supermarket Week 3',      amount:  700, category: 'Groceries',     budget_id: aprilBudget._id, budget_category_id: catGroceries._id,     expense_date: new Date(2026, 3, 21) },
    { title: 'Electricity Bill',        amount:  530, category: 'Utilities',     budget_id: aprilBudget._id, budget_category_id: catUtilities._id,     expense_date: new Date(2026, 3, 10) },
    { title: 'Internet + Water',        amount:  390, category: 'Utilities',     budget_id: aprilBudget._id, budget_category_id: catUtilities._id,     expense_date: new Date(2026, 3, 14) },
    { title: 'School Trip',             amount:  300, category: 'Education',     budget_id: aprilBudget._id, budget_category_id: catEducation._id,     expense_date: new Date(2026, 3,  7) },
    { title: 'Amusement Park',          amount:  600, category: 'Entertainment', budget_id: aprilBudget._id, budget_category_id: catEntertainment._id, expense_date: new Date(2026, 3,  8) },
    { title: 'Transport April',         amount:  310, category: 'Transport',     budget_id: aprilBudget._id, budget_category_id: catTransport._id,     expense_date: new Date(2026, 3, 30) },
    { title: 'Clothes Shopping',        amount:  800, category: 'Entertainment', budget_id: aprilBudget._id, budget_category_id: catEntertainment._id, expense_date: new Date(2026, 3, 15) },
    // Over-budget (emergency fund used)
    { title: 'Emergency: Car Repair',   amount:  200, category: 'Healthcare',    budget_id: aprilBudget._id, budget_category_id: catHealthcare._id,    expense_date: new Date(2026, 3, 28) },
  ];
  for (const ex of aprilExpenses) {
    await Expense.create({ ...ex, family_id: family._id, member_id: habiba._id, member_mail: FAMILY_EMAIL, expense_source: 'budget', expense_scope: 'shared', is_finalized: true, finalized_at: ex.expense_date });
  }
  log(`  + ${aprilExpenses.length} April expenses`);

  // ══════════════════════════════════════════════════════════════════════════
  // ACTIVE BUDGET — May 2026
  // ══════════════════════════════════════════════════════════════════════════
  log('\n=== Active Period Budget: May 2026 ===');

  const mayBudget = await PeriodBudget.create({
    family_id: family._id,
    title: 'May 2026 Budget',
    period_type: 'monthly',
    start_date: new Date(2026, 4, 1),
    end_date:   new Date(2026, 4, 31),
    total_amount: 5500,
    spent_amount: 0,
    emergency_fund_percentage: 10,
    emergency_fund_spent: 0,
    threshold_percentage: 15,
    is_active: true,
    created_by: habiba._id,
  });
  log(`  + May 2026 Budget  (5500 EGP, 10% emergency fund = 550 EGP)`);

  // ── Budget Allocations ─────────────────────────────────────────────────────
  log('\n=== Budget Allocations (May) ===');
  // Total allocated: 4950 out of 5500 (remaining 550 is the emergency fund amount)
  const allocations = [
    { inventory_category_id: catGroceries._id,     allocated_amount: 2000, threshold_percentage: 15 },
    { inventory_category_id: catUtilities._id,     allocated_amount: 1000, threshold_percentage: 10 },
    { inventory_category_id: catEducation._id,     allocated_amount:  500, threshold_percentage: 20 },
    { inventory_category_id: catEntertainment._id, allocated_amount:  800, threshold_percentage: 20 },
    { inventory_category_id: catTransport._id,     allocated_amount:  400, threshold_percentage: 25 },
    { inventory_category_id: catHealthcare._id,    allocated_amount:  250, threshold_percentage: 20 },
  ];

  const savedAllocations = {};
  for (const alloc of allocations) {
    const doc = await BudgetAllocation.create({
      family_id: family._id,
      period_budget_id: mayBudget._id,
      inventory_category_id: alloc.inventory_category_id,
      allocated_amount: alloc.allocated_amount,
      spent_amount: 0,
      threshold_percentage: alloc.threshold_percentage,
      is_active: true,
    });
    const cat = await InventoryCategory.findById(alloc.inventory_category_id).select('title');
    savedAllocations[cat.title] = doc;
    log(`  + ${cat.title}: ${alloc.allocated_amount} EGP allocated`);
  }

  // ── Member Allowances → auto-deposit to MemberWallets ─────────────────────
  log('\n=== Member Allowances + Wallets (May) ===');
  // Only children get allowances; they go directly to MemberWallet
  const allowances = [
    { member: ahmed, money_amount: 300 },
    { member: ziad,  money_amount: 250 },
    { member: noor,  money_amount: 200 },
  ];

  for (const entry of allowances) {
    const allowance = await MemberAllowance.create({
      family_id: family._id,
      period_budget_id: mayBudget._id,
      member_id: entry.member._id,
      member_mail: entry.member.mail,
      period_type: 'monthly',
      start_date: new Date(2026, 4, 1),
      end_date:   new Date(2026, 4, 31),
      allowance_currency: 'money',
      money_amount: entry.money_amount,
      spent_amount: 0,
    });

    // Deposit to MemberWallet
    const wallet = await MemberWallet.create({
      family_id: family._id,
      member_mail: entry.member.mail,
      balance: entry.money_amount,
    });
    log(`  + ${entry.member.username}: allowance ${entry.money_amount} EGP → wallet balance ${wallet.balance} EGP`);
  }

  // Habiba (parent) wallet — no allowance, but has a wallet
  await MemberWallet.create({
    family_id: family._id,
    member_mail: FAMILY_EMAIL,
    balance: 1200,
  });
  log(`  + Habiba: wallet balance 1200 EGP (parent, no allowance)`);

  // ── Current Month Shared Expenses ─────────────────────────────────────────
  log('\n=== Shared Expenses (May — current month) ===');

  const mayShared = [
    { title: 'Supermarket Week 1', amount: 820, catKey: 'Groceries',     daysBack: 9,  by: habiba },
    { title: 'Electricity Bill',   amount: 480, catKey: 'Utilities',     daysBack: 8,  by: habiba },
    { title: 'Internet Bill',      amount: 200, catKey: 'Utilities',     daysBack: 8,  by: habiba },
    { title: 'School Books May',   amount: 175, catKey: 'Education',     daysBack: 7,  by: habiba },
    { title: 'Bus Pass May',       amount: 120, catKey: 'Transport',     daysBack: 6,  by: ziad   },
    { title: 'Supermarket Week 2', amount: 760, catKey: 'Groceries',     daysBack: 4,  by: habiba },
    { title: 'Family Cinema',      amount: 220, catKey: 'Entertainment', daysBack: 3,  by: habiba },
    { title: 'Doctor Visit',       amount: 150, catKey: 'Healthcare',    daysBack: 2,  by: noor   },
    { title: 'Fruit Market',       amount: 180, catKey: 'Groceries',     daysBack: 1,  by: habiba },
  ];

  let totalSharedSpent = 0;
  const catSpent = {};

  for (const ex of mayShared) {
    const catDoc = savedAllocations[ex.catKey];
    totalSharedSpent += ex.amount;
    catSpent[ex.catKey] = (catSpent[ex.catKey] || 0) + ex.amount;

    await Expense.create({
      family_id: family._id,
      member_id:   ex.by._id,
      member_mail: ex.by.mail,
      title:       ex.title,
      amount:      ex.amount,
      category:    ex.catKey,
      expense_source: 'budget',
      expense_scope:  'shared',
      budget_id:          mayBudget._id,
      budget_category_id: catDoc?.inventory_category_id,
      expense_date: daysAgo(ex.daysBack),
      is_finalized: true,
      finalized_at: daysAgo(ex.daysBack),
    });
    log(`  + ${ex.title}: ${ex.amount} EGP [${ex.catKey}]`);
  }

  // Update period budget + allocations spent amounts
  await PeriodBudget.findByIdAndUpdate(mayBudget._id, { spent_amount: totalSharedSpent });
  for (const [catTitle, spent] of Object.entries(catSpent)) {
    if (savedAllocations[catTitle]) {
      await BudgetAllocation.findByIdAndUpdate(savedAllocations[catTitle]._id, { spent_amount: spent });
    }
  }
  log(`\n  Total shared spent this month: ${totalSharedSpent} EGP / 5500`);

  // ── Personal Expenses (children spending from their wallet) ───────────────
  log('\n=== Personal Expenses (children) ===');

  const personalExpenses = [
    { member: ahmed, title: 'Snacks from school',  amount:  25, daysBack: 6 },
    { member: ahmed, title: 'Stationery',          amount:  40, daysBack: 4 },
    { member: ahmed, title: 'Mobile top-up',       amount:  50, daysBack: 2 },
    { member: ziad,  title: 'Snacks',              amount:  20, daysBack: 7 },
    { member: ziad,  title: 'Game credit',         amount:  60, daysBack: 3 },
    { member: noor,  title: 'Hair accessories',    amount:  35, daysBack: 5 },
  ];

  for (const ex of personalExpenses) {
    // Find the allowance for this member
    const allowanceDoc = await MemberAllowance.findOne({ family_id: family._id, member_mail: ex.member.mail });
    const walletDoc    = await MemberWallet.findOne({ family_id: family._id, member_mail: ex.member.mail });

    await Expense.create({
      family_id:   family._id,
      member_id:   ex.member._id,
      member_mail: ex.member.mail,
      title:       ex.title,
      amount:      ex.amount,
      category:    'Personal',
      expense_source: 'personal_budget',
      expense_scope:  'personal',
      linked_member_allowance_id: allowanceDoc?._id,
      expense_date: daysAgo(ex.daysBack),
      is_finalized: true,
      finalized_at: daysAgo(ex.daysBack),
    });

    // Deduct from wallet + update allowance spent
    if (walletDoc) {
      walletDoc.balance = Math.max(0, walletDoc.balance - ex.amount);
      await walletDoc.save();
    }
    if (allowanceDoc) {
      allowanceDoc.spent_amount = (allowanceDoc.spent_amount || 0) + ex.amount;
      allowanceDoc.last_activity_at = daysAgo(ex.daysBack);
      await allowanceDoc.save();
    }
    log(`  + ${ex.member.username}: ${ex.title} — ${ex.amount} EGP`);
  }

  // ── Child Expense Requests ─────────────────────────────────────────────────
  log('\n=== Expense Requests (child → parent approval) ===');

  // 1 — Pending (Ahmed wants to buy a book from the education allocation)
  const pendingReq = await Expense.create({
    family_id:   family._id,
    member_id:   ahmed._id,
    member_mail: ahmed.mail,
    title:       'New Math Textbook',
    amount:      120,
    description: 'Grade 9 math textbook needed for exam prep',
    category:    'Education',
    expense_source: 'budget',
    expense_scope:  'shared',
    budget_id:          mayBudget._id,
    budget_category_id: savedAllocations['Education']?.inventory_category_id,
    request_status: 'pending',
    is_finalized: false,
    expense_date: daysAgo(1),
  });
  log(`  + PENDING:  Ahmed — "New Math Textbook" 120 EGP`);

  // 2 — Approved (Ziad wanted transport money — approved yesterday)
  const approvedReq = await Expense.create({
    family_id:   family._id,
    member_id:   ziad._id,
    member_mail: ziad.mail,
    title:       'Football Match Ticket',
    amount:      85,
    description: 'School football team final match ticket',
    category:    'Entertainment',
    expense_source: 'budget',
    expense_scope:  'shared',
    budget_id:          mayBudget._id,
    budget_category_id: savedAllocations['Entertainment']?.inventory_category_id,
    request_status: 'approved',
    is_finalized: true,
    finalized_at: daysAgo(2),
    expense_date: daysAgo(2),
  });
  // Update allocation for the approved request
  if (savedAllocations['Entertainment']) {
    await BudgetAllocation.findByIdAndUpdate(savedAllocations['Entertainment']._id, {
      $inc: { spent_amount: 85 },
    });
    await PeriodBudget.findByIdAndUpdate(mayBudget._id, {
      $inc: { spent_amount: 85 },
    });
  }
  log(`  + APPROVED: Ziad  — "Football Match Ticket" 85 EGP`);

  // 3 — Rejected (Noor wanted expensive shoes — rejected)
  const rejectedReq = await Expense.create({
    family_id:   family._id,
    member_id:   noor._id,
    member_mail: noor.mail,
    title:       'New Sneakers',
    amount:      450,
    description: 'Nike sneakers from the mall',
    category:    'Entertainment',
    expense_source: 'budget',
    expense_scope:  'shared',
    budget_id:          mayBudget._id,
    budget_category_id: savedAllocations['Entertainment']?.inventory_category_id,
    request_status: 'rejected',
    is_finalized: false,
    expense_date: daysAgo(3),
  });
  log(`  + REJECTED: Noor  — "New Sneakers" 450 EGP`);

  // ── Future Events ─────────────────────────────────────────────────────────
  log('\n=== Future Events ===');

  const existingEvents = await FutureEvent.find({ family_id: family._id });
  if (existingEvents.length === 0) {
    await FutureEvent.create({
      family_id: family._id,
      title: 'Summer Family Trip',
      description: 'Trip to Alexandria in July',
      event_date: daysFromNow(65),
      estimated_cost: 8000,
      total_contributed_money: 2000,
      funding_source: 'member_contributions',
      created_by: FAMILY_EMAIL,
    });
    await FutureEvent.create({
      family_id: family._id,
      title: 'Eid Shopping',
      description: 'Clothes and gifts for Eid',
      event_date: daysFromNow(40),
      estimated_cost: 3000,
      total_contributed_money: 500,
      funding_source: 'budget',
      created_by: FAMILY_EMAIL,
    });
    await FutureEvent.create({
      family_id: family._id,
      title: "Ahmed's School Trip",
      description: 'Annual school excursion',
      event_date: daysFromNow(30),
      estimated_cost: 800,
      total_contributed_money: 800,
      funding_source: 'budget',
      created_by: FAMILY_EMAIL,
    });
    log('  + 3 future events created');
  } else {
    log(`  ~ ${existingEvents.length} future events already exist, skipping`);
  }

  // ── Final Summary ──────────────────────────────────────────────────────────
  const finalBudget = await PeriodBudget.findById(mayBudget._id);
  const finalAllocs = await BudgetAllocation.find({ period_budget_id: mayBudget._id }).populate('inventory_category_id', 'title');

  log('\n====================================================');
  log('Budget Seed Complete!');
  log('====================================================');
  log(`\nACTIVE BUDGET: ${finalBudget.title}`);
  log(`  Total:   ${finalBudget.total_amount} EGP`);
  log(`  Spent:   ${finalBudget.spent_amount} EGP`);
  log(`  Remaining: ${finalBudget.total_amount - finalBudget.spent_amount} EGP`);
  log(`  Emergency Fund: ${finalBudget.total_amount * finalBudget.emergency_fund_percentage / 100} EGP`);
  log('\nALLOCATIONS:');
  for (const a of finalAllocs) {
    const pct = ((a.spent_amount / a.allocated_amount) * 100).toFixed(1);
    log(`  ${a.inventory_category_id?.title?.padEnd(16)}: ${a.spent_amount} / ${a.allocated_amount} EGP  (${pct}%)`);
  }
  log('\nWALLETS (after personal expenses):');
  const wallets = await MemberWallet.find({ family_id: family._id });
  for (const w of wallets) {
    log(`  ${w.member_mail.padEnd(30)}: ${w.balance} EGP`);
  }
  log('\nEXPENSE REQUESTS:');
  log('  PENDING : Ahmed  — New Math Textbook       120 EGP');
  log('  APPROVED: Ziad   — Football Match Ticket    85 EGP  (already in budget)');
  log('  REJECTED: Noor   — New Sneakers            450 EGP  (not deducted)');
  log('\nTEST SCENARIOS:');
  log('  1. GET /api/budget/periods              → see May budget list');
  log('  2. GET /api/budget/periods/:id          → May budget + allocations');
  log('  3. POST /api/budgets/expenses/new        → add shared expense (parent)');
  log('  4. POST /api/budgets/expenses/new        → add personal expense (child)');
  log('  5. POST /api/budget/expense-requests     → child submits request');
  log('  6. GET /api/budget/expense-requests      → parent sees all requests');
  log('  7. PATCH /api/budget/expense-requests/:id/approve → approve Ahmed request');
  log('  8. PATCH /api/budget/expense-requests/:id/reject  → reject any request');
  log('  9. PATCH /api/budget/periods/:id        → update budget title/amount');
  log(' 10. GET /api/budget/analytics?period_budget_id=:id → spending chart data');
  log(' 11. GET /api/budget/member/:id/combined-balance     → wallet summary');
  log(' 12. POST /api/budget/wallet/convert-to-points       → money → points');
  log(' 13. DELETE /api/budget/periods/:id        → delete old budget');
  log('====================================================\n');

  await mongoose.disconnect();
  process.exit(0);
}

seedData().catch((err) => {
  console.error('Seed error:', err.message, err.stack);
  process.exit(1);
});
