require 'rubygems'
require 'fusion_tables'

class NYCares::FusionTables

  def init
    @ft = GData::Client::FusionTables.new
    @ft.clientlogin ENV['GOOGLE_USERNAME'], ENV['GOOGLE_PASSWORD']
    @ft.set_api_key ENV['GOOGLE_API_KEY']
  end

  # TABLE_NAME = 'nycares'
  def insert data, table_name
    table = create_or_initialize_table(table_name)
    table.insert data
  end

  def create_or_initialize_table table_name
    tables = @ft.show_tables.map {|t| t if t.name == table_name }.compact

    if tables.empty?
      cols = columns.inject([]) { |ary, set| ary << { name: set[0], type: set[1] } }
      @ft.create_table(TABLE_NAME, cols)
    else
      tables.first
    end
  end

  def columns
    {
      title:                :string,
      description:          :string,
      spots_remaining:      :number,
      url:                  :string,
      start_date:           :datetime,
      end_date:             :datetime,
      partner:              :string,
      partner_description:  :string,
      team_leader:          :string,
      location:             :string,
      latitude:             :location,
      longitude:            :number,
      created_at:           :datetime
    }
  end

end
