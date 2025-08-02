class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :name
      t.integer :year
      t.string :category
      t.text :description

      t.timestamps
    end
  end
end
