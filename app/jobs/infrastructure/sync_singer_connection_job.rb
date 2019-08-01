class Infrastructure::SyncSingerConnectionJob < Que::Job
  def run(connection_id:)
    connection = Connection.find(connection_id)
    Infrastructure::SingerConnectionSync.new(connection.account).sync(connection)
  end
end
