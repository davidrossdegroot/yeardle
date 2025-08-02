class CreateGuesses < ActiveRecord::Migration[8.0]
  def change
    create_table :guesses do |t|
      t.references :game, null: false, foreign_key: true
      t.integer :year

      t.timestamps
    end
  end
end
