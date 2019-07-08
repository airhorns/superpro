class Types::Todos::TodoFeedItemSourceUnion < Types::BaseUnion
  description "Objects which create entries in the todo feed"
  possible_types Types::Todos::ProcessExecutionType, Types::Todos::ScratchpadType

  def self.resolve_type(object, _context)
    if object.is_a?(ProcessExecution)
      Types::Todos::ProcessExecutionType
    else
      Types::Todos::ScratchpadType
    end
  end
end
