class Infrastructure::SyncSingerConnectionJob < Que::Job
  self.maximum_retry_count = 0

  def run(connection_id:)
    connection = Connection.find(connection_id)
    Infrastructure::SingerConnectionSync.new(connection.account).sync(connection)
  end
end
