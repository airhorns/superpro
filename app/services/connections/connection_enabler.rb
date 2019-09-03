class Connections::ConnectionEnabler
  def initialize(account, user)
    @account = account
    @user = user
  end

  def enable(connection)
    connection.update!(enabled: true)
    connection
  end

  def disable(connection)
    connection.update!(enabled: false)
    connection
  end
end
