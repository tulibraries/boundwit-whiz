module Alma
  module UserOverrides
    def cataloger?
      Array(self["user_role"]).any? do |role|
        role.dig("role_type", "desc") == "Cataloger"
      end
    end
  end
end
