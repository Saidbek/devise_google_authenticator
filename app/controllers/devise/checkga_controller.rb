class Devise::CheckgaController < Devise::SessionsController
  prepend_before_filter :devise_resource, only: [:show]
  prepend_before_filter :require_no_authentication, only: [ :show, :update ]

  include Devise::Controllers::Helpers

  def show
    @tmpid = params[:id]
    if @tmpid.nil?
      redirect_to :root
    else
      render :show
    end
  end

  def update
    resource = resource_class.find_by_gauth_tmp(params[resource_name]['tmpid'])

    if resource.present?
      return render :max_attempts_exceeded if resource.max_login_attempts?

      if resource.validate_token(params[resource_name][:gauth_token])
        set_flash_message(:notice, :signed_in) if is_navigational_format?
        sign_in(resource_name,resource)
        warden.manager._run_callbacks(:after_set_user, resource, warden, {event: :authentication})
        respond_with resource, :location => after_sign_in_path_for(resource)

        if resource.class.ga_remembertime.present?
          cookies.signed[:gauth] = {
            :value => resource.email << "," << Time.now.to_i.to_s,
            :secure => !(Rails.env.test? || Rails.env.development?),
            :expires => (resource.class.ga_remembertime + 1.days).from_now
          }
        end
        resource.update_attribute(:gauth_attempts_count, 0)
      else
        resource.gauth_attempts_count += 1
        resource.save

        if resource.max_login_attempts?
          render :max_attempts_exceeded
        else
          redirect_to :back
        end
      end
    else
      set_flash_message(:error, :error)
      redirect_to :root
    end
  end

  private

  def devise_resource
    self.resource = resource_class.new
  end
end
