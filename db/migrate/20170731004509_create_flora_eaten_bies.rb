class CreateFloraEatenBies < ActiveRecord::Migration
  def change
    create_table :flora_eaten_bies do |t|
      t.integer :flora_id
      t.integer :creature_id

      t.timestamps null: false
    end
  end
end
