const mongoose = require('mongoose');

const mealSuggestionSchema = new mongoose.Schema({
  family_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'FamilyAccount',
    required: [true, 'Please provide a family account ID']
  },
  recipe_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Recipe',
    required: [true, 'Please provide the recipe ID']
  },
  meal_type: {
    type: String,
    enum: ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Any'],
    default: 'Any'
  },
  match_percentage: {
    type: Number,
    required: [true, 'Please provide the match percentage'],
    min: 0,
    max: 100
  },
  // Stored as plain strings so no populate needed
  missing_ingredients: [{
    ingredient_name: String,
    quantity: Number,
    unit_name: String
  }],
  available_ingredients: [String],
  suggested_date: {
    type: Date,
    default: Date.now
  },
  uses_expiring_items: {
    type: Boolean,
    default: false
  },
  uses_leftovers: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true
});

mealSuggestionSchema.index({ family_id: 1, createdAt: -1 });
mealSuggestionSchema.index({ match_percentage: -1 });

const MealSuggestion = mongoose.model('MealSuggestion', mealSuggestionSchema);
module.exports = MealSuggestion;
