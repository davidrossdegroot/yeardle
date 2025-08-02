class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.datetime :completed_at
      t.boolean :won

      t.timestamps
    end
  end
end
