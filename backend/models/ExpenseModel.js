const mongoose = require('mongoose');

const expenseSchema = new mongoose.Schema({
	family_id: {
		type: mongoose.Schema.Types.ObjectId,
		ref: 'FamilyAccount',
		required: [true, 'Please provide a family account ID']
	},
	member_id: {
		type: mongoose.Schema.Types.ObjectId,
		ref: 'Member',
		default: null
	},
	member_mail: {
		type: String,
		ref: 'Member',
		default: null
	},
	category: {
		type: String,
		trim: true,
		default: ''
	},
	title: {
		type: String,
		required: [true, 'Please provide the expense title'],
		trim: true
	},
	amount: {
		type: Number,
		required: [true, 'Please provide the expense amount'],
		min: [0, 'Expense amount cannot be negative']
	},
	description: {
		type: String,
		default: ''
	},
	expense_date: {
		type: Date,
		default: Date.now
	},
	notes: {
		type: String,
		default: ''
	},
	expense_source: {
		type: String,
		enum: ['budget', 'member_wallet', 'redeem_reward', 'personal_budget'],
		default: 'budget'
	},
	budget_id: {
		type: mongoose.Schema.Types.ObjectId,
		ref: 'Budget',
		default: null
	},
	budget_category_id: {
		type: mongoose.Schema.Types.ObjectId,
		ref: 'InventoryCategory',
		default: null
	},
	linked_member_allowance_id: {
		type: mongoose.Schema.Types.ObjectId,
		ref: 'MemberAllowance',
		default: null
	},
	is_finalized: {
		type: Boolean,
		default: false
	},
	finalized_at: {
		type: Date,
		default: null
	},
	linked_redeem_id: {
		type: mongoose.Schema.Types.ObjectId,
		ref: 'Redeem',
		default: null
	},
	linked_member_wallet_id: {
		type: mongoose.Schema.Types.ObjectId,
		ref: 'MemberWallet',
		default: null
	},
	linked_event_id: {
		type: mongoose.Schema.Types.ObjectId,
		ref: 'FutureEvent',
		default: null
	},
	request_status: {
		type: String,
		enum: ['pending', 'approved', 'rejected'],
		default: null
	},
	expense_scope: {
		type: String,
		enum: ['shared', 'personal'],
		default: 'shared'
	}
}, {
	timestamps: true
});

expenseSchema.index({ family_id: 1, expense_date: -1 });
expenseSchema.index({ family_id: 1, expense_source: 1 });
expenseSchema.index({ family_id: 1, budget_id: 1 });
expenseSchema.index({ linked_redeem_id: 1 });
expenseSchema.index({ linked_member_wallet_id: 1 });
expenseSchema.index({ linked_member_allowance_id: 1 });
expenseSchema.index({ linked_event_id: 1 });

const Expense = mongoose.model('Expense', expenseSchema);

module.exports = Expense;
