class CreateStocks < ActiveRecord::Migration
  def self.up
    create_table :stocks do |t|
      t.integer :company_id
      t.date :day
      t.decimal :open, :precision => 8, :scale => 2
      t.decimal :high, :precision => 8, :scale => 2
      t.decimal :low, :precision => 8, :scale => 2
      t.decimal :close, :precision => 8, :scale => 2
      t.decimal :volume, :precision => 16, :scale => 2
      t.decimal :adjusted_close, :precision => 8, :scale => 2

      t.timestamps
    end
  end

  def self.down
    drop_table :stocks
  end
end
