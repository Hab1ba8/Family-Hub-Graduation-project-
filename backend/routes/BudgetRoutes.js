const express = require('express');
const { protect, restrictTo } = require('../controllers/AuthController');
const {
	setConversionRate,
	getConversionRate,
	convertMoneyToPoints,
	convertPointsToMoney,
	getMemberCombinedBalance,
	getMemberBalanceWalletDetails,
	getRedeemExpenses,
	createExpense,
	createEventWithRewards,
	contributeToEvent,
	getEventFundingStatus,
	markContributionPaid,
	adjustFundingGoal,
	getCombinedAnalytics,
	createPeriodBudget,
	getPeriodBudgets,
	getInventoryBudgetSummary,
	setPeriodBudgetAllocations,
	recordAllocationWithdrawal,
	getPeriodBudgetDetails,
	setPeriodMemberAllowances,
	getPeriodMemberAllowances,
	getFutureEvents,
	updateFutureEvent,
	deleteFutureEvent,
	updatePeriodBudget,
	deletePeriodBudget,
	createExpenseRequest,
	getExpenseRequests,
	approveExpenseRequest,
	rejectExpenseRequest,
} = require('../controllers/BudgetController');

const budgetRouter = express.Router();

budgetRouter.use(protect);

budgetRouter.post('/conversion-rate', restrictTo('Parent'), setConversionRate);
budgetRouter.get('/conversion-rate', getConversionRate);
budgetRouter.post('/wallet/convert-to-points', convertMoneyToPoints);
budgetRouter.post('/wallet/convert-from-points', convertPointsToMoney);
budgetRouter.get('/analytics', getCombinedAnalytics);
budgetRouter.get('/member/:memberId/combined-balance', getMemberCombinedBalance);
budgetRouter.get('/member/:memberId/balance-details', getMemberBalanceWalletDetails);
budgetRouter.get('/expenses/redeems', getRedeemExpenses);
budgetRouter.post('/expenses/new', createExpense);
budgetRouter.post('/future-events', restrictTo('Parent'), createEventWithRewards);
budgetRouter.get('/future-events/all', getFutureEvents);
budgetRouter.put('/future-events/:eventId', restrictTo('Parent'), updateFutureEvent);
budgetRouter.delete('/future-events/:eventId', restrictTo('Parent'), deleteFutureEvent);
budgetRouter.post('/events/:eventId/contribute', contributeToEvent);
budgetRouter.get('/events/:eventId/funding', getEventFundingStatus);
budgetRouter.patch('/events/:eventId/mark-paid', restrictTo('Parent'), markContributionPaid);
budgetRouter.patch('/events/:eventId/funding-goal', restrictTo('Parent'), adjustFundingGoal);

// Flexible period budgeting (weekly/monthly/yearly/custom)
budgetRouter.post('/periods', restrictTo('Parent'), createPeriodBudget);
budgetRouter.get('/periods', restrictTo('Parent'), getPeriodBudgets);
budgetRouter.get('/inventory-summary', getInventoryBudgetSummary);
budgetRouter.get('/periods/:periodBudgetId', restrictTo('Parent'), getPeriodBudgetDetails);
budgetRouter.patch('/periods/:periodBudgetId', restrictTo('Parent'), updatePeriodBudget);
budgetRouter.delete('/periods/:periodBudgetId', restrictTo('Parent'), deletePeriodBudget);
budgetRouter.put('/periods/:periodBudgetId/allocations', restrictTo('Parent'), setPeriodBudgetAllocations);
budgetRouter.put('/periods/:periodBudgetId/allowances', restrictTo('Parent'), setPeriodMemberAllowances);
budgetRouter.get('/periods/:periodBudgetId/allowances', restrictTo('Parent'), getPeriodMemberAllowances);

// Withdrawal tracking against allocations with parent notifications
budgetRouter.post('/allocations/:allocationId/withdrawals', recordAllocationWithdrawal);

// Child expense requests
budgetRouter.post('/expense-requests', createExpenseRequest);
budgetRouter.get('/expense-requests', restrictTo('Parent'), getExpenseRequests);
budgetRouter.patch('/expense-requests/:expenseId/approve', restrictTo('Parent'), approveExpenseRequest);
budgetRouter.patch('/expense-requests/:expenseId/reject', restrictTo('Parent'), rejectExpenseRequest);

module.exports = budgetRouter;
