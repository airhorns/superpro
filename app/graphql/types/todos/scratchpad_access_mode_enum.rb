class Types::Todos::ScratchpadAccessModeEnum < Types::BaseEnum
  value "PUBLIC", value: "public", description: "All members of the account can view and edit this scratchpad"
  value "PRIVATE", value: "private", description: "Only the creator of the scratchpad can view and edit it with no exceptions."
end
