# This controller is where clients can exchange
# codes and refresh_tokens for access_tokens

class Oauth::TokenController < OproController
  before_filter      :opro_authenticate_user!,    :except => [:create]
  skip_before_filter :verify_authenticity_token,  :only   => [:create]


  def create
    # Find the client application
    application = Oauth::ClientApp.authenticate(params[:client_id], params[:client_secret])

    if application.nil?
      render :json => {:error => "Could not find application based on client_id=#{params[:client_id]}
                                  and client_secret=#{params[:client_secret]}"}, :status => :unauthorized
      return
    end


    if params[:code]
      auth_grant = Oauth::AuthGrant.authenticate(params[:code], application.id)
    else
      auth_grant = Oauth::AuthGrant.refresh_tokens!(params[:refresh_token], application.id)
    end

    if auth_grant.nil?
      msg = "Could not find a user that belongs to this application & "
      msg << " has a refresh_token=#{params[:refresh_token]}" if params[:refresh_token]
      msg << " has been granted a code=#{params[:code]}"      if params[:code]
      render :json => {:error => msg }, :status => :unauthorized
      return
    end

    auth_grant.generate_expires_at!
    render :json => { :access_token   => auth_grant.access_token,
                      :refresh_token  => auth_grant.refresh_token,
                      :expires_in     => auth_grant.expires_in }
  end

end