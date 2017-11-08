# frozen_string_literal: true

class Auth::RegistrationsController < Devise::RegistrationsController
  layout :determine_layout

  before_action :check_enabled_registrations, only: [:new, :create]
  before_action :configure_sign_up_params, only: [:create]
  before_action :set_sessions, only: [:edit, :update]
  before_action :set_instance_presenter, only: [:new, :create, :update]

  def create
    build_resource(sign_up_params)

    resource.save
    yield resource if block_given?
    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"

        # CARD PAYMENT SECTION
        begin
          # Create the customer in Stripe
          customer = Stripe::Customer.create(
            email: params[:stripeEmail],
            card: params[:stripeToken]
          )
          resource.stripe_id = customer.id
          resource.save

          # Create the charge using the customer data returned by Stripe API
          charge = Stripe::Charge.create(
            customer: customer.id,
            amount: 500, # Amount in cents
            description: 'capitalism.party account',
            currency: 'usd'
          )
          resource.has_paid = true
          resource.save
        rescue Stripe::CardError => e
          # flash[:notice] = e.message
          flash[:notice] = 'there was an error with your card, please verify your email and login'
          #respond_with resource
          # redirect_to :new_user_registration
        end

        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end


  def new
    super
  end

  def destroy
    not_found
  end

  protected

  def build_resource(hash = nil)
    super(hash)
    resource.locale = I18n.locale
    resource.build_account if resource.account.nil?
  end

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up) do |u|
      u.permit({ account_attributes: [:username] }, :email, :password, :password_confirmation)
    end
  end

  def after_sign_up_path_for(_resource)
    new_user_session_path
  end

  def after_inactive_sign_up_path_for(_resource)
    new_user_session_path
  end

  def check_enabled_registrations
    redirect_to root_path if single_user_mode? || !Setting.open_registrations
  end

  private

  def set_instance_presenter
    @instance_presenter = InstancePresenter.new
  end

  def determine_layout
    %w(edit update).include?(action_name) ? 'admin' : 'auth'
  end

  def set_sessions
    @sessions = current_user.session_activations
  end
end
