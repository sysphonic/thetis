class ChangesForVer110 < ActiveRecord::Migration
  def self.up
    add_column :items, :source_id, :integer

    add_column :addresses, :groups, :text
    add_column :addresses, :teams, :text

    add_column :workflows, :groups, :text

    add_column :users,  :figure, :string
    add_column :groups, :xtype, :string

    add_column :teams, :req_to_del_at, :datetime
    change_table :teams do |t|
      t.timestamps
    end

    teams = Team.all
    unless teams.nil?
      teams.each do |team|
        begin
          item = Item.find(team.item_id)
        rescue
        end
        next if item.nil?

        attrs = ActionController::Parameters.new({created_at: item.created_at, updated_at: item.updated_at})
        attrs.permit!
        team.update_attributes(attrs)
      end
    end
  end

  def self.down
    remove_column :items, :source_id

    remove_column :addresses, :groups
    remove_column :addresses, :teams

    remove_column :workflows, :groups

    remove_column :users,   :figure
    remove_column :groups,  :xtype

    remove_column :teams, :req_to_del_at
    remove_column :teams, :created_at
    remove_column :teams, :updated_at
  end
end
