# This migration comes from thinkspace_common (originally 20170327152401)
class CreateThinkspaceCommonColor < ActiveRecord::Migration[5.0]
  def change
    create_table :thinkspace_common_colors, force: true do |t|
      t.string :color
      t.string :title
      t.string :description
      t.timestamps
    end
  end
end
