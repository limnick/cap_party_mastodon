# frozen_string_literal: true

class Settings::PaymentsController < ApplicationController
  layout 'admin'

  skip_before_action :check_payment
  before_action :authenticate_user!
  before_action :set_account

  def show; end

  def update
    #if has_paid then bail
    if current_user.has_paid
      redirect_to settings_payment_path, notice: 'you have already paid'
    else

      #TODO: else try to charge card
      customer = Stripe::Customer.create(
        email: params[:stripeEmail],
        card: params[:stripeToken]
      )
      current_user.stripe_id = customer.id
      current_user.save

      # Create the charge using the customer data returned by Stripe API
      charge = Stripe::Charge.create(
        customer: customer.id,
        amount: 500, # Amount in cents
        description: 'capitalism.party account',
        currency: 'usd'
      )
      #TODO: if no error then set has_paid and redirect to home
      current_user.has_paid = true
      current_user.save
      redirect_to :settings_profile, notice: 'Welcome to capitalism.party!'
    end
  rescue Stripe::CardError => e
      #TODO: print error on page if error
    redirect_to settings_payment_path, alert: e.message
  end

  # def account_params
  #   params.require(:account).permit(:display_name, :note, :avatar, :header, :locked)
  # end

  def set_account
    @account = current_user.account
  end

end
