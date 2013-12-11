module KillBillClient
  module Model
    class Account < AccountAttributes

      has_many :audit_logs, KillBillClient::Model::AuditLog

      KILLBILL_API_ACCOUNTS_PREFIX = "#{KILLBILL_API_PREFIX}/accounts"

      class << self
        def find_in_batches(offset = 0, limit = 100, with_balance = false, with_balance_and_cba = false, options = {})
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{Resource::KILLBILL_API_PAGINATION_PREFIX}",
              {
                  :offset => offset,
                  :limit => limit,
                  :accountWithBalance => with_balance,
                  :accountWithBalanceAndCBA => with_balance_and_cba
              },
              options
        end

        def find_by_id(account_id, with_balance = false, with_balance_and_cba = false, options = {})
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}",
              {
                  :accountWithBalance => with_balance,
                  :accountWithBalanceAndCBA => with_balance_and_cba
              },
              options
        end

        def find_in_batches_by_search_key(search_key, offset = 0, limit = 100, with_balance = false, with_balance_and_cba = false, options = {})
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}/search/#{search_key}",
              {
                  :offset => offset,
                  :limit => limit,
                  :accountWithBalance => with_balance,
                  :accountWithBalanceAndCBA => with_balance_and_cba
              },
              options
        end
      end

      def create(user = nil, reason = nil, comment = nil, options = {})
        created_account = self.class.post KILLBILL_API_ACCOUNTS_PREFIX,
                                          to_json,
                                          {},
                                          {
                                              :user => user,
                                              :reason => reason,
                                              :comment => comment,
                                          }.merge(options)
        created_account.refresh(options)
      end

      def bundles(options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/bundles",
                       {},
                       options,
                       Bundle
      end

      def invoices(with_items=false, options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/invoices",
                       {
                           :withItems => with_items
                       },
                       options,
                       Invoice
      end

      def payments(options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/payments",
                       {},
                       options,
                       Payment
      end

      def overdue(options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/overdue",
                       {},
                       options,
                       OverdueStateAttributes
      end

      def tags(audit = 'NONE', options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/tags",
                       {
                           :audit => audit
                       },
                       options,
                       Tag
      end

      def add_tag(tag_name, user = nil, reason = nil, comment = nil, options = {})
        tag_definition = TagDefinition.find_by_name(tag_name, options)
        if tag_definition.nil?
          tag_definition = TagDefinition.new
          tag_definition.name = tag_name
          tag_definition.description = "Tag created for account #{@account_id}"
          tag_definition = TagDefinition.create(user, options)
        end

        add_tag_from_definition_id(tag_definition.id, user, reason, comment, options)
      end

      def remove_tag(tag_name, user = nil, reason = nil, comment = nil, options = {})
        tag_definition = TagDefinition.find_by_name(tag_name)
        return nil if tag_definition.nil?

        self.class.delete "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/tags",
                          {
                              :tagList => tag_definition.id
                          },
                          {
                              :user => user,
                              :reason => reason,
                              :comment => comment,
                          }.merge(options)
      end

      def is_AUTO_PAY_OFF(options)
        is_control_tag_off('00000000-0000-0000-0000-000000000001', options)
      end

      def set_AUTO_PAY_OFF(user = nil, reason = nil, comment = nil, options)
        add_tag_from_definition_id('00000000-0000-0000-0000-000000000001', user, reason, comment, options)
      end

      def is_AUTO_INVOICING_OFF(options)
        is_control_tag_off('00000000-0000-0000-0000-000000000002', options)
      end

      def set_AUTO_INVOICING_OFF(user = nil, reason = nil, comment = nil, options)
        add_tag_from_definition_id('00000000-0000-0000-0000-000000000002', user, reason, comment, options)
      end

      def is_OVERDUE_ENFORCEMENT_OFF(options)
        is_control_tag_off('00000000-0000-0000-0000-000000000003', options)
      end

      def set_OVERDUE_ENFORCEMENT_OFF(user = nil, reason = nil, comment = nil, options)
        add_tag_from_definition_id('00000000-0000-0000-0000-000000000003', user, reason, comment, options)
      end

      def is_WRITTEN_OFF(options)
        is_control_tag_off('00000000-0000-0000-0000-000000000004', options)
      end

      def set_WRITTEN_OFF( user = nil, reason = nil, comment = nil, options)
        add_tag_from_definition_id('00000000-0000-0000-0000-000000000004', user, reason, comment, options)
      end

      def is_MANUAL_PAY(options)
        is_control_tag_off('00000000-0000-0000-0000-000000000005', options)
      end

      def set_MANUAL_PAY(user = nil, reason = nil, comment = nil, options)
        add_tag_from_definition_id('00000000-0000-0000-0000-000000000005', user, reason, comment, options)
      end


      def is_TEST(options)
        is_control_tag_off('00000000-0000-0000-0000-000000000006', options)
      end

      def set_TEST(user = nil, reason = nil, comment = nil, options)
        add_tag_from_definition_id('00000000-0000-0000-0000-000000000006', user, reason, comment, options)
      end

      private

      def is_control_tag_off(control_tag_definition_id, options)
        res = tags('NONE', options)
        !((res || []).select do |t|
          t.tag_definition_id == control_tag_definition_id
        end.first.nil?)
      end

      def add_tag_from_definition_id(tag_definition_id, user = nil, reason = nil, comment = nil, options = {})
        created_tag = self.class.post "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/tags",
                                      {},
                                      {
                                          :tagList => tag_definition_id
                                      },
                                      {
                                          :user => user,
                                          :reason => reason,
                                          :comment => comment,
                                      }.merge(options),
                                      Tag
        created_tag.refresh(options)
      end

    end
  end
end
