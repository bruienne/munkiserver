class ApplicationController < ActionController::Base
  helper :all
  protect_from_forgery :except => [:checkin]
  
  before_filter :require_login
  before_filter :require_valid_unit
  before_filter :load_singular_resource
  before_filter :authorize_resource
  
  private
  include ApplicationHelper
  
  # Run a rake task in the background
  # TO-DO could improve performance if using a gem (rake loads environment every single time)
  def call_rake(task, options = {})
    options[:rails_env] ||= Rails.env
    args = options.map { |k,v| "#{k.to_s.upcase}='#{v}'" }
    system "rake #{task} #{args.join(' ')} --trace >> #{Rails.root}/log/rake.log &"
  end
  
  # Redirects user to login path if logged_in returns false.
  def require_login
    # If client logged in or the action is authorized
    if logged_in? or authorized?
      # Let them pass
    else
      flash[:warning] = "You must be logged in to view that page"
      redirect_to login_path(:redirect => request.request_uri)
    end
  end
  
  # Checks unit_shortname and ensures it refers to a valid unit
  def require_valid_unit
    if current_unit.nil?
      flash[:error] = "The unit you requested (#{params[:unit_shortname]}) does not exist or you do not have permission to it!"
      render :file => "#{Rails.root}/public/generic_error.html", :layout => false
    end
  end
  
  def authorized?
    begin
      authorize_resource
      true
    rescue CanCan::AccessDenied
      false
    end
  end

  def page_not_found
    {:file => "#{Rails.root}/public/404.html", :layout => false, :status => 404}
  end
  
  def error_page
    {:file => "#{Rails.root}/public/generic_error.html", :layout => false}
  end
  
  # Load a singular resource into @package for all actions
  def load_singular_resource
    raise Exception.new("Unale to load singular resource for #{params[:action]} action of #{params[:controller]} controller.")
  end
  
  def authorize_resource
    authorize! params[:action].to_sym, instance_variable_get("@#{params[:controller].singularize}") || params[:controller].classify.constantize
  end
  
  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = exception.message
    redirect_to :back, :alert => exception.message
  end
end
