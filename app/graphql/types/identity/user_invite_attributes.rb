class Types::Identity::UserInviteAttributes < Types::BaseInputObject
  description "Attributes for inviting a new user"
  argument :email, String, "Email to send the invite to", required: true
end
