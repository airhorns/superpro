class Infrastructure::SyncSingerConnectionJob < Que::Job
  self.maximum_retry_count = 0
  self.exclusive_execution_lock = true

  def run(connection_id:)
    connection = Connection.find(connection_id)
    Infrastructure::SingerConnectionSync.new(connection.account).sync(connection)
  end
end
