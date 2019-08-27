# find_nth / find_nth! must be public here to allow Octopus to call
# them on the scope proxy object
if Octopus.rails42? || Octopus.rails50?
  module ActiveRecord::FinderMethods
    public :find_nth
    public :find_nth!
  end
end
