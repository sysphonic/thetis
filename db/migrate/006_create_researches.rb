class CreateResearches < ActiveRecord::Migration
  def self.up
    create_table :researches do |t|
      t.column :user_id, :integer, :null => false
      t.column :status, :integer

      t.column :q01_01, :string
      t.column :q01_02, :string
      t.column :q01_03, :string
      t.column :q01_04, :string
      t.column :q01_05, :string
      t.column :q01_06, :string
      t.column :q01_07, :string
      t.column :q01_08, :string
      t.column :q01_09, :string
      t.column :q01_10, :string
      t.column :q01_11, :string
      t.column :q01_12, :string
      t.column :q01_13, :string
      t.column :q01_14, :string
      t.column :q01_15, :string
      t.column :q01_16, :string
      t.column :q01_17, :string
      t.column :q01_18, :string
      t.column :q01_19, :string
      t.column :q01_20, :string

      t.column :q02_01, :string
      t.column :q02_02, :string
      t.column :q02_03, :string
      t.column :q02_04, :string
      t.column :q02_05, :string
      t.column :q02_06, :string
      t.column :q02_07, :string
      t.column :q02_08, :string
      t.column :q02_09, :string
      t.column :q02_10, :string
      t.column :q02_11, :string
      t.column :q02_12, :string
      t.column :q02_13, :string
      t.column :q02_14, :string
      t.column :q02_15, :string
      t.column :q02_16, :string
      t.column :q02_17, :string
      t.column :q02_18, :string
      t.column :q02_19, :string
      t.column :q02_20, :string

      t.column :q03_01, :string
      t.column :q03_02, :string
      t.column :q03_03, :string
      t.column :q03_04, :string
      t.column :q03_05, :string
      t.column :q03_06, :string
      t.column :q03_07, :string
      t.column :q03_08, :string
      t.column :q03_09, :string
      t.column :q03_10, :string
      t.column :q03_11, :string
      t.column :q03_12, :string
      t.column :q03_13, :string
      t.column :q03_14, :string
      t.column :q03_15, :string
      t.column :q03_16, :string
      t.column :q03_17, :string
      t.column :q03_18, :string
      t.column :q03_19, :string
      t.column :q03_20, :string
    end
  end

  def self.down
    drop_table :researches
  end
end
