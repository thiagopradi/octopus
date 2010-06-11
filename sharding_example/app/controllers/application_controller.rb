class ApplicationController < ActionController::Base
  around_filter :select_shard

  protect_from_forgery
  layout 'application'

  def select_shard()
    if user_signed_in?
      yield
    else
      using(current_user.country.to_sym) { yield }
    end
  end
end
