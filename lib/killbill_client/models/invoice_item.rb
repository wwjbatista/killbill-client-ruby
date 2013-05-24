module KillBillClient
  module Model
    class InvoiceItem < InvoiceItemAttributes
      def create(user = nil, reason = nil, comment = nil)
        created_invoice_item = self.class.post "#{Invoice::KILLBILL_API_INVOICES_PREFIX}/charges",
                                               to_json,
                                               {},
                                               {
                                                   :user => user,
                                                   :reason => reason,
                                                   :comment => comment,
                                               }
        created_invoice_item.refresh
      end
    end
  end
end