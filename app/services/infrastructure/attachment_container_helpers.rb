# frozen_string_literal: true

module Infrastructure::AttachmentContainerHelpers
  def attachment_container(container_class, _container_id)
    # scope = case
    #         when container_class == Scratchpad then @account.scratchpads.for_user(@user)
    #         when container_class == ProcessExecution then @account.process_executions
    #         when container_class == ProcessTemplate then @account.process_templates
    #         else
    #           throw RuntimeError.new("Unknown container type #{container_class}")
    #         end

    # scope.find(container_id)
    throw RuntimeError.new("Unknown container type #{container_class}")
  end
end
