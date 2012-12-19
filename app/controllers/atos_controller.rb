#encoding:utf-8
class AtosController < ApplicationController
  before_filter :load_response_data
  before_filter :restore_session, :only => [:atos_confirm, :atos_cancel]
  before_filter :create_payment, :only => [:atos_confirm, :atos_auto_response]
  respond_to :html

  def atos_confirm
    # Si le paiement a été effectué
    if transaction_approved?
      # Si la commande existe et que le montant dû est égal au montant payé
      if amounts_match?
        order_completed!
        session[:order_id] = nil
        flash[:notice] = "Le paiement a été effectué avec succès"
        redirect_to spree.order_path(@order)
      else
        flash[:error] = "Le prix de vos achats (#{(@order.total.to_f*100).to_i}) et le montant que vous avez payé (#{@response_array[:amount]}) diffèrent"
        redirect_to "/"
      end
    else
      flash[:error] = "ERROR: #{@response_array[:error].gsub(/<\/?[^>]*>/, '')}"
      redirect_to "/"
    end
  end


  def atos_cancel
    session[:order_id] = @order.id
    flash[:error] = "Paiement annule. Choisissez une autre méthode de paiement ou <a href='/'>continuez vos achats</a>".html_safe
    redirect_to "/checkout/payment"
  end


  def atos_auto_response
    # Si le paiement a été effectué
    order_completed! if transaction_approved? and amounts_match?
    render :nothing => true
  end

  private

    def load_response_data
      @payment_method = Spree::PaymentMethod.where(:type => "Spree::BillingIntegration::Atos::Sips", :active => 1).first
      @banque = if banque = Spree::Preference.where(:key => "spree/billing_integration/atos/sips/banque/#{@payment_method.id}").first
        banque.value
      else
        Spree::BillingIntegration::Atos::Sips.new.preferred_banque
      end
      @response_array = AtosPayment.new(:banque => @banque).response(params[:DATA])
      @order = Spree::Order.find(@response_array[:order_id])
    end

    def restore_session
      sign_in Spree::User.find(@response_array[:customer_id])
    end

    def create_payment
      @atos_account = Spree::AtosSipsAccount.find_or_create_by_customer_id_and_payment_means_and_card_number(
        @response_array[:customer_id],@response_array[:payment_means],@response_array[:card_number])
      @payment = @order.payments.create(
        :amount => (@response_array[:amount].to_f/100.0),
        :source => @atos_account,
        :source_type => 'Spree::AtosSipsAccount',
        :payment_method_id => @payment_method.id,
        :response_code => @response_array[:response_code],
        :avs_response => @response_array[:error])
    end

    def transaction_approved?
      @response_array[:response_code] == "00"
    end
    
    def amounts_match?
      @order.present? && (@order.total.to_f*100).to_i == @response_array[:amount].to_i
    end
    
    def order_completed!
      @order.state = "complete"
      @order.payment_state = "paid"
      @order.completed_at = Time.now
      @order.save
    end
end
