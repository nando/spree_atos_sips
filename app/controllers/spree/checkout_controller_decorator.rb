#encoding:utf-8
module Spree
  CheckoutController.class_eval do
    attr_accessor :root_path, :request_path, :response_path, :pathfile_path


    private

      def atos_request
        config = BillingIntegration::Atos::Sips.new
        gateway_id = PaymentMethod.where(:type => "Spree::BillingIntegration::Atos::Sips", :active => 1).first.id
        merchant_id = config.preferred_merchant_id
        banque = config.preferred_banque
        # facebook_app_url = Preference.where(:key => "spree/billing_integration/atos/sips/facebook_application_url/#{gateway_id}").first.value
        base_url = "http://#{Config.site_url}"
        @atos_request = AtosPayment.new(
          :banque => banque.to_s
        )
        .request(
          :merchant_id            => merchant_id,
          :amount                 => (@order.total.to_f*100).to_i,
          :customer_id            => current_user.id,
          :order_id               => @order.id,
          :automatic_response_url => "#{base_url}/atos/atos_auto_response",
          :normal_return_url      => "#{base_url}/atos/atos_confirm",
          :cancel_return_url      => "#{base_url}/atos/atos_cancel"
          # on facebook
          # :automatic_response_url => "{facebook_app_url}/atos/atos_auto_response",
          # :normal_return_url      => "{facebook_app_url}/atos/atos_confirm",
          # :cancel_return_url      => "{facebook_app_url}/atos/atos_cancel"
        )
      end

      def save_cart
        @order.line_items.each do |line|
          line.save
        end
        @order.save
      end


      def before_payment
        current_order.payments.destroy_all if request.put?
        save_cart
        atos_request
      end
  end
end
