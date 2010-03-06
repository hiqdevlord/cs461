class CreateFunctions < ActiveRecord::Migration
  def self.up
    create_table :functions do |t|
      t.string :name
      t.text :body
      t.text :description
      t.string :type
      t.boolean :visible , :default => 1
      t.boolean :editable , :default => 1

      t.timestamps
    end
  end

  def self.down
    drop_table :functions
  end
end
