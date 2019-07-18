class Types::AppMutationType < Types::BaseObject
  # Identity
  field :invite_user, mutation: Mutations::Identity::InviteUser
  field :update_account, mutation: Mutations::Identity::UpdateAccount

  # Budgets
  field :update_budget, mutation: Mutations::Budget::UpdateBudget

  # Todos
  field :create_process_template, mutation: Mutations::Todos::CreateProcessTemplate
  field :update_process_template, mutation: Mutations::Todos::UpdateProcessTemplate
  field :discard_process_template, mutation: Mutations::Todos::DiscardProcessTemplate
  field :create_process_execution, mutation: Mutations::Todos::CreateProcessExecution
  field :update_process_execution, mutation: Mutations::Todos::UpdateProcessExecution
  field :discard_process_execution, mutation: Mutations::Todos::DiscardProcessExecution
  field :create_scratchpad, mutation: Mutations::Todos::CreateScratchpad
  field :update_scratchpad, mutation: Mutations::Todos::UpdateScratchpad
  field :discard_scratchpad, mutation: Mutations::Todos::DiscardScratchpad

  # Infrastructure
  field :attach_direct_uploaded_file, mutation: Mutations::Infrastructure::AttachDirectUploadedFile
  field :attach_remote_url, mutation: Mutations::Infrastructure::AttachRemoteUrl
end
