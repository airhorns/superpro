class Connections::DiscardConnection
  def initialize(account, user)
    @account = account
    @user = user
  end

  def discard(connection)
    Connection.transaction do
      connection.update!(enabled: false)
      connection.discard!
    end

    connection
  end
end
